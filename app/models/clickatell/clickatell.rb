require 'csv'

module Clickatell

  def self.get_credit(query_parameters)
    Clickatell.get("/http/getbalance?#{query_parameters.to_query}").body
  end
  
  def self.get_status(query_parameters)
    Clickatell.get("/http/querymsg?#{query_parameters.to_query}").body 
  end

  def self.send_message(query_parameters)
    Clickatell.get "/http/sendmsg?#{query_parameters.to_query}"
  end
  
  def self.update_coverage_tables(options = {})
    firstRow = nil
    countryRow = nil
    country = nil
    carrier = nil
  
    puts "Downloading clickatell mo coverage..." unless options[:silent]
    csv = RestClient.get("http://www.clickatell.com/pricing/standard_mo_coverage.php?action=export&country=").to_s
    
    CSV.parse(csv) do |row|
      # empty row, skip
      next if row.size < 2
      
      # trim spaces
      row.map! { |x| x ? x.strip : x }
      
      # get header rows
      if not firstRow
        firstRow = row
        next
      end
      
      # if is country row
      if row[0]
        countryRow = row

        country = Country.find_by_clickatell_name row[0]
        if not country
          puts "\033[31mCountry not found: #{row[0]}\033[0m" unless options[:silent]
        end
        next
      end
      
      next if not country # missing country => missing carrier
      carrier = Carrier.find_by_clickatell_name row[2]
      if not carrier
        puts "\033[31mCountry/carrier not found: #{country.clickatell_name} - #{row[2]}\033[0m" unless options[:silent]
        next
      end
      
      ::ClickatellChannelHandler::CLICKATELL_NETWORKS.each do |network_key, network_desc|
        next if network_key == 'usa'
        
        network_column_index = firstRow.index(network_desc)
        cost = row[network_column_index]
        next if cost == 'x'
        
        cov = ::ClickatellCoverageMO.find_by_country_id_and_carrier_id_and_network country.id, carrier.id, network_key
        if cov
          if cov.cost != cost.to_f
            cov.cost = cost.to_f
            cov.save!
            
            puts "Updated #{country.clickatell_name} - #{carrier.clickatell_name} - #{network_key} to cost #{cost}" unless options[:silent]
          end 
        else
          ::ClickatellCoverageMO.create! :country_id => country.id, :carrier_id => carrier.id, :network => network_key, :cost => cost.to_f
          puts "Created #{country.clickatell_name} - #{carrier.clickatell_name} - #{network_key} with cost #{cost}" unless options[:silent]
        end
      end
    end
    
    usa = Country.find_by_iso2('US')
    if usa
      cov = ::ClickatellCoverageMO.find_by_country_id_and_carrier_id_and_network usa.id, nil, 'usa'
      if not cov
        ClickatellCoverageMO.create! :country_id => usa.id, :carrier_id => nil, :network => 'usa', :cost => 1
        puts "Created #{usa.clickatell_name} - usa with cost 1" unless options[:silent]
      end
    else
      puts "\033[31mCan't create usa network: country US not founde\033[0m"
    end
    
    Channel.find_each(:conditions => ['kind = ?', 'clickatell']) do |chan|
      chan.handler.clear_restrictions_cache
    end
  end
  
  private
  
  def self.get(path)
    RestClient.get "https://api.clickatell.com#{path}"
  end

end
