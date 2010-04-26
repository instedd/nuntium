module ClientQstJob
  
  require 'net/http'
  require 'uri'
  
  include CronTask::QuotedTask
  
  # Executes loop
  def perform
    begin
      result = perform_batch
    end while result == :success_pending and has_quota?
    result
  end
  
  # Initialize http connection
  def create_http(cfg, target=nil)
    begin
      uri = URI.parse(cfg.url) 
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    rescue => e
      cfg.logger.error_initializing_http e
      cfg.set_last_at_guid nil
      return nil, nil
    else
      path = uri.path
      if not target.nil?
        path << '/' unless path.blank? or path[-1..-1] == '/'
        path << target
      end
      return http, path  
    end
  end

  # Validates application for QST
  def validate_application(application)
    if application.nil?
      Rails.logger.warn 'Validate application for QST: application not found'
      return :error_no_application
    elsif application.configuration.nil? or application.configuration[:url].nil?
      Rails.logger.warn "Validate application for QST: no url found in application configuration for pushing/pulling messages in application #{application.name}"
      return :error_no_url_in_configuration
    elsif not application.interface == 'qst_client'
      Rails.logger.warn "Validate application for QST: found interface #{application.interface} when expecting qst in application #{application.name}"
      return :error_wrong_interface
    end
    nil
  end

  # Validates channel for QST
  def validate_channel(channel)
    if channel.nil?
      Rails.logger.warn 'Validate channel for QST: channel not found'
      return :error_no_channel
    elsif not channel.enabled
      Rails.logger.warn "Validate channel for QST: channel #{channel.id} is disabled"
      return :error_channel_disabled
    elsif channel.configuration.nil? or channel.configuration[:url].nil?
      Rails.logger.warn "Validate channel for QST: no url found in channel configuration for pushing/pulling messages in channel #{channel.id}"
      return :error_no_url_in_configuration
    end
    nil
  end

end
