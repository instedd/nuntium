class ApiTwitterChannelController < ApiAuthenticatedController

  def friendship_create
    channel = @account.channels.find_by_name params[:name]

    return head :not_found unless channel
    return head :forbidden if @application && !channel.application_id
    return head :bad_request if channel.kind != 'twitter'

    user = params[:user]
    follow = params[:follow].to_b

    begin
      result = channel.friendship_create user, follow
    rescue Twitter::TwitterError, Twitter::NotFound, Twitter::InformTwitter, Twitter::Unavailable => e
      index = e.message.index '):'
      code = e.message[1 .. index].to_i
      msg = e.message[index + 2 .. -1].strip
      return render :text => msg, :status => code
    end

    head :ok
  end

end
