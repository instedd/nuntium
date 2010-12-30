class IpopChannelHandler < GenericChannelHandler
  def self.title
    "I-POP"
  end

  def check_valid
    check_config_not_blank :mt_post_url, :bid, :cid
  end
end
