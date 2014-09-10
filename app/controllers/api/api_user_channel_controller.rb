class ApiUserChannelController < ApiUserAuthenticationController
  # GET /api/accounts.:format
  def index
  	channels = []
  	@user.accounts.each do |acc|
  		channels.concat acc.channels
  	end
    render :json => channels
  end

end