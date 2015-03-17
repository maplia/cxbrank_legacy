#!/usr/local/bin/ruby -Ku
#***************************************************************
#	GFDMmix for CS - Music Data List
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#***************************************************************
$LOAD_PATH << 'lib'

require 'cgi'
require 'util'
require 'gfdmmix/user_view'

begin
	cgi = CGI.new
	u_list = GfDmMix::UserListMaker.new(cgi, sp_access?(cgi))

	print respond_to_http_request(cgi, u_list)
rescue
	print write_backtrace_for_cgi
end
