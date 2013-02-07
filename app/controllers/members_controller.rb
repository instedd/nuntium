class MembersController < ApplicationController
  expose(:user_accounts) { account.user_accounts }
  expose(:user_applications) { UserApplication.where(account_id: account.id).includes(:user, :application) }
  expose(:user_channels) { UserChannel.where(account_id: account.id).includes(:user, :channel) }
  expose(:users) { user_accounts.map(&:user).uniq.sort_by(&:email) }
  expose(:channels) { account.channels.where(application_id: nil) }

  def index
  end

  def autocomplete
    users = User.
      where('email LIKE ?', "#{params[:term]}%").
      where('id not in (?)', account.user_accounts.pluck(:user_id))
    render json: users.pluck(:email)
  end

  def add
    user = User.find_by_email params[:email]
    return render json: {ok: false, error: 'User not found'} unless user
    return render json: {ok: false, error: 'User already belongs to this account'} if user_accounts.where(user_id: user.id).exists?

    user.join_account account

    render json: {ok: true, user: {id: user.id, name: user.display_name, role: 'member'}}
  end

  def remove
    user = User.find_by_id params[:id]
    return render json: {ok: false, error: 'User not found'} unless user

    account.remove_user(user)

    render json: {ok: true}
  end

  def set_user_role
    user = User.find_by_id params[:id]
    return render json: {ok: false, error: 'User not found'} unless user

    account.set_user_role(user, params[:role])

    render json: {ok: true}
  end

  def set_user_application_role
    user = User.find_by_id params[:user_id]
    return render json: {ok: false, error: 'User not found'} unless user

    account.set_user_application_role(user, params[:application_id], params[:role])

    render json: {ok: true}
  end

  def set_user_channel_role
    user = User.find_by_id params[:user_id]
    return render json: {ok: false, error: 'User not found'} unless user

    account.set_user_channel_role(user, params[:channel_id], params[:role])

    render json: {ok: true}
  end
end