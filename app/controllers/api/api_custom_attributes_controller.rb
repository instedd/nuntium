class ApiCustomAttributesController < ApiAuthenticatedController

  # GET /api/custom_attributes?address=:address
  def show
    custom_attr = @account.custom_attributes.find_by_address params[:address]
    return head :not_found unless custom_attr
    render :json => custom_attr.custom_attributes || {}
  end

  # POST /api/custom_attributes?address=:address
  def create_or_update
    custom_attr = @account.custom_attributes.find_by_address params[:address]
    custom_attr ||= @account.custom_attributes.new :address => params[:address], :custom_attributes => {}
    data = request.POST.present? ? request.POST : request.raw_post
    data = JSON.parse data if data.is_a? String

    data.each do |key, value|
      if value.present?
        custom_attr.custom_attributes[key] = value
      else
        custom_attr.custom_attributes.delete key
      end
    end

    if custom_attr.custom_attributes.count > 0
      custom_attr.save!
    else
      custom_attr.delete
    end
    head :ok
  end

end