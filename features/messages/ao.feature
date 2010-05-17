Feature: Send Application Originated messages
In order to send messages to users
An application
Should be able to send messages to nuntium

  Background:
    Given an account named "InsTEDD" exists
      And an application named "GeoChat" belongs to the "InsTEDD" account
      And an SMTP channel named "email" belongs to the "InsTEDD" account
      
  Scenario: Send message via RSS interface
    Given I am authenticated as the "GeoChat" application
    
    When I POST XML /InsTEDD/GeoChat/rss:
      """
      <rss version="2.0">
        <channel>
          <item>
            <title>Hi!</title>
            <description>Hello</description>
            <author>mailto://geochat@instedd.org</author>
            <to>mailto://some@user.com</to>
            <pubDate>Sun Jan 02 05:00:00 UTC 2000</pubDate>
            <guid>someguid</guid>
          </item>
        </channel>
      </rss>
      """
      
    Then the email account "some@user.com" receives the following email:
      | From    | geochat@instedd.org |
      | Subject | Hi!                 |
      | Body    | Hello               |
      
  Scenario: Send message via HTTP inerface
    Given I am authenticated as the "GeoChat" application
    
    When I GET /InsTEDD/GeoChat/send_ao?subject=Hi!&body=Hello&from=mailto://geochat@instedd.org&to=mailto://some@user.com
    
    Then the email account "some@user.com" receives the following email:
      | From    | geochat@instedd.org |
      | Subject | Hi!                 |
      | Body    | Hello               |
