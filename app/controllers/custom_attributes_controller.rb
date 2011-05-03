class CustomAttributesController < AccountAuthenticatedController
  before_filter :check_login
  include CustomAttributesControllerCommon

  # GET /custom_attributes
  def index
    conditions = ['account_id = ?', @account.id]
    @custom_attributes = CustomAttribute.paginate(
      :conditions => conditions,
      :order => 'address',
      :page => params[:page],
      :per_page => 20
      )
  end

  # GET /custom_attributes/new
  def new
    @custom_attribute = CustomAttribute.new :custom_attributes => {}
    render :edit
  end

  # GET /custom_attributes/1/edit
  def edit
    @custom_attribute = @account.custom_attributes.find(params[:id])
    @custom_attribute[:custom_attributes] ||= {}
  end

  # POST /custom_attributes
  def create
    attrs = {
      :address => params[:custom_attribute][:address],
      :custom_attributes => get_custom_attributes
    }
    @custom_attribute = @account.custom_attributes.new(attrs)

    if @custom_attribute.save
      flash[:notice] = 'CustomAttribute was successfully created.'
      redirect_to :action => :index
    else
      render :action => "new"
    end
  end

  # PUT /custom_attributes/1
  def update
    @custom_attribute = @account.custom_attributes.find(params[:id])
    attrs = {
      :address => params[:custom_attribute][:address],
      :custom_attributes => get_custom_attributes
    }

    if @custom_attribute.update_attributes(attrs)
      flash[:notice] = 'CustomAttribute was successfully updated.'
      redirect_to :action => :index
    else
      render :action => "edit"
    end
  end

  # DELETE /custom_attributes/1
  def destroy
    @custom_attribute = @account.custom_attributes.find(params[:id])
    @custom_attribute.destroy

    redirect_to :action => :index
  end
end
