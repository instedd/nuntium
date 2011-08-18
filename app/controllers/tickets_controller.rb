class TicketsController < ApplicationController
  skip_filter :check_login

  def create
    Ticket.remove_expired

    ticket = Ticket.checkout clean_params
    render :json => ticket.to_json
  end

  def show
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
    r.symbolize_keys
  end
end
