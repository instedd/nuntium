Feature: Provide the list of carriers known to Nuntium
In order for websites to let users choose the cellphone company their
  messages are coming from
A website owner
Should be able to query the list of carriers known to Nuntium

  Background:
    Given the following Countries exist:
      | name      | iso2  | iso3  | phone_prefix  |
      | Argentina | ar    | arg   | 54            |
      | Brazil    | br    | bra   | 55            |
    And the following Carriers exist:
      | country name  | name      | guid        |
      | Argentina     | Personal  | Ar-Personal |
      | Brazil        | Movistar  | Br-Movistar |
      
  Scenario: A website queries the Argentina carriers list in XML format     
    When I GET /api/carriers.xml?country_id=ar
    
    Then I should see XML:
      """
      <carriers>
        <carrier name="Personal" country_iso2="ar" guid="Ar-Personal" />
      </carriers>
      """
      
  Scenario: A website queries the Argentina carriers list in JSON format     
    When I GET /api/carriers.json?country_id=ar
    
    Then I should see JSON:
      """
      [
        {"name": "Personal", "country_iso2": "ar", "guid": "Ar-Personal"}
      ]
      """

