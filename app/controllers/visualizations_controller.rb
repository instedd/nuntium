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

class VisualizationsController < ApplicationController
  def messages_state_by_day
    @selected_tab = :visualizations
    @kind = params[:kind]
    @kind = 'ao' unless @kind == 'ao' || @kind == 'at'
    @two_months_ago = Date.today - 2.months
    if @two_months_ago.year == Date.today.year
      @prefix = "#{Date.today.year}-"
      @month_and_day = "concat(month(updated_at), '-', day(updated_at))"
    else
      @month_and_day = "concat(toDate(updated_at))"
    end
    @two_months_ago = @two_months_ago.strftime '%Y-%m-%d'
    render 'messages_state_by_day'
  end
end
