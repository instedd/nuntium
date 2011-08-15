# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

# ci_reporter
gem 'ci_reporter'
require 'ci/reporter/rake/test_unit' # use this if you're using Test::Unit
require 'ci/reporter/rake/cucumber'  # use this if you're using Cucumber

Nuntium::Application.load_tasks
