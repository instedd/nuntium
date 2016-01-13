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

require 'test_helper'

class ChannelsControllerTest < ActionController::TestCase
  def setup
    @user = User.make!
    @account = @user.create_account Account.make
    sign_in @user
  end

  test "create qst server channel succeeds" do
    attrs = QstServerChannel.make.attributes.merge(:kind => 'qst_server')

    post :create, :channel => attrs

    # Go to channels page
    assert_redirected_to channels_path
    assert_equal "Channel #{attrs['name']} was created", flash[:notice]

    # The channel was created
    chans = Channel.all
    assert_equal 1, chans.length

    chan = chans[0]
    assert_equal @account.id, chan.account_id
    assert_equal attrs['name'], chan.name
    assert_equal attrs['protocol'], chan.protocol
    assert_equal attrs['kind'], chan.kind
    assert chan.authenticate(attrs['configuration'][:password])
  end

  test "edit channel change password succeeds" do
    chan = QstServerChannel.make! :account => @account

    put :update, :id => chan.id, :channel => {:protocol => 'sms', :direction => Channel::Bidirectional, :configuration => {:password => 'new_pass', :password_confirmation => 'new_pass'}}

    # Go to channels page
    assert_redirected_to channels_path
    assert_equal "Channel #{chan.name} was updated", flash[:notice]

    # The channel was changed
    chans = Channel.all
    assert_equal 1, chans.length
    chan = chans[0]
    assert chan.authenticate('new_pass')
  end

  test "edit qst server channel succeeds" do
    app1 = Application.make! :account => @account
    app2 = Application.make! :account => @account
    chan = QstServerChannel.make :account => @account, :priority => 100, :application_id => app1.id
    chan.configuration[:password] = 'chan_pass'
    chan.configuration[:password_confirmation] = 'chan_pass'
    chan.configuration.delete :salt
    chan.save!

    put :update, :id => chan.id, :channel => {:protocol => 'mail', :priority => 200, :application_id => app2.id, :direction => Channel::Bidirectional, :configuration => {:password => '', :password_confirmation => ''}}

    # Go to channels page
    assert_redirected_to channels_path
    assert_equal "Channel #{chan.name} was updated", flash[:notice]

    # The channel was changed
    chans = Channel.all
    assert_equal 1, chans.length

    chan = chans[0]

    assert_equal 'mail', chan.protocol
    assert_equal 200, chan.priority
    assert_equal app2.id, chan.application_id
    assert chan.authenticate('chan_pass')
  end

  test "delete channel" do
    chan = QstServerChannel.make! :account => @account

    delete :destroy, :id => chan.id

    # Go to channels page
    assert_redirected_to channels_path
    assert_equal "Channel #{chan.name} was deleted", flash[:notice]

    # The channel was deleted
    chans = Channel.all
    assert_equal 0, chans.length
  end

  test "edit channel fails protocol empty" do
    chan = QstServerChannel.make! :account => @account

    put :update, :id => chan.id, :channel => {:protocol => '', :direction => Channel::Bidirectional, :configuration => {:password => '', :password_confirmation => ''}}

    assert_template "channels/edit"
  end

  test "enable channel" do
    chan = QstServerChannel.make! :account => @account, :enabled => false

    get :enable, :id => chan.id

    # Go to channels page
    assert_response :ok
    assert_equal "Channel #{chan.name} was enabled", @response.body

    # The channel was enabled
    chans = Channel.all
    assert_true chans[0].enabled
  end

  test "disable channel re-routes" do
    chan1 = QstServerChannel.make! :account => @account
    chan2 = QstServerChannel.make! :account => @account

    app = Application.make! :account => @account
    msg = AoMessage.make! :account => @account, :application => app, :channel => chan1, :state => 'queued'

    get :disable, :id => chan1.id

    chan1.reload
    chan2.reload
    msg.reload

    assert_false chan1.enabled
    assert_true chan2.enabled
    assert_equal chan2.id, msg.channel_id
  end

  test "pause channel" do
    chan = QstServerChannel.make! :account => @account

    get :pause, :id => chan.id

    assert_response :ok
    assert_equal "Channel #{chan.name} was paused", @response.body

    # The channel was paused
    chans = Channel.all
    assert_true chans[0].paused
  end

  test "resume channel" do
    chan = QstServerChannel.make! :account => @account, :paused => true

    get :resume, :id => chan.id

    # Go to channels page
    assert_response :ok
    assert_equal "Channel #{chan.name} was resumed", @response.body

    # The channel was resumed
    chans = Channel.all
    assert_false chans[0].paused
  end
end
