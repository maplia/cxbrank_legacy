#!/usr/local/bin/ruby -Ku
#***************************************************************
#	GFDMmix for CS - Play Rank Calculator
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#***************************************************************
$LOAD_PATH << 'lib'

require 'cgi'
require 'util'
require 'gfdmmix/music_view'

begin
	cgi = CGI.new
	m_list = GfDmMix::PlayRankCalcMaker.new(cgi, sp_access?(cgi))

	print respond_to_http_request(cgi, m_list)
rescue
	print write_backtrace_for_cgi
end
