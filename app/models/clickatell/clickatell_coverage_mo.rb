class ClickatellCoverageMO < ActiveRecord::Base  
  belongs_to :country
  belongs_to :carrier
  
  before_destroy :clear_cache 
  after_save :clear_cache
  
  def self.find_all_by_network(network)
    mos = Rails.cache.read 'clickatell_coverage_mos'
    if not mos
      mos = ClickatellCoverageMO.all
      to_cache = Hash.new
      mos.each do |mo|
        to_cache[mo.network] = [] unless to_cache.has_key? mo.network
        to_cache[mo.network] << mo
      end
      mos = to_cache
      Rails.cache.write 'clickatell_coverage_mos', mos 
    end
    mos[network] || []
  end
  
  private
  
  def clear_cache
    Rails.cache.delete 'clickatell_coverage_mos'
    true
  end
  
end
