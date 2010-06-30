Feature: Specify routing rules for application terminated messages
In order to transform messages and select a specific application for a messages
A user
Should be able to specify at rules

  Background:
    Given the following Countries exist:
        | name      | iso2  | iso3  | phone_prefix  |
        | Argentina | ar    | arg   | 54            |
        | Brazil    | br    | bra   | 55            |
    And the following Carriers exist:
      | country name  | name      | guid        |
      | Argentina     | Personal  | Ar-Personal |
      | Brazil        | Movistar  | Br-Movistar |
    And an account named "InSTEDD" exists
    And an application named "GeoChat" belongs to the "InSTEDD" account
    
  # 7)
  Scenario: Route with AT rule that sets a carrier
    Given a "clickatell" channel named "chan" with an at rule that sets "carrier" to "Ar-Personal" when "to" "starts_with" "sms" belongs to the "InSTEDD" account
    
    When the account "InSTEDD" receives a message with "from" set to "sms://5001" via the "chan" channel 
    
    Then the carrier associated with the number "5001" should be "Personal"
    
  Scenario: Infer carrier when present in mobile numbers
    Given a "clickatell" channel named "chan" belongs to the "InSTEDD" account
      And the number "5001" is associated to the "Personal" carrier
      
    When the account "InSTEDD" receives a message with "from" set to "sms://5001" via the "chan" channel
    
    Then the "ATMessage" with "from" set to "sms://5001" should have its carrier set to "Ar-Personal"
