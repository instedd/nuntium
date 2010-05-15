Feature: Provide the list of countries known to Nuntium
In order for websites to let users choose where their messages are coming from
A website owner
Should be able to query the list of countries known to Nuntium

  Background:
    Given the following Countries exist:
      | name      | iso2  | iso3  | phone_prefix  |
      | Argentina | ar    | arg   | 54            |
      | Brazil    | br    | bra   | 55            |

  Scenario: A website queries the country list in XML format    
    When I go to the countries exposed via XML in the API
    
    Then I should see XML:
      """
      <countries>
        <country name="Argentina" iso2="ar" iso3="arg" phone_prefix="54" />
        <country name="Brazil" iso2="br" iso3="bra" phone_prefix="55" />
      </countries>
      """
      
  Scenario: A website queries the country list in JSON format
    When I go to the countries exposed via JSON in the API
    
    Then I should see JSON:
      """
      [
        {"name": "Argentina", "iso2": "ar", "iso3": "arg", "phone_prefix": "54"},
        {"name": "Brazil", "iso2": "br", "iso3": "bra", "phone_prefix": "55"}
      ]
      """
