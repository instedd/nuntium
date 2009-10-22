# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

require 'digest/sha2'

app_salt = ActiveSupport::SecureRandom.base64(8)
app_pass = 'riffpass'
app = Application.create({ :name => 'riff', :salt => app_salt, :password => app_pass })

chan_salt = ActiveSupport::SecureRandom.base64(8)
chan_pass = 'smspass'
Channel.create(:name => 'sms', :kind => 'qst', :configuration => { :salt => chan_salt, :password => chan_pass }, :application_id => app.id)