#!/usr/bin/ruby
require 'uri'
require 'oauth'
require 'net/https'
require 'net/http'
require 'pp'
require 'json'
require 'rubygems'
require './accessToken_Pocket.rb'
include AccessToken_Pocket

@consumer_key=CONSUMERKEY_POCKET
@code = ""#別途スクリプトで取得したcodeを追記する.

uri = URI.parse("https://getpocket.com/v3/oauth/authorize")
https = Net::HTTP.new(uri.host,uri.port)
https.use_ssl = true
https.ca_file = "./cacert.pem"
https.verify_depth = 5
https.verify_mode = OpenSSL::SSL::VERIFY_PEER
https.start do |hs|
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json; charset=UTF-8"
    request["X-Accept"] = "application/json"
    request.body = {
        consumer_key: @consumer_key,
        code: @code}.to_json
    hs.request(request) do |response|
        puts response.body
        status = JSON.parse(response.body)
        access_token = status['access_token']
        puts "Access_token: "+access_token
    end
end
