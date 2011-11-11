class ApiXmppChannelController < ApiAuthenticatedController
  def add_contact
    channel = @account.channels.find_by_name params[:name]

    return head :not_found unless channel
    return head :forbidden if @application && !channel.application_id
    return head :bad_request if channel.kind != 'xmpp'
    return head :bad_request if params[:jid].blank?

    channel.add_contact params[:jid]

    head :ok
  end
end
