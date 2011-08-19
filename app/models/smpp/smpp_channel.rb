class SmppChannel < Channel
  include ServiceChannel

  configuration_accessor :user, :password
  configuration_accessor :host, :system_type, :port, :source_ton, :source_npi, :destination_ton, :destination_npi
  configuration_accessor :default_mo_encoding, :mt_encodings, :mt_csms_method

  validates_presence_of :host, :system_type
  validates_presence_of :user, :password, :default_mo_encoding, :mt_encodings, :mt_csms_method
  validates_numericality_of :port, :greater_than => 0
  validates_numericality_of :source_ton, :source_npi, :destination_ton, :destination_npi, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 7

  def self.title
    "SMPP"
  end

  def check_valid_in_ui
    # what kind of validation should we put here?
    # what if the smpp connection require a vpn?
  end

  def info
    str = "#{user}@#{host}:#{port}"
    str << " (#{throttle}/min)" if throttle != 0
    str
  end
end
