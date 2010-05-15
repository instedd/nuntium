Feature: User registers and logins into the application
In order to configure nuntium and see the messages that come and go
A user
Should be able to create an account and login into nuntium

Scenario:  User creates an account
Given nuntium is up and running

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
  And I should see "Last Application Originated Messages"
  And I should see "Last Application Terminated Messages"
  And I should see "Logs"
