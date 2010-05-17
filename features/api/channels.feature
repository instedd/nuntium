Feature: Manage the channels of a nuntium account via a RESTful API
In order to manage the channels of a nuntium account remotely
A website owner
Should be able to manage the channels via a RESTful API

  Background:
    Given an account named "InsTEDD" exists
      And an application named "GeoChat" belongs to the "InsTEDD" account
      And the following Channel exists:
        | name                    | EmailChannel  |
        | kind                    | smtp          |
        | protocol                | mailto        |
        | direction               | incoming      |
        | priority                | 20            |
        | account name            | InsTEDD       |
        | application name        | GeoChat       |
        | configuration host      | some.host     |
        | configuration port      | 465           |
        | configuration user      | some.user     |
        | configuration password  | secret        |
      And I am authenticated as the "GeoChat" application

  Scenario: Create a channel via XML
    When I go to the channels exposed via XML in the API
    
    Then I should see XML:
      """
      <channels>
        <channel kind="smtp" name="EmailChannel" protocol="mailto" direction="incoming"
          enabled="true" application="GeoChat" priority="20">
          <configuration>
            <property name="host" value="some.host" />
            <property name="user" value="some.user" />
            <property name="port" value="465" />
          </configuration>
        </channel>
      </channels>
      """
  
  Scenario: Create a channel via JSON
    When I go to the channels exposed via JSON in the API
    
    Then I should see JSON:
      """
      [
        {"kind": "smtp", "name": "EmailChannel", "protocol": "mailto",
          "direction": "incoming", "enabled": true, "application": "GeoChat",
          "priority": 20, "configuration": [
            {"name": "host", "value": "some.host"},
            {"name": "user", "value": "some.user"},
            {"name": "port", "value": "465"}
          ]}
      ]
      """
      
  Scenario: Delete a channel
    When I DELETE /api/channels/EmailChannel
    
    Then The Channel with the name "EmailChannel" should not exist
