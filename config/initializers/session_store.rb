# Be sure to restart your server when you modify this file.
DEV_SECRET = '1234567890123456789012345678901234567890'
SECRET = DEV_SECRET

if ENV['RAILS_ENV'] == 'production' && SECRET == DEV_SECRET
  raise 'Please, replace the secret key for something more secure!'
end

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_nuntium_session',
  :secret      => SECRET
}


# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
