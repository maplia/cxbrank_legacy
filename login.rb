#!/usr/local/bin/ruby -Ku
#***************************************************************
#	GFDMmix for CS - Login
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#***************************************************************
$LOAD_PATH << 'lib'

require 'cgi'
require 'util'
require 'gfdmmix/menu_view'
require 'gfdmmix/authenticate'

begin
	cgi = CGI.new

	case cgi.request_method.downcase
	when 'get'						# ログインフォーム立ち上げ
		u_menu = GfDmMix::SiteTopMakerForLogin.new(cgi)
	when 'post'						# ログイン検証
		u_menu = GfDmMix::UserAuthenticator.new(cgi)
	end

	print respond_to_http_request(cgi, u_menu)
rescue
	print write_backtrace_for_cgi
end
