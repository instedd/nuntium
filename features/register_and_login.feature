Feature: User registers and logins into the application
In order to configure nuntium and see the messages that come and go
A user
Should be able to create an account and login into nuntium

  Scenario: User creates an account
    When I go to the home page
      And I fill in the following within "#new_account":
        | Name                  | nuntium_account |
        | Password              | secret          |
        | Password confirmation | secret          |
      And I press "Create Account"

    Then I should see "Interactions"
      And I should see "Settings"
      And I should see "Channels"
      And I should see "Applications"
      And I should see "AO messages"
      And I should see "AT messages"
      And I should see "Logs"

  Scenario: User logs into his account
    Given the following Accounts exist:
      | name | password |
      | nunt | secret   |

    When I go to the home page
      And I fill in the following within "#login":
        | Name      | nunt    |
        | Password  | secret  |
      And I press "Login"

    Then I should see "Interactions"
      And I should see "Settings"
      And I should see "Channels"
      And I should see "Applications"
      And I should see "AO messages"
      And I should see "AT messages"
      And I should see "Logs"
