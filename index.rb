#!/usr/local/bin/ruby -Ku
#***************************************************************
#	GFDMmix for CS - Site Top
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#***************************************************************
$LOAD_PATH << 'lib'

require 'cgi'
require 'util'
require 'gfdmmix/menu_view'

begin
	cgi = CGI.new
	s_top = GfDmMix::SiteTopMaker.new(cgi, sp_access?(cgi))

	print respond_to_http_request(cgi, s_top)
rescue
	print write_backtrace_for_cgi
end
