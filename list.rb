#!/usr/local/bin/ruby -Ku
#***************************************************************
#	GFDMmix for CS - Skill Data List for Edit
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#***************************************************************
$LOAD_PATH << 'lib'

require 'cgi'
require 'util'
require 'gfdmmix/session'
require 'gfdmmix/skill_view'

begin
	cgi = CGI.new
	session = GfDmMix::UserSession.new(cgi)

	# セッションが生きていなければ、エラーを出して終了
	unless session.alive?
		print respond_to_http_request(cgi, GfDmMix::UserSessionExecutor.new(cgi, session))
		exit
	end

	s_list = GfDmMix::SkillListMaker.new(cgi, sp_access?(cgi), session)

	print respond_to_http_request(cgi, s_list)
rescue
	print write_backtrace_for_cgi
end
