class Application < ActiveRecord::Base
  belongs_to :account
  has_many :ao_messages
  has_many :at_messages
  
  validates_presence_of :account_id
  validates_presence_of :name, :interface
  validates_uniqueness_of :name, :scope => :account_id, :message => 'Name has already been used by another application in the account'
  
  validates_inclusion_of :interface, :in => ['rss', 'qst_client', 'http_post_callback']
  
  serialize :configuration, Hash
  
  def configuration
    self[:configuration] = {} if self[:configuration].nil?
    self[:configuration]
  end
  
  def interface_description
    case interface
    when 'rss'
      return 'rss'
    when 'qst_client'
      return 'qst_client: ' << self.configuration[:url]
    when 'http_post_callback'
      return 'http_post_callback: ' << self.configuration[:url]
    end
  end
end
