class ApiTwitterChannelController < ApiAuthenticatedController

  def friendship_create
    channel = @account.find_channel params[:name]
    
    return head :not_found unless channel
    return head :forbidden if @application && !channel.application_id
    
    user = params[:user]
    follow = params[:follow].to_b
    
    result = channel.handler.friendship_create user, follow
    
    render :json => result
  end

end
