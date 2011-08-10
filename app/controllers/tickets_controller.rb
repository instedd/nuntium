class TicketsController < ApplicationController

  def checkout
    Ticket.remove_expired
    
    ticket = Ticket.checkout clean_params
    render :json => ticket.to_json
  end
  
  def keep_alive
    begin
      ticket = Ticket.keep_alive params[:code], params[:secret_key]
    rescue RuntimeError
      return head :not_found
    end
    render :json => ticket.to_json
  end
  
private

  def clean_params
    r = params.reject { |k,v| [:action,:controller,:format].include?(k.to_sym) }
    r.to_options
  end
end
