class ApiApplicationsController < ApiAuthenticatedController

  def show
    return head :not_found unless params[:id] == 'me'
    render json: @application
  end

  def update
    return head :not_found unless params[:id] == 'me'

    @application.update_from(JSON.parse request.raw_post)
    @application.save!

    render json: @application
  end

end
