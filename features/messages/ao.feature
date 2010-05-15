Feature: Send Application Originated messages
In order to send messages to users
An application
Should be able to send messages to nuntium

  Background:
    Given an account named InsTEDD exists
      And an application named GeoChat belongs to the InsTEDD account

  Scenario: Send message to be sent as email
    Given an SMTP channel named email belongs to the InsTEDD account
      
    When GeoChat sends the following AOMessage:
      | from                          | to                      | subject | body  |
      | mailto://geochat@instedd.org  | mailto://some@user.com  | Hi!     | Hello |
    
    Then the email account some@user.com receives the following email:
      | From    | geochat@instedd.org |
      | Subject | Hi!                 |
      | Body    | Hello               |
