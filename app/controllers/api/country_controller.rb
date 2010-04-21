class CountryController < ApplicationController

  def index
    case params[:format]
    when 'xml'
      render :xml => Country.all.to_xml
    when 'json'
      render :json => Country.all.to_json(:except => [:id, :created_at, :updated_at])
    else
      head :bad_request
    end
  end

end
