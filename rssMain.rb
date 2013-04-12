#!/usr/bin/ruby
require '/home/pi/rss/rssAnalyzer'
require 'rexml/document'
require 'tempfile'
require 'set'
include REXML
#初期処理
tmp = Tempfile::new("tmp","/home/pi/rss/")
rssAry = Array.new
hisSet = Set.new
sites = open("/home/pi/rss/rssResource")
history = open("/home/pi/rss/rssHistory","r+")
sites.each {|line|
    rssAry.push( RssAnalyze.new(line.chomp) )
}
sites.close
#履歴取得
history.each{|entry|
   hisSet.add(entry.chomp)    
}
history.close
    
#RSS取得を実行する
rssAry.each {|rss|
   rss.historys=hisSet
   rss.fetchRSS() 
   rss.postNewEntry()
}
#更新履歴を一次ファイルへ書き込む
rssAry.each{|rss|
    rss.ary.each{|entry|
        tmp.puts(entry.url)
    }
}
tmp.close
tmp.open
#次回のフィルタリングのため今回のエントリーを保存
open("/home/pi/rss/rssHistory","w"){|f|
    tmp.each{|line|
        f.puts(line)
    }
}
tmp.close
