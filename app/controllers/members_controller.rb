class MembersController < ApplicationController
  expose(:user_accounts) { account.user_accounts.includes(:user).all }
  expose(:user_applications) { UserApplication.where(application_id: applications.map(&:id)).includes(:user, :application).all }
  expose(:users) { user_accounts.map(&:user).uniq.sort_by(&:email) }
end