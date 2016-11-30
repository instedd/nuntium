class ApiApplicationsController < ApiAuthenticatedController
  before_filter :require_account_and_application!

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
