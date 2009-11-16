# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

require 'digest/sha2'

app = Application.create({ :name => 'riff', :password => 'riffpass' })
chan = Channel.new(:name => 'sms', :kind => 'qst', :protocol => 'sms', :direction => Channel::Both, :application_id => app.id)
chan.configuration = { :password => 'smspass' }
chan.save