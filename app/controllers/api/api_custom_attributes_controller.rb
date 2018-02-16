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

class ApiCustomAttributesController < ApiAuthenticatedController
  before_action :require_account!

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
