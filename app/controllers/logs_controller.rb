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

class LogsController < ApplicationController
  def index
    @page = params[:page].presence || 1
    @search = params[:search]
    @previous_search = params[:previous_search]
    @page = 1 if @previous_search.present? && @previous_search != @search

    @logs = account.logs.includes(:application, :channel).order 'id DESC'
    @logs = @logs.search @search if @search.present?
    @logs = @logs.paginate :page => @page, :per_page => ResultsPerPage
    @logs = @logs.all
  end
end
