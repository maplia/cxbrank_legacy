#!/usr/local/bin/ruby -Ku
#***************************************************************
#	GFDMmix for CS - Skill Rank Data List
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#***************************************************************
$LOAD_PATH << 'lib'

require 'cgi'
require 'util'
require 'gfdmmix/skill_view'

begin
	cgi = CGI.new
	s_list = GfDmMix::SkillRankListMaker.new(cgi, sp_access?(cgi))

	print respond_to_http_request(cgi, s_list)
rescue
	print write_backtrace_for_cgi
end
