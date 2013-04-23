#!/usr/bin/ruby
###RSSを表すクラス
class RssAnalyze
    require 'net/http'
    require '/home/pi/rss/twitterPost'
    require 'uri'
    require 'rss'
    require 'set'
    require 'rexml/document'
    include REXML
    attr_accessor:source,:ary,:historys
    ##メソッド宣言
    #実行したらまだ取得してない記事のURLとタイトルを配列かリストで返すメソッド
    def initialize(sourceUrl)
        @source=sourceUrl
        @ary=Array.new
        @historys=Set.new
    end
    #rssResourceから登録フィードを取得するメソッド
    def fetchRSS
        puts "fetch "+@source
        url = URI.parse(@source)
        req = Net::HTTP::Get.new(url.request_uri)
        res = Net::HTTP.start(url.host,url.port) {|http|
            http.request(req)
        }
        doc = REXML::Document.new(res.body)
        type = doc.root.attributes["xmlns"]
        #RSSのフォーマットがいくつかあるので対応
        #一つ目
        if type == "http://www.w3.org/2005/Atom" then
            doc.elements.each("feed/entry"){|item|
                title = item.elements["title"].text
                link = item.elements["link"].attributes["href"]
                c = Content.new(link,title,"",item.elements["updated"].text)
            @ary.push c
            }
        #二つ目
        elsif type == "http://purl.org/rss/1.0/" 
            rss = RSS::Parser.parse(@source)
            rss.items.each do |item|
                title = item.title
                link = item.about
                c = Content.new(link,title,"",item.date.to_s)
            @ary.push c
            end
        #三つ目
        else   
            doc.elements.each("rss/channel/item"){|item|
                title = item.elements["title"].text
                link = item.elements["link"].text
                c = Content.new(link,title,"",item.elements["pubDate"].text)
            @ary.push c
            }
        end
    end
    
    #取得したXMLを解析して、以前取得した記事以降のデータを返す
    def postNewEntry
         @ary.each{|a|
            begin
            #新着を見極めるために取得済みのエントリをフィルタリングする
                if @historys.include?(a.url) then
                    next
                else 
                    #ツイート
                    #puts "Post: "+a.url
                    Twitter.update(a.title+"- "+a.url)
                 end
            rescue Twitter::Error::Forbidden => ex
                    @ary.delete(a)
            rescue => ex
                    @ary.delete(a)
        end
         }
        end
    end

##ポスト内容を表すクラス
class Content
    attr_reader :url, :title, :homeTitle, :date
    def initialize(url,title,homeTitle,date)
        @url = url
        @title =title
        @homeTitle = homeTitle
        @date = date
    end
end
