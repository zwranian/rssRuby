#!/usr/bin/ruby
require 'uri'
#require 'oauth'
require 'net/https'
require 'net/http'
require 'pp'
require 'json'
require 'rubygems'
require './accessToken_Pocket'

include AccessToken_Pocket
@consumer_key=CONSUMERKEY_POCKET
uri = URI.parse("https://getpocket.com/v3/oauth/request")
https = Net::HTTP.new(uri.host,uri.port)
https.use_ssl = true
https.ca_file = OpenSSL::X509::DEFAULT_CERT_FILE
p OpenSSL::X509::DEFAULT_CERT_FILE
https.verify_depth = 5
https.verify_mode = OpenSSL::SSL::VERIFY_PEER
https.start do |hs|
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json; charset=UTF-8"
    request["X-Accept"] = "application/json"
    request.body = {'consumer_key'=> @consumer_key, 'redirect_uri'=> "http://localhost"}.to_json
    hs.request(request) do |response|
        status = JSON.parse(response.body)
        code = status['code']
        puts "code: "+code
    end
end
