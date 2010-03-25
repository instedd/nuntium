class AddSmppChannelPropertiesToExistingChannels < ActiveRecord::Migration
  def self.up
    Channel.all(:conditions => ['kind = ?', 'smpp']).each do |c|
      c.configuration[:mt_encodings] = ['ascii', 'latin1', 'ucs-2']
      c.configuration[:endianness] = 'big'
      c.configuration[:default_mo_encoding] = 'ascii'
      c.configuration[:mt_csms_method] = 'udh'
      c.configuration[:mt_max_length] = 160
      c.save!
    end
  end

  def self.down
  end
end
