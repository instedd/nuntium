# Copyright (C) 2009-2012, InSTEDD
# 
# This file is part of Nuntium.
# 
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

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

  def self.red(string)
    "\033[31m#{string}\033[0m"
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
          puts red("Country not found: #{row[0]}") unless options[:silent]
        end
        next
      end

      next if not country # missing country => missing carrier
      carrier = Carrier.find_by_clickatell_name row[2]
      if not carrier
        puts red("Country/carrier not found: #{country.clickatell_name} - #{row[2]}") unless options[:silent]
        next
      end

      ::ClickatellChannel::CLICKATELL_NETWORKS.each do |network_key, network_desc|
        next if network_key == 'usa'

        network_column_index = firstRow.index(network_desc)
        if not network_column_index
          puts red("Network not found in the CSV: #{network_desc}")
          next
        end
        cost = row[network_column_index]
        cov = ::ClickatellCoverageMO.find_by_country_id_and_carrier_id_and_network country.id, carrier.id, network_key

        if cost == 'x'
          if cov
            cov.delete unless options[:pretend]
            puts "Deleted #{country.clickatell_name} - #{carrier.clickatell_name} - #{network_key}" unless options[:silent]
          end
          next
        end

        if cov
          if cov.cost != cost.to_f
            cov.cost = cost.to_f
            cov.save! unless options[:pretend]

            puts "Updated #{country.clickatell_name} - #{carrier.clickatell_name} - #{network_key} to cost #{cost}" unless options[:silent]
          end
        else
          ::ClickatellCoverageMO.create! :country_id => country.id, :carrier_id => carrier.id, :network => network_key, :cost => cost.to_f unless options[:pretend]
          puts "Created #{country.clickatell_name} - #{carrier.clickatell_name} - #{network_key} with cost #{cost}" unless options[:silent]
        end
      end
    end

    usa = Country.find_by_iso2('US')
    if usa
      cov = ::ClickatellCoverageMO.find_by_country_id_and_carrier_id_and_network usa.id, nil, 'usa'
      if not cov
        ClickatellCoverageMO.create! :country_id => usa.id, :carrier_id => nil, :network => 'usa', :cost => 1 unless options[:pretend]
        puts "Created #{usa.clickatell_name} - usa with cost 1" unless options[:silent]
      end
    else
      puts "\033[31mCan't create usa network: country US not founde\033[0m"
    end

    ClickatellChannel.find_each do |chan|
      chan.clear_restrictions_cache unless options[:pretend]
    end
  end

  private

  def self.get(path)
    RestClient.get "https://api.clickatell.com#{path}"
  end

end
