#!/usr/local/bin/ruby -Ku
#***************************************************************
#	GFDMmix for CS - Skill Data List
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#***************************************************************
$LOAD_PATH << 'lib'

require 'cgi'
require 'util'
require 'gfdmmix/skill_compare'

begin
	cgi = CGI.new

	unless cgi.path_info
		print cgi.header(
			{'Location' => 
				 "http://#{cgi.server_name}#{cgi.script_name.sub(/\.rb/, '')}/#{cgi['user1']}/#{cgi['user2']}"}
		)
		exit
	end

	s_list = GfDmMix::SkillCompareMaker.new(cgi, sp_access?(cgi))

	print respond_to_http_request(cgi, s_list)
rescue
	print write_backtrace_for_cgi
end
