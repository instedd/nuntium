class AccountsController < ApplicationController
  skip_filter :check_account, :only => [:new, :create]

  def new
    @account = Account.new
  end

  def create
    @account = Account.new params[:account]
    if current_user.create_account(@account)
      redirect_to applications_path
    else
      render :new
    end
  end

  def select
    account = Account.find params[:id]
    current_user.current_account = account
    current_user.save!

    redirect_to :back
  end
end