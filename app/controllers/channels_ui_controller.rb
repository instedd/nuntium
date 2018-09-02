class ChannelsUiController < ApplicationController
  skip_before_filter :check_guisso_cookie
  before_filter :new_channel, only: [:new, :create]
  layout 'channels_ui'

  def check_guisso_cookie
    true
  end

  def new
    load_config_from_channel() if @channel
  end

  def create
    load_config_to_channel()
    unless @channel.save
      load_config_from_channel()
      render "new"
    end
  end

  def show
    @channel = channels.find_by_name(params[:id])
    load_config_from_channel()
  end

  def update
    params[:config] = params[:config].except("name")
    @channel = channels.find_by_name(params[:id])
    load_config_to_channel()
    unless @channel.save
      load_config_from_channel()
      render "show"
    end
  end

  private

  def new_channel
    if params[:kind]
      @channel = params[:kind].to_channel.new
    end
  end

  def load_config_from_channel
    @kind = @channel.kind
    @config =
      case @kind
      when "twilio"
        OpenStruct.new({
          name: @channel.name,
          account_sid: @channel.account_sid,
          auth_token: @channel.auth_token,
          from: @channel.from,
          errors: @channel.errors
        })
      when "chikka"
        OpenStruct.new({
          name: @channel.name,
          shortcode: @channel.shortcode,
          client_id: @channel.client_id,
          secret_key: @channel.secret_key,
          secret_token: @channel.secret_token,
          errors: @channel.errors
        })
      when "africas_talking"
        OpenStruct.new({
          name: @channel.name,
          username: @channel.username,
          api_key: @channel.api_key,
          shortcode: @channel.shortcode,
          secret_token: @channel.secret_token,
          use_sandbox: @channel.use_sandbox,
          errors: @channel.errors
        })
      when "smpp"
        OpenStruct.new({
          name: @channel.name,
          # max_unacknowledged_messages: @channel.max_unacknowledged_messages,
          host: @channel.host,
          port: @channel.port,
          user: @channel.user,
          password: @channel.password,
          system_type: @channel.system_type,
          source_ton: @channel.source_ton,
          source_npi: @channel.source_npi,
          destination_npi: @channel.destination_npi,
          destination_ton: @channel.destination_ton,
          endianness_mo: @channel.endianness_mo,
          endianness_mt: @channel.endianness_mt,
          accept_mo_hex_string: @channel.accept_mo_hex_string,
          default_mo_encoding: @channel.default_mo_encoding,
          mt_encodings: @channel.mt_encodings,
          mt_max_length: @channel.mt_max_length,
          mt_csms_method: @channel.mt_csms_method,
          suspension_codes: @channel.suspension_codes,
          rejection_codes: @channel.suspension_codes,
          errors: @channel.errors
        })
        when "qst_server"
        OpenStruct.new({
          name: @channel.name,
          ticket_code: @channel.ticket_code,
          errors: @channel.errors
        })
      end
  end

  def load_config_to_channel
    if params[:config][:name]
      @channel.name = params[:config][:name]
    end
    @channel.account = account
    @channel.direction = Channel::Bidirectional
    @channel.protocol = TwilioChannel.default_protocol

    case @channel.kind
    when "twilio"
      @channel.account_sid = params[:config][:account_sid]
      @channel.auth_token = params[:config][:auth_token]
      @channel.from = params[:config][:from]
    when "chikka"
      @channel.shortcode = params[:config][:shortcode]
      @channel.client_id = params[:config][:client_id]
      @channel.secret_key = params[:config][:secret_key]
      @channel.secret_token = params[:config][:secret_token]
    when "africas_talking"
      @channel.username = params[:config][:username]
      @channel.api_key = params[:config][:api_key]
      @channel.shortcode = params[:config][:shortcode]
      @channel.secret_token = params[:config][:secret_token]
      @channel.use_sandbox = params[:config][:use_sandbox]
    when "smpp"
      # @channel.max_unacknowledged_messages = params[:config][:max_unacknowledged_messages]
      @channel.host = params[:config][:host]
      @channel.port = params[:config][:port]
      @channel.user = params[:config][:user]
      @channel.password = params[:config][:password]
      @channel.system_type = params[:config][:system_type]
      @channel.source_ton = params[:config][:source_ton]
      @channel.source_npi = params[:config][:source_npi]
      @channel.destination_npi = params[:config][:destination_npi]
      @channel.destination_ton = params[:config][:destination_ton]
      @channel.endianness_mo = params[:config][:endianness_mo]
      @channel.endianness_mt = params[:config][:endianness_mt]
      @channel.accept_mo_hex_string = params[:config][:accept_mo_hex_string]
      @channel.default_mo_encoding = params[:config][:default_mo_encoding]
      @channel.mt_encodings = params[:config][:mt_encodings]
      @channel.mt_max_length = params[:config][:mt_max_length]
      @channel.mt_csms_method = params[:config][:mt_csms_method]
      @channel.suspension_codes = params[:config][:suspension_codes]
      @channel.rejection_codes = params[:config][:rejection_codes]
    when "qst_server"
      # A new password is assigned every time a new ticket_code is used
      new_password = SecureRandom.base64 6
      @channel.use_ticket = true
      @channel.ticket_code = params[:config][:ticket_code]
      @channel.password = new_password
      @channel.password_confirmation = new_password
    end
  end
end
