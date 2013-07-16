# Copyright (C) 2009-2012, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

class CustomAttributesController < ApplicationController
  include CustomAttributesControllerCommon

  before_filter :check_account_admin

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
