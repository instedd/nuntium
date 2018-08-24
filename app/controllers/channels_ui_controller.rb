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
    @channel = channels.find(params[:id])
    load_config_from_channel()
  end

  def update
    @channel = channels.find(params[:id])
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
    @kind = channel.kind
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
      end
  end

  def load_config_to_channel
    @channel.account = account
    @channel.direction = Channel::Bidirectional
    @channel.protocol = TwilioChannel.default_protocol
    case @channel.kind
    when "twilio"
      @channel.name = params[:config][:name]
      @channel.account_sid = params[:config][:account_sid]
      @channel.auth_token = params[:config][:auth_token]
      @channel.from = params[:config][:from]
    end
  end
end
