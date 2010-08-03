Feature: Manage the channels of a nuntium application via a RESTful API
In order to manage the channels of a nuntium application remotely
A website owner
Should be able to manage the channels via a RESTful API

  Background:
    Given an account named "InsTEDD" exists
      And an application named "GeoChat" belongs to the "InsTEDD" account
      And the following Channel exists:
        | name                    | EmailChannel    |
        | kind                    | smtp            |
        | protocol                | mailto          |
        | direction               | incoming        |
        | address                 | mailto://a@b.c  |
        | priority                | 20              |
        | account name            | InsTEDD         |
        | application name        | GeoChat         |
        | configuration host      | some.host       |
        | configuration port      | 465             |
        | configuration user      | some.user       |
        | configuration password  | secret          |
      And I am authenticated as the "GeoChat" application

  Scenario: Query the channels via XML
    When I GET /api/channels.xml
    
    Then I should see XML:
      """
      <channels>
        <channel kind="smtp" name="EmailChannel" protocol="mailto" direction="incoming"
          enabled="true" application="GeoChat" priority="20" address="mailto://a@b.c">
          <configuration>
            <property name="host" value="some.host" />
            <property name="user" value="some.user" />
            <property name="port" value="465" />
          </configuration>
        </channel>
      </channels>
      """
  
  Scenario: Query the channels via JSON
    When I GET /api/channels.json
    
    Then I should see JSON:
      """
      [
        {"kind": "smtp", "name": "EmailChannel", "protocol": "mailto",
          "direction": "incoming", "enabled": true, "application": "GeoChat",
          "priority": 20, "address": "mailto://a@b.c", "configuration": [
            {"name": "host", "value": "some.host"},
            {"name": "user", "value": "some.user"},
            {"name": "port", "value": "465"}
          ]}
      ]
      """
      
  Scenario: Query a channel via XML
    When I GET /api/channels/EmailChannel.xml
    
    Then I should see XML:
      """
      <channel kind="smtp" name="EmailChannel" protocol="mailto" direction="incoming"
        enabled="true" application="GeoChat" priority="20" address="mailto://a@b.c">
        <configuration>
          <property name="host" value="some.host" />
          <property name="user" value="some.user" />
          <property name="port" value="465" />
        </configuration>
      </channel>
      """
  
  Scenario: Query a channel via JSON
    When I GET /api/channels/EmailChannel.json
    
    Then I should see JSON:
      """
      {"kind": "smtp", "name": "EmailChannel", "protocol": "mailto",
        "direction": "incoming", "enabled": true, "application": "GeoChat",
        "priority": 20, "address": "mailto://a@b.c", "configuration": [
          {"name": "host", "value": "some.host"},
          {"name": "user", "value": "some.user"},
          {"name": "port", "value": "465"}
        ]}
      """
      
  Scenario: Create a channel via XML
    When I POST XML /api/channels.xml:
      """
      <channel kind="smtp" name="EmailChannel2" protocol="mailto" direction="incoming"
        enabled="true" application="GeoChat" priority="20" address="mailto://a@b.c">
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
      | application name        | GeoChat         |
      | address                 | mailto://a@b.c  |
      | configuration host      | some.host       |
      | configuration port      | 465             |
      | configuration user      | some.user       |
      | configuration password  | secret          |
      
  Scenario: Create a channel via JSON
    When I POST JSON /api/channels.json:
      """
      {"kind": "smtp", "name": "EmailChannel2", "protocol": "mailto",
        "direction": "incoming", "enabled": true, "application": "GeoChat",
        "priority": 20, "address": "mailto://a@b.c", "configuration": [
          {"name": "host", "value": "some.host"},
          {"name": "user", "value": "some.user"},
          {"name": "port", "value": "465"},
          {"name": "password", "value": "secret"}
        ]}
      """
      
    Then the Channel with the name "EmailChannel2" should have the following properties:
      | kind                    | smtp            |
      | protocol                | mailto          |
      | direction_text          | incoming        |
      | priority                | 20              |
      | account name            | InsTEDD         |
      | application name        | GeoChat         |
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
      
  Scenario: Edit a channel via JSON
    When I PUT JSON /api/channels/EmailChannel.json:
      """
      {"priority": 40}
      """
      
    Then the Channel with the name "EmailChannel" should have the following properties:
      | priority  | 40  |
      
  Scenario: Delete a channel
    When I DELETE /api/channels/EmailChannel
    
    Then the Channel with the name "EmailChannel" should not exist
    
  Scenario: Create a channel via XML gives error
    When I POST XML /api/channels.xml:
      """
      <channel kind="smtp" name="Email Channel2" protocol="mailto" direction="incoming"
        enabled="true" application="GeoChat" priority="20">
        <configuration>
          <property name="host" value="some.host" />
          <property name="user" value="some.user" />
          <property name="port" value="465" />
          <property name="password" value="secret" />
        </configuration>
      </channel>
      """
      
    Then I should see XML:
      """
      <error summary="There were problems creating the channel">
        <property name="name" value="can only contain alphanumeric characters, '_' or '-' (no spaces allowed)" />
      </error>
      """
  Scenario: Create a channel via JSON gives error
    When I POST JSON /api/channels.json:
      """
      {"kind": "smtp", "name": "Email Channel2", "protocol": "mailto",
        "direction": "incoming", "enabled": true, "application": "GeoChat",
        "priority": 20, "configuration": [
          {"name": "host", "value": "some.host"},
          {"name": "user", "value": "some.user"},
          {"name": "port", "value": "465"},
          {"name": "password", "value": "secret"}
        ]}
      """
      
    Then I should see JSON:
      """
      {
        "summary": "There were problems creating the channel",
        "properties": [{
          "name": "can only contain alphanumeric characters, '_' or '-' (no spaces allowed)"
        }]
      }
      """ 
      
  Scenario: Get the list of candidate channels via XML 
    Given the following Channel exists:
        | name                    | QstServerChannel  |
        | kind                    | qst_server        |
        | protocol                | sms               |
        | direction               | bidirectional     |
        | address                 | sms://0           |
        | account name            | InsTEDD           |
        | application name        | GeoChat           |
        | configuration password  | secret            |
        
    When I GET /api/candidate/channels.xml?from=sms://1&to=sms://2&subject=Hello
    
    Then I should see XML:
      """
      <channels>
        <channel kind="qst_server" name="QstServerChannel" protocol="sms" direction="bidirectional"
          enabled="true" application="GeoChat" priority="100" address="sms://0">
          <configuration>
          </configuration>
        </channel>
      </channels>
      """
      
  Scenario: Get the list of candidate channels via JSON 
    Given the following Channel exists:
        | name                    | QstServerChannel  |
        | kind                    | qst_server        |
        | protocol                | sms               |
        | direction               | bidirectional     |
        | address                 | sms://0           |
        | account name            | InsTEDD           |
        | application name        | GeoChat           |
        | configuration password  | secret            |
        
    When I GET /api/candidate/channels.json?from=sms://1&to=sms://2&subject=Hello
    
    Then I should see JSON:
      """
      [
      {"kind": "qst_server", "name": "QstServerChannel", "protocol": "sms",
        "direction": "bidirectional", "enabled": true, "application": "GeoChat",
        "priority": 100, "address": "sms://0", "configuration": []}
      ]
      """
