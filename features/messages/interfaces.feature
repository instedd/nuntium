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
      
  Scenario: Receive message via RSS interface
    Given I am authenticated as the "GeoChat" application
      And the following ATMessage exists:
        | account name      | InsTEDD                       |
        | application name  | GeoChat                       |
        | from              | mailto://some@user.com        | 
        | to                | mailto://geochat@instedd.org  |
        | subject           | RE: Hi!                       |
        | body              | How are you?                  |
        | timestamp         | Sun Jan 02 05:00:00 UTC 2000  |
        | guid              | userguid                      |
        | state             | queued                        |
        
    When I GET /InsTEDD/GeoChat/rss
    
    Then I should see XML:
      """
      <rss version="2.0">
        <channel>
          <title>Outbox</title>
          <lastBuildDate>Sun, 02 Jan 2000 05:00:00 +0000</lastBuildDate>
          <item>
            <title>RE: Hi!</title>
            <description>How are you?</description>
            <author>mailto://some@user.com</author>
            <to>mailto://geochat@instedd.org</to>
            <pubDate>Sun, 02 Jan 2000 05:00:00 +0000</pubDate>
            <guid>userguid</guid>
          </item>
        </channel>
      </rss>
      """        
      
  Scenario: Send message via HTTP inerface
    Given I am authenticated as the "GeoChat" application
    
    When I GET /InsTEDD/GeoChat/send_ao?subject=Hi!&body=Hello&from=mailto://geochat@instedd.org&to=mailto://some@user.com
    
    Then the email account "some@user.com" receives the following email:
      | From    | geochat@instedd.org |
      | Subject | Hi!                 |
      | Body    | Hello               |
