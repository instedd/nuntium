module ChannelsUiHelper
  def new_channels_ui_path_for(options)
    new_params = { access_token: params[:access_token] }
    new_params.merge!(account: params[:account]) if params[:account]

    new_channels_ui_path(new_params.merge(options))
  end
end
