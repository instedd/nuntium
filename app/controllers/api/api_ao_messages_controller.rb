class ApiAoMessagesController < ApiAuthenticatedController
  before_action :require_account_and_application!
  include AoMessageCreateCommon

  def create
    create_from_request
  end
end
