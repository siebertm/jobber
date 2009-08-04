# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_jobber_session',
  :secret      => 'ba68c690d27eba806c2667d08b6f15b0a47d4338a994b4ef4da6e9e6bdcc2040daf289cfd38880861f1f224e538bca7e542e0b224951fab0b457ca6218b99ee3'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
