class AddressController < QSTServerController
  def update
    @channel.address = params[:address]
    @channel.save!
    head :ok
  end
end
