#!/usr/bin/ruby
require 'net/https'
require 'pp'
require 'json'
require 'rubygems'
require 'mechanize'
require './accessToken_Pocket.rb'

class ALPocket
    include AccessToken_Pocket

    #API URI設定
    LOGIN_URI     = "https://getpocket.com/auth/authorize"
    REQUEST_URI   = "https://getpocket.com/v3/oauth/request"
    AUTHORIZE_URI = "https://getpocket.com/v3/oauth/authorize"
    ADD_URI       = "https://getpocket.com/v3/add"

    def initialize
        @consumer_key = CONSUMERKEY_POCKET
        @access_token = nil
        @redirect_uri = REDIRECT_URI
    end

    #PocketへItemを追加(title効いてない?)
    def post(url, title, tweetid)
        if !add(url, title, tweetid)
            #リクエストトークン取得
            request_token = getRequestToken

            #Webログイン(PocketID,Passwordを設定)
            login("ID","PASS",request_token)

            #アクセストークン取得
            getAccessToken(request_token)
            return add(url, title, tweetid)
        else
            return true
        end
    end

    #http post部分を共通化
    def httpRequest(apiUri, body)
        #HTTPインスタンスを生成
        uri = URI.parse(apiUri)
        https = Net::HTTP.new(uri.host,uri.port)
        
        #SSL関連設定
        https.use_ssl = true
        https.ca_file = OpenSSL::X509::DEFAULT_CERT_FILE
        https.verify_depth = 5
        https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        
        #POSTメソッドを投げる
        https.start do |hs|
            request = Net::HTTP::Post.new(uri.request_uri)
            request["Content-Type"] = "application/json; charset=UTF-8"
            request["X-Accept"] = "application/json"
            request.body = body
            #レスポンスを返す
            return hs.request(request)
        end
    end
    private:httpRequest

    
    def getRequestToken
        request_token = nil

        #パラメータ設定してAPIを叩く
        body = {'consumer_key'=> @consumer_key,
                'redirect_uri'=> @redirect_uri
               }.to_json
        response = httpRequest(REQUEST_URI, body)

        #取得エラーチェック
        case response
        when Net::HTTPOK
            begin
                request_token = JSON.parse(response.body)['code']
            rescue JSON::ParserError
            end
            return request_token
        else
            p "error getRequestToken:"+response.body.to_s
        end
    end
    private:getRequestToken
    
    def login(user,passwd,code)
        #インスタンス生成、IE偽装
        agent = Mechanize.new
        agent.user_agent_alias = 'Windows IE 9'
        agent.redirect_ok = 'true'
        agent.redirection_limit = 1

        #ログインページへアクセス
        uri = URI.parse(LOGIN_URI+"?request_token="+code+"&redirect_uri"+@redirect_uri)
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

        #チェック失敗してる
#        #ログインエラーチェック
#        if page.uri != @redirect_uri
#            p "error login: login failed."
#        end
    end
    private:login

    def getAccessToken(code)
        access_token = nil

        #パラメータ設定してAPIを叩く
        body = {'consumer_key'=> @consumer_key,
                'code'=> code
               }.to_json
        response = httpRequest(AUTHORIZE_URI, body)

        #取得エラーチェック
        case response
        when Net::HTTPOK
            begin
                access_token = JSON.parse(response.body)['access_token']
            rescue JSON::ParserError
            end
            @access_token = access_token
            return access_token
        else
            p "error getAccessToken:"+response.body.to_s
        end
    end
    private:getAccessToken

    def add(url, title, tweetid)
        #パラメータ設定してAPIを叩く
        body = {'url'=> url,
                'title'=> title,
                'tweet_id'=> tweetid,
                'consumer_key'=> @consumer_key,
                'access_token'=> @access_token
               }.to_json
        response = httpRequest(ADD_URI, body)

        #投稿エラーチェック
        case response
        when Net::HTTPOK
            return true
        else
            p "error post:"+response.body.to_s
            return false
        end
    end
    private:add
end




# テストコード #
pocket = ALPocket.new

#テストポスト
pocket.post("http://getpocket.com/","テスト",nil)
