#!/usr/bin/ruby
require 'net/https'
require 'pp'
require 'json'
require 'rubygems'
require 'mechanize'
require './accessToken_Pocket.rb'

class ALPocket
    include AccessToken_Pocket

    def initialize
        @consumer_key = CONSUMERKEY_POCKET
        @redirect_uri = REDIRECT_URI
    end

#    private:getRequestToken
#    private:login
#    private:getAccessToken

    def getRequestToken
        uri = URI.parse("https://getpocket.com/v3/oauth/request")
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        https.ca_file = OpenSSL::X509::DEFAULT_CERT_FILE
        https.verify_depth = 5
        https.verify_mode = OpenSSL::SSL::VERIFY_PEER

        request_token=nil

        response = https.start do |hs|
            request = Net::HTTP::Post.new(uri.request_uri)
            request["Content-Type"] = "application/json; charset=UTF-8"
            request["X-Accept"] = "application/json"
            request.body = {'consumer_key'=> @consumer_key, 'redirect_uri'=> @redirect_uri}.to_json
            hs.request(request) do |response|
                begin
                    status = JSON.parse(response.body)
                    request_token =  status['code']
                rescue JSON::ParserError
                    p "error getRequestToken:"+response.body.to_s
                end
            end
        end
        if response=Net::HTTPOK
            return request_token
        end
    end

    def login(user,passwd,code)
        #インスタンス生成、IE偽装
        agent = Mechanize.new
        agent.user_agent_alias = 'Windows IE 9'

        #ログインページへアクセス
        uri = URI.parse("https://getpocket.com/auth/authorize?request_token="+code+"&redirect_uri"+@redirect_uri)
        page = agent.get(uri)

        #ログインフォーム取得
        form = page.forms.first

        #ユーザーID,パスワード入力
        form.field_with(:name => 'feed_id').value = user
        form.field_with(:name => 'password').value = passwd

        #formをsubmit
        form.click_button
    end

    def getAccessToken(code)
        uri = URI.parse("https://getpocket.com/v3/oauth/authorize")
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        https.ca_file = OpenSSL::X509::DEFAULT_CERT_FILE
        https.verify_depth = 5
        https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        
        access_token=nil
        
        response = https.start do |hs|
            request = Net::HTTP::Post.new(uri.request_uri)
            request["Content-Type"] = "application/json; charset=UTF-8"
            request["X-Accept"] = "application/json"
            request.body = {'consumer_key'=> @consumer_key, 'code'=> code}.to_json
            hs.request(request) do |response|
                begin
                    status = JSON.parse(response.body)
                    access_token = status['access_token']
                rescue JSON::ParserError
                    p "error getAccessToken:"+response.body.to_s
                end
            end
        end
        if response=Net::HTTPOK
            return access_token
        end
    end
end


pocket = ALPocket.new

#リクエストトークン取得&表示
req_tkn = pocket.getRequestToken
p req_tkn

#Webログイン(PocketID,Passwordを設定)
pocket.login("ID","PASS",req_tkn)

#アクセストークン取得&表示
acs_tkn = pocket.getAccessToken(req_tkn)
p acs_tkn
