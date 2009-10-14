# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_nuntium_session',
  :secret      => 'ff43bdb4376ad74c82d27a321bbb01eb32f55886e6f68a5b357a3a89a562bd22a6ea64181304980404ad54d238ae72215fa60887723c14c0d87a2ba2c0102849'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
