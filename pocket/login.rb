#!/usr/bin/ruby
require 'net/https'
require 'pp'
require 'rubygems'
require 'mechanize'

@code = ""
@redirect_uri = "http://localhost"

@user = ""
@pass = ""

uri = URI.parse("https://getpocket.com/auth/authorize?request_token="+@code+"&redirect_uri"+@redirect_uri)

agent = Mechanize.new
agent.user_agent_alias = 'Windows IE 9'

page = agent.get(uri)

form = page.forms.first

form.field_with(:name => 'feed_id').value = @user
form.field_with(:name => 'password').value = @pass

form.click_button
