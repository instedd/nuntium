module AoMessageCreateCommon
  private

  def create_from_request
    case params[:format]
    when nil
      create_single
    when 'json'
      create_many_json
    when 'xml'
      create_many_xml
    end
  end

  def create_single
    msg = AoMessage.from_hash params
    msg.token = params.delete(:token) || Guid.new.to_s
    route msg

    response.headers['X-Nuntium-Id'] = msg.id.to_s
    response.headers['X-Nuntium-Guid'] = msg.guid.to_s
    response.headers['X-Nuntium-Token'] = msg.token.to_s
    head :ok
  end

  def create_many_json
    create_many :from_json
  end

  def create_many_xml
    create_many :parse_xml
  end

  def create_many(method)
    token = Guid.new.to_s
    AoMessage.send(method, request.raw_post) do |msg|
      token = msg.token if msg.token
      msg.token = token
      route msg
    end
    response.headers['X-Nuntium-Token'] = token
    head :ok
  end

  def route(msg)
    msg.account_id = @account.id
    msg.token ||= Guid.new.to_s
    @application.route_ao msg, 'http'
  end
end
