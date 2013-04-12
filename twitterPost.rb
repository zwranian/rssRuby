#!/usr/bin/ruby
require "twitter"
require "pp"
require "/home/pi/rss/access_token.rb"
include AccessToken
Twitter.configure do |config|
    config.consumer_key = CONSUMER_KEY
    config.consumer_secret = CONSUMER_SECRET
    config.oauth_token = ACCESS_TOKEN
    config.oauth_token_secret = ACCESS_TOKEN_SECRET
end
