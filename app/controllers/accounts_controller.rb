class AccountsController < ApplicationController
  skip_before_action :check_account, :only => [:new, :create, :reclaim]

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

  def reclaim
    account = Account.find_by_name params[:account][:name]
    if account && account.authenticate(params[:account][:password])
      current_user.join_account account, :admin
      current_user.current_account = account
      current_user.save!

      redirect_to root_path, notice: "Account #{account.name} reclaimed"
    else
      @account = Account.new
      @acount_reclaim_error = true
      if params[:from_reclaim] == '1'
        render 'reclaims/index'
      else
        render 'new'
      end
    end
  end
end
