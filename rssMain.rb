#!/usr/bin/ruby
require '/home/pi/rss/rssAnalyzer'
require 'rexml/document'
require 'set'
include REXML
#初期処理
rssAry = Array.new
hisSet = Set.new
postAry = Array.new
sites = open("/home/pi/rss/rssResource")
history = open("/home/pi/rss/rssHistory","r+")
sites.each {|line|
    rssAry.push( RssAnalyze.new(line.chomp) )
}
sites.close
#履歴取得
count=0
history.each{|entry|
   hisSet.add(entry.chomp)    
   count = count + 1
}
history.close

#RSS取得を実行する
rssAry.each {|rss|
   rss.historys=hisSet
   rss.fetchRSS() 
   postAry.concat( rss.postNewEntry() )
}
#RSSの履歴を保存
if count > 500 then
    #現状の最新RSSで履歴を上書き
    #puts "rssHistory reset"
    open("/home/pi/rss/rssHistory","w"){|f|
        rssAry.each{|rss|
            rss.ary.each{|entry|
                f.puts(entry.url)
            }
        }
    }
end
#次回のフィルタリングのため今回のエントリーを追記
open("/home/pi/rss/rssHistory","a"){|f|
    #puts "Add entry to rssHistory"
    postAry.each{|url|
        f.puts(url)
        #puts "ADD: "+url
    }
}
