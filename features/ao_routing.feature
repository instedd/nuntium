Feature: Specify routing rules for application originated messages
In order to transform messages and select a specific channel for a messages
A user
Should be able to specify ao rules

  Background:
    Given the following Countries exist:
        | name      | iso2  | iso3  | phone_prefix  |
        | Argentina | ar    | arg   | 54            |
        | Brazil    | br    | bra   | 55            |
    And an account named "InSTEDD" exists
        And an application named "GeoChat" belongs to the "InSTEDD" account

  # 1)
  Scenario: Route according to country code
    Given a "clickatell" channel named "a_channel" with "country" restriction set to "ar" belongs to the "InSTEDD" account
      And a "clickatell" channel named "b_channel" with "country" restriction set to "br" belongs to the "InSTEDD" account
      
    When the application "GeoChat" sends a message with "to" set to "sms://5401"
    Then the message with "to" set to "sms://5401" should have been routed to the "a_channel" channel
    
    When the application "GeoChat" sends a message with "to" set to "sms://5501"    
    Then the message with "to" set to "sms://5501" should have been routed to the "b_channel" channel
    
  # 2)
  Scenario: Route according to priority
    Given a "clickatell" channel named "high" with "priority" set to "20" belongs to the "InSTEDD" account
    Given a "clickatell" channel named "low" with "priority" set to "40" belongs to the "InSTEDD" account
    
    When the application "GeoChat" sends a message with "to" set to "sms://5401"
    Then the message with "to" set to "sms://5401" should have been routed to the "high" channel
