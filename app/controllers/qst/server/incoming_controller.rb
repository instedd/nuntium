class IncomingController < QSTServerController
  # HEAD /qst/:account_id/incoming
  def index
    return head(:not_found) unless request.head?
    msg = ATMessage.select(:guid).where(:account_id => @account.id).order(:timestamp).last
    etag = msg.nil? ? nil : msg.guid
    head :ok, 'Etag' => etag
  end

  # POST /qst/:account_id/incoming
  def create
    tree = request.POST.present? ? request.POST : Hash.from_xml(request.raw_post).with_indifferent_access

    last_id = nil
    ATMessage.parse_xml(tree) do |msg|
      @account.route_at msg, @channel
      last_id = msg.guid
    end

    head :ok, 'Etag' => last_id
  end
end
