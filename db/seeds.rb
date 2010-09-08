# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

# Create the worker queue for cron tasks
WorkerQueue.create!(:queue_name => 'cron_tasks_queue', :working_group => 'slow', :ack => false, :durable => false)

load "#{RAILS_ROOT}/db/seeds-countries.rb"
load "#{RAILS_ROOT}/db/seeds-carriers.rb"