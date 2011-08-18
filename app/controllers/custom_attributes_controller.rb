class CustomAttributesController < ApplicationController
  include CustomAttributesControllerCommon

  # GET /custom_attributes
  def index
    @custom_attributes = account.custom_attributes.order :address

    @search = params[:search]
    @custom_attributes = @custom_attributes.search @search if @search.present?
    @custom_attributes = @custom_attributes.paginate :page => params[:page], :per_page => 20
  end

  # GET /custom_attributes/new
  def new
    @custom_attribute = CustomAttribute.new :custom_attributes => {}
  end

  # GET /custom_attributes/1/edit
  def edit
    @custom_attribute = account.custom_attributes.find params[:id]
    @custom_attribute[:custom_attributes] ||= {}
  end

  # POST /custom_attributes
  def create
    attrs = {
      :address => params[:custom_attribute][:address],
      :custom_attributes => get_custom_attributes
    }
    @custom_attribute = account.custom_attributes.new attrs

    if @custom_attribute.save
      redirect_to custom_attributes_path, :notice => 'CustomAttribute was successfully created.'
    else
      render :new
    end
  end

  # PUT /custom_attributes/1
  def update
    @custom_attribute = account.custom_attributes.find(params[:id])
    attrs = {
      :address => params[:custom_attribute][:address],
      :custom_attributes => get_custom_attributes
    }

    if @custom_attribute.update_attributes attrs
      redirect_to custom_attributes_path, :notice => 'CustomAttribute was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /custom_attributes/1
  def destroy
    @custom_attribute = account.custom_attributes.find params[:id]
    @custom_attribute.destroy

    redirect_to custom_attributes_path
  end
end
