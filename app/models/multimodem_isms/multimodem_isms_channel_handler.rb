# coding: utf-8

class MultimodemIsmsChannelHandler < ChannelHandler
  include GenericChannelHandler

  def self.title
    "Multimodem iSms"
  end

  def check_valid
    check_config_not_blank :host, :user, :password
    check_config_port :required => false
  end

  def info
    config = @channel.configuration
    if config[:port].present?
      "#{config[:user]}@#{config[:host]}:#{config[:port]}"
    else
      "#{config[:user]}@#{config[:host]}"
    end
  end

  def on_create
    super
    if @channel.enabled
      @channel.create_task('multimodem-isms-receive', MULTIMODEM_ISMS_RECEIVE_INTERVAL, ReceiveMultimodemIsmsMessageJob.new(@channel.account_id, @channel.id))
    end
  end

  def on_enable
    super
    @channel.create_task('multimodem-isms-receive', MULTIMODEM_ISMS_RECEIVE_INTERVAL, ReceiveMultimodemIsmsMessageJob.new(@channel.account_id, @channel.id))
  end

  def on_disable
    super
    @channel.drop_task('multimodem-isms-receive')
  end

  def on_pause
    super
    @channel.drop_task('multimodem-isms-receive')
  end

  def on_resume
    super
    @channel.create_task('multimodem-isms-receive', MULTIMODEM_ISMS_RECEIVE_INTERVAL, ReceiveMultimodemIsmsMessageJob.new(@channel.account_id, @channel.id))
  end

  def on_destroy
    super
    if @channel.enabled
      @channel.drop_task('multimodem-isms-receive')
    end
  end

  ERRORS = {
    601 => { :kind => :fatal, :description => 'Authentication Failed Send API, Query API'},
    602 => { :kind => :fatal, :description => 'Parse Error Send API, Query API'},
    603 => { :kind => :fatal, :description => 'Invalid Category Send API'},
    604 => { :kind => :message, :description => 'SMS message size is greater than 160 chars Send API'},
    605 => { :kind => :fatal, :description => 'Recipient Overflow Send API'},
    606 => { :kind => :message, :description => 'Invalid Recipient Query API'},
    607 => { :kind => :message, :description => 'No Recipient Send API'},
    608 => { :kind => :unexpected, :description => 'MultiModem iSMS is busy, can’t accept this request Send API, Query API'},
    609 => { :kind => :unexpected, :description => 'Timeout waiting for a TCP API request Send API'},
    610 => { :kind => :unexpected, :description => 'Unknown Action Trigger Send API'},
    611 => { :kind => :unexpected, :description => 'Error in broadcast trigger Send API'},
    612 => { :kind => :unexpected, :description => 'System Error – Memory Allocation Failure Send API, Query API'},
    613 => { :kind => :fatal, :description => 'Invalid Modem Index'},
    614 => { :kind => :fatal, :description => 'Invalid device model number'},
    615 => { :kind => :message, :description => 'Invalid Encoding type Send API'},
    616 => { :kind => :message, :description => 'Invalid Time/Date Input Receive API'},
    617 => { :kind => :message, :description => 'Invalid Count Input Receive API'},
    618 => { :kind => :fatal, :description => 'Service Not Available (Non-Polling Receive API is enabled so Polling Receive API service is not available)'},
    619 => { :kind => :message, :description => 'Invalid Addressee Receive API'},
    620 => { :kind => :message, :description => 'Invalid Priority value Send API'},
    621 => { :kind => :message, :description => 'Invalid SMS text'}
  }
end
