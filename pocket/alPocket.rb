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
        @access_token = nil
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
                end
            end
        end
        
        #取得エラーチェック
        case response
        when Net::HTTPOK
            return request_token
        else
            p "error getRequestToken:"+response.body.to_s
        end
    end

    def login(user,passwd,code)
        #インスタンス生成、IE偽装
        agent = Mechanize.new
        agent.user_agent_alias = 'Windows IE 9'
        agent.redirect_ok = 'true'
        agent.redirection_limit = 1

        #ログインページへアクセス
        uri = URI.parse("https://getpocket.com/auth/authorize?request_token="+code+"&redirect_uri"+@redirect_uri)
        page = agent.get(uri)

        #ログインフォーム取得
        form = page.forms.first

        #ユーザーID,パスワード入力
        form.field_with(:name => 'feed_id').value = user
        form.field_with(:name => 'password').value = passwd

        #formをsubmit
        begin
            page = form.click_button
        rescue Mechanize::RedirectLimitReachedError
        end
        
        #ログインエラーチェック
        if page.uri != @redirect_uri
            p "erro login: "
        end
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
                end
            end
        end
        
        #取得エラーチェック
        case response
        when Net::HTTPOK
            @access_token = access_token
            return access_token
        else
            p "error getAccessToken:"+response.body.to_s
        end
    end
    
    def post(url, title, tweetid)
        uri = URI.parse("https://getpocket.com/v3/add")
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        https.ca_file = OpenSSL::X509::DEFAULT_CERT_FILE
        https.verify_depth = 5
        https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        response = https.start do |hs|
            request = Net::HTTP::Post.new(uri.request_uri)
            request["Content-Type"] = "application/json; charset=UTF-8"
            request["X-Accept"] = "application/json"
            request.body = {'url'=> url, 'title'=> title, 'tweet_id'=> tweetid,
               'consumer_key'=> @consumer_key,
               'access_token'=> @access_token
                }.to_json
            hs.request(request)
        end
        
        #投稿エラーチェック
        case response
        when Net::HTTPClientError
            p "error post:"+response.body.to_s
        end
    end
end


# テストコード #
pocket = ALPocket.new

#テストポスト(エラー)
pocket.post("http://google.com","テストグーグル",nil)

#リクエストトークン取得&表示
req_tkn = pocket.getRequestToken
p "main requestToken: "+req_tkn.to_s

#Webログイン(PocketID,Passwordを設定)
pocket.login("ID","PASS",req_tkn)

#アクセストークン取得&表示
acs_tkn = pocket.getAccessToken(req_tkn)
p "main accessToken: "+acs_tkn.to_s

#テストポスト
pocket.post("http://google.com","テストグーグル",nil)
