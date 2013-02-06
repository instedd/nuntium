class MembersController < ApplicationController
  expose(:user_accounts) { account.user_accounts }
  expose(:user_applications) { UserApplication.where(application_id: applications.map(&:id)).includes(:user, :application) }
  expose(:user_channels) { UserChannel.where(channel_id: channels.map(&:id)).includes(:user, :channel) }
  expose(:users) { user_accounts.map(&:user).uniq.sort_by(&:email) }

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
end