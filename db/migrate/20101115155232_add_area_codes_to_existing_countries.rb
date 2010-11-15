class AddAreaCodesToExistingCountries < ActiveRecord::Migration
  def self.up
    [
      ['AI', '264'],
      ['AG', '268'],
      ['BS', '242'],
      ['BB', '246'],
      ['BM', '441'],
      ['VG', '284'],
      ['CA', "204,226,236,249,250,289,306,343,365,403,416,418,431,438,450,506,514,519,579,581,587,600,604,613,647,705,709,778,780,807,819,867,873,902,905"],
      ['KY', '345'],
      ['DM', '767'],
      ['DO', '809,829,849'],
      ['GD', '473'],
      ['GU', '671'],
      ['JM', '876'],
      ['MS', '664'],
      ['MP', '670'],
      ['PR', '787,939'],
      ['KN', '869'],
      ['LC', '758'],
      ['MF', '599,721'],
      ['VC', '784'],
      ['TT', '868'],
      ['TC', '649'],
      ['VI', '340']
    ].each do |iso, area_codes|
      c = Country.find_by_iso2 iso
      next unless c
      c.phone_prefix = '1'
      c.area_codes = area_codes
      c.save!
    end
  end

  def self.down
  end
end
