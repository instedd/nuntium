Feature: Manage the channels of a nuntium account via a RESTful API
In order to manage the channels of a nuntium account remotely
A website owner
Should be able to manage the channels via a RESTful API

  Background:
    Given an account named "InsTEDD" exists
      And the following Channel exists:
        | name                    | EmailChannel    |
        | kind                    | smtp            |
        | protocol                | mailto          |
        | direction               | incoming        |
        | address                 | mailto://a@b.c  |
        | priority                | 20              |
        | account name            | InsTEDD         |
        | configuration host      | some.host       |
        | configuration port      | 465             |
        | configuration user      | some.user       |
        | configuration password  | secret          |
      And I am authenticated as the "InsTEDD" account
      
  Scenario: Query the channels via XML
    When I GET /api/channels.xml
    
    Then I should see XML:
      """
      <channels>
        <channel kind="smtp" name="EmailChannel" protocol="mailto" direction="incoming"
          enabled="true" priority="20" address="mailto://a@b.c">
          <configuration>
            <property name="host" value="some.host" />
            <property name="user" value="some.user" />
            <property name="port" value="465" />
          </configuration>
        </channel>
      </channels>
      """

  Scenario: Create a channel via XML with account credentials
    When I POST XML /api/channels.xml:
      """
      <channel kind="smtp" name="EmailChannel2" protocol="mailto" direction="incoming"
        enabled="true" priority="20" address="mailto://a@b.c">
        <configuration>
          <property name="host" value="some.host" />
          <property name="user" value="some.user" />
          <property name="port" value="465" />
          <property name="password" value="secret" />
        </configuration>
      </channel>
      """
      
    Then the Channel with the name "EmailChannel2" should have the following properties:
      | kind                    | smtp            |
      | protocol                | mailto          |
      | direction_text          | incoming        |
      | priority                | 20              |
      | account name            | InsTEDD         |
      | address                 | mailto://a@b.c  |
      | configuration host      | some.host       |
      | configuration port      | 465             |
      | configuration user      | some.user       |
      | configuration password  | secret          |
      
  Scenario: Edit a channel via XML
    When I PUT XML /api/channels/EmailChannel.xml:
      """
      <channel priority="40" />
      """
      
    Then the Channel with the name "EmailChannel" should have the following properties:
      | priority  | 40  |
      
  Scenario: Delete a channel
    When I DELETE /api/channels/EmailChannel
    
    Then the Channel with the name "EmailChannel" should not exist
