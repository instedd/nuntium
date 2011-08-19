Feature: Specify routing rules for application originated messages
In order to transform messages and select a specific channel for a messages
A user
Should be able to specify ao rules

  Background:
    Given the following Countries exist:
        | name      | iso2  | iso3  | phone_prefix  |
        | Argentina | ar    | arg   | 54            |
        | Brazil    | br    | bra   | 55            |
    And the following Carriers exist:
      | country name  | name      | guid        | prefixes  |
      | Argentina     | Personal  | Ar-Personal | 12        |
      | Brazil        | Movistar  | Br-Movistar | 34        |
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

  # 4)
  Scenario: Route according to priority
    Given a "clickatell" channel named "high" with "priority" set to "20" belongs to the "InSTEDD" account
    Given a "clickatell" channel named "low" with "priority" set to "40" belongs to the "InSTEDD" account

    When the application "GeoChat" sends a message with "to" set to "sms://5401"
    Then the message with "to" set to "sms://5401" should have been routed to the "high" channel

  # 6)
  Scenario: Route according to credit
    Given a "clickatell" channel named "requires_credit" with "credit" restriction set to "true" belongs to the "InSTEDD" account
      And a "clickatell" channel named "accepts_all" belongs to the "InSTEDD" account

    When the application "GeoChat" sends a message with "to" set to "sms://5501" and "credit" custom attribute set to "false"
    Then the message with "to" set to "sms://5501" should have been routed to the "accepts_all" channel

  # 8)
  Scenario: Infer carrier when present in mobile numbers
    Given a "clickatell" channel named "chan" belongs to the "InSTEDD" account
      And the number "5001" is associated to the "Personal" carrier

    When the application "GeoChat" sends a message with "to" set to "sms://5001"

    Then the "AoMessage" with "to" set to "sms://5001" should have its carrier set to "Ar-Personal"

  # 9)
  Scenario: AO rule that changes the from based on the message's carrier
    Given the "GeoChat" application has an AO rule that sets "from" to "sms://1234" when "carrier" "equals" "Ar-Personal"
      And a "clickatell" channel named "chan" belongs to the "InSTEDD" account

    When the application "GeoChat" sends a message with "to" set to "sms://541234"

    Then the "AoMessage" with "to" set to "sms://541234" should have "from" set to "sms://1234"
