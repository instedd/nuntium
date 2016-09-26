class ApiAoMessagesController < ApiAuthenticatedController
  include AoMessageCreateCommon

  def create
    create_from_request
  end
end
