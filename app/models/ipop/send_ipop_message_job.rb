class SendIpopMessageJob < SendMessageJob
  def managed_perform
    data = {
      :hp => @msg.to.mobile_number,
      :ts => @msg.timestamp.strftime('%Y%m%d%H%M%S') + ("%03d" % @msg.timestamp.milliseconds),
      :bid => @config[:bid],
      :cid => @config[:cid],
      :mt => 1,
      :txt => @msg.subject_and_body,
      :sc => @channel.address
    }

    options = {:headers => {:content_type => "application/x-www-form-urlencoded"}}

    res = RestClient::Resource.new(@config[:mt_post_url], options)
    res = res.post data
    netres = res.net_http_res

    case netres
      when Net::HTTPSuccess, Net::HTTPRedirection
        raise res.body if res.body.blank? || res.body.strip != 'OK'

        @msg.channel_relative_id = "#{@msg.to.mobile_number}-#{data[:ts]}"
      else
        raise netres.error!
    end
  end
end
