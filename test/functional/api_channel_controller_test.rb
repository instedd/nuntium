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

class ApiChannelControllerTest < ActionController::TestCase
  def setup
    @account = Account.make :password => 'secret'
    @application = Application.make :account => @account, :password => 'secret'
    @application2 = Application.make :account => @account

    account2 = Account.make
    app2 = Application.make :account => account2

    chan2 = QstServerChannel.make :account => account2
    chan3 = QstServerChannel.make :account => @account, :application => @application2
  end

  def authorize
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'secret')
  end

  def index(format, result_channel_count)
    yield if block_given?

    authorize
    get :index, :format => format

    case format
    when 'xml'
      xml = Hash.from_xml(@response.body).with_indifferent_access
      chans = xml[:channels]
      if result_channel_count == 0
        assert_nil chans
      else
        assert_equal result_channel_count, chans[:channel].length
      end
    when 'json'
      json = JSON.parse @response.body
      assert_equal result_channel_count, json.length
    end
  end

  def show(name, format, result_channel_count)
    yield if block_given?

    authorize
    get :show, :format => format, :name => name
    return assert_response :not_found if result_channel_count == 0
    assert_response :ok

    case format
    when 'xml'
      xml = Hash.from_xml(@response.body).with_indifferent_access
      assert_not_nil xml[:channel]
    when 'json'
      json = JSON.parse @response.body
      assert_not_nil json
    end
  end

  def update(name, channel, format)
    authorize
    @request.env['RAW_POST_DATA'] = channel.send("to_#{format}", :include_passwords => true)

    put :update, :format => format, :name => name

    assert_response :ok
  end

  def create(channel, format, expected_response = :ok)
    authorize
    @request.env['RAW_POST_DATA'] = channel.send("to_#{format}", :include_passwords => true)

    post :create, :format => format

    assert_response expected_response

    if expected_response == :ok
      case format
      when 'xml'
        xml = Hash.from_xml(@response.body).with_indifferent_access
        assert_not_nil xml[:channel]
      when 'json'
        json = JSON.parse @response.body
        assert_not_nil json
      end
    end
  end

  ['json', 'xml'].each do |format|
    test "index #{format} no channels" do
      index format, 0
    end

    test "index #{format} two channels" do
      index format, 2 do
        2.times {|i| QstServerChannel.make :account => @account, :application => @application }
      end
    end

    test "index #{format} should also include channels that don't belong to any application" do
      index format, 3 do
        2.times {|i| QstServerChannel.make :account => @account, :application => @application }
        QstServerChannel.make :account => @account
      end
    end

    test "show #{format} not found" do
      show 'hola', format, 0
    end

    test "show #{format} for application found" do
      show 'hola', format, 1 do
        QstServerChannel.make :account => @account, :application => @application, :name => 'hola'
      end
    end

    test "show #{format} for no application found" do
      show 'hola', format, 1 do
        QstServerChannel.make :account => @account, :name => 'hola'
      end
    end

    test "create #{format} channel succeeds" do
      chan = QstServerChannel.make_unsaved :qst_client, :enabled => false
      chan.restrictions['foo'] = ['a', 'b', 'c']
      chan.restrictions['bar'] = 'baz'

      create chan, format

      @account.reload
      result = @account.channels.last

      assert_not_nil result
      assert_equal @account.id, result.account_id
      assert_equal @application.id, result.application_id
      [:name, :kind, :protocol, :direction, :enabled, :priority, :restrictions].each do |sym|
        assert_equal chan.send(sym), result.send(sym), "#{sym} was not the same"
      end
      assert result.authenticate('secret')
    end

    test "create #{format} channel with at_rules and ao_rules succeeds" do
      chan = QstServerChannel.make_unsaved :qst_client, :enabled => false
      chan.ao_rules = [
        RulesEngine.rule([
          RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1')
        ],[
          RulesEngine.action('from','sms://2')
        ], true),
        RulesEngine.rule([
          RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://3')
        ],[
          RulesEngine.action('from','sms://4'),
          RulesEngine.action('body','lorem')
        ]),
        RulesEngine.rule([],[
          RulesEngine.action('subject','foo')
        ])
      ]

      chan.at_rules = [
        RulesEngine.rule([
          RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1'),
          RulesEngine.matching('body', RulesEngine::OP_EQUALS, 'ipsum')
        ],[
          RulesEngine.action('ca1','whitness')
        ])
      ]

      create chan, format

      @account.reload
      result = @account.channels.last

      assert_not_nil result
      assert_equal @account.id, result.account_id
      assert_equal @application.id, result.application_id
      [:name, :kind, :protocol, :direction, :enabled, :priority, :restrictions, :ao_rules, :at_rules].each do |sym|
        assert_equal chan.send(sym), result.send(sym), "#{sym} was not the same"
      end
    end

    test "create #{format} channel with using ticket succeeds and complete ticket" do
      ticket = Ticket.make :pending, :data => { :address => '8346-2355' }
      chan = QstServerChannel.make_unsaved :qst_server, :enabled => false, :ticket_code => ticket.code, :ticket_message => 'Phone plugged to app'

      create chan, format

      @account.reload
      result = @account.channels.last
      ticket.reload

      assert_not_nil result
      assert_equal @account.id, result.account_id
      assert_equal @application.id, result.application_id
      [:name, :kind, :protocol, :direction, :enabled, :priority, :restrictions].each do |sym|
        assert_equal chan.send(sym), result.send(sym), "#{sym} was not the same"
      end
      assert_nil result.ticket_code
      assert_equal '8346-2355', result.address

      assert_equal 'complete', ticket.status
      assert_equal @account.name, ticket.data[:account]
      assert_equal result.name, ticket.data[:channel]
      assert_equal chan.configuration[:password], ticket.data[:password]
      assert_equal 'Phone plugged to app', ticket.data[:message]
    end

    test "create #{format} channel fails missing name" do
      chan = QstServerChannel.make_unsaved :qst_server, :name => nil

      before_count = Channel.all.length
      create chan, format, :bad_request
      assert_equal before_count, Channel.all.length

      errors = (format == 'xml' ? Hash.from_xml(@response.body) : JSON.parse(@response.body)).with_indifferent_access
      if format == 'xml'
        assert_not_nil errors[:error][:summary]
        assert_equal "name", errors[:error][:property][:name]
        assert_not_nil errors[:error][:property][:value]
      else
        assert_not_nil errors[:summary]
        assert_equal "name", errors[:properties][0].keys[0]
        assert_not_nil errors[:properties][0].values[0]
      end
    end

    test "create #{format} channel fails missing password" do
      chan = QstServerChannel.make_unsaved :qst_server, :name => 'coco'
      chan.password = nil

      before_count = Channel.all.length
      create chan, format, :bad_request
      assert_equal before_count, Channel.all.length
    end

    test "create #{format} channel using invalid ticket fails" do
      chan = QstServerChannel.make_unsaved :qst_server, :ticket_code => 'wrong-ticket'

      before_count = Channel.all.length
      create chan, format, :bad_request
      assert_equal before_count, Channel.all.length

      errors = (format == 'xml' ? Hash.from_xml(@response.body) : JSON.parse(@response.body)).with_indifferent_access
      if format == 'xml'
        assert_not_nil errors[:error][:summary]
        assert_equal "ticket_code", errors[:error][:property][:name]
        assert_not_nil errors[:error][:property][:value]
      else
        assert_not_nil errors[:summary]
        assert_equal "ticket_code", errors[:properties][0].keys[0]
        assert_not_nil errors[:properties][0].values[0]
      end
    end

    test "update #{format} channel succeeds" do
      chan = QstServerChannel.make :account => @account, :application => @application, :priority => 20, :address => 'sms://1'
      update chan.name, Channel.new(:protocol => 'foobar', :priority => nil, :enabled => false, :address => 'sms://2'), format
      chan.reload

      assert_equal 'foobar', chan.protocol
      assert_equal 20, chan.priority
      assert_equal false, chan.enabled
      assert_equal 'sms://2', chan.address
    end

    test "update #{format} channel configuration succeeds" do
      chan = QstServerChannel.make :qst_client, :account => @account, :application => @application
      update chan.name, Channel.new(:configuration => {:url => 'x', :user => 'y', :password => 'z'}), format
      chan.reload

      assert_equal 'x', chan.configuration[:url]
      assert_equal 'y', chan.configuration[:user]
    end

    test "update #{format} channel restrictions succeeds" do
      chan = QstServerChannel.make :account => @account, :application => @application
      update chan.name, Channel.new(:restrictions => {'x' => 'z'}), format
      chan.reload

      assert_equal 'z', chan.restrictions['x']
    end

    test "update #{format} channel can override completely rules" do
      chan = QstServerChannel.make :qst_client, { :account => @account, :application => @application, :enabled => false,
          :ao_rules => [RulesEngine.rule([],[RulesEngine.action('from','sms://3')])],
          :at_rules => [RulesEngine.rule([],[RulesEngine.action('from','sms://6')])] }

      to_update = Channel.new(:enabled => true)
      to_update.ao_rules = [
        RulesEngine.rule([
          RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1')
        ],[
          RulesEngine.action('from','sms://2')
        ], true),
        RulesEngine.rule([
          RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://3')
        ],[
          RulesEngine.action('from','sms://4'),
          RulesEngine.action('body','lorem')
        ]),
        RulesEngine.rule([],[
          RulesEngine.action('subject','foo')
        ])
      ]

      to_update.at_rules = [
        RulesEngine.rule([
          RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1'),
          RulesEngine.matching('body', RulesEngine::OP_EQUALS, 'ipsum')
        ],[
          RulesEngine.action('ca1','whitness')
        ])
      ]

      update chan.name, to_update, format

      @account.reload
      result = @account.channels.last

      assert_not_nil result
      assert_equal @account.id, result.account_id
      assert_equal @application.id, result.application_id
      assert result.enabled
      assert_equal to_update.ao_rules, result.ao_rules
      assert_equal to_update.at_rules, result.at_rules
      [:name, :kind, :protocol, :direction, :priority, :restrictions].each do |sym|
        assert_equal chan.send(sym), result.send(sym), "#{sym} was not the same"
      end
    end

    #
    test "update #{format} channel avoid touching rules if not specified" do
      chan = QstServerChannel.make :qst_client, :account => @account, :application => @application, :enabled => false
      chan.ao_rules = [
        RulesEngine.rule([
          RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1')
        ],[
          RulesEngine.action('from','sms://2')
        ], true),
        RulesEngine.rule([
          RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://3')
        ],[
          RulesEngine.action('from','sms://4'),
          RulesEngine.action('body','lorem')
        ]),
        RulesEngine.rule([],[
          RulesEngine.action('subject','foo')
        ])
      ]

      chan.at_rules = [
        RulesEngine.rule([
          RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1'),
          RulesEngine.matching('body', RulesEngine::OP_EQUALS, 'ipsum')
        ],[
          RulesEngine.action('ca1','whitness')
        ])
      ]
      chan.save!

      update chan.name, Channel.new(:enabled => true), format

      @account.reload
      result = @account.channels.last

      assert_not_nil result
      assert_equal @account.id, result.account_id
      assert_equal @application.id, result.application_id
      assert result.enabled
      [:name, :kind, :protocol, :direction, :priority, :restrictions, :ao_rules, :at_rules].each do |sym|
        assert_equal chan.send(sym), result.send(sym), "#{sym} was not the same"
      end
    end
  end

  test "update channel fails no channel found" do
    authorize
    put :update, :format => 'xml', :name => "chan_lala"
    assert_response :not_found
  end

  test "update channel fails not owner" do
    chan = QstServerChannel.make :account => @account

    authorize
    put :update, :format => 'xml', :name => chan.name
    assert_response :forbidden
  end

  test "delete channel succeeds" do
    chan = QstServerChannel.make :account => @account, :application => @application

    authorize
    delete :destroy, :name => chan.name
    assert_response :ok

    assert_nil @account.channels.find_by_name chan.name
  end

  test "delete channel fails, no channel found" do
    authorize
    delete :destroy, :name => "chan_lala"
    assert_response :not_found
  end

  test "delete channel fails, does not own channel" do
    chan = QstServerChannel.make :account => @account

    authorize
    delete :destroy, :name => chan.name
    assert_response :forbidden
  end

  test "authenticate with application@account" do
    chan = QstServerChannel.make :account => @account, :application => @application

    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@application.name}@#{@account.name}", 'secret')
    delete :destroy, :name => chan.name
    assert_response :ok

    assert_nil @account.channels.find_by_name chan.name
  end

end
