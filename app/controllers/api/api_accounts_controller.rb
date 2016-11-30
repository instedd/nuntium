class ApiAccountsController < ApiAuthenticatedController
  def index
    render json: current_user.accounts.map(&:name)
  end
end
