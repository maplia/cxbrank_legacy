#!/usr/local/bin/ruby -Ku
#***************************************************************
#	GFDMmix for CS - Site Top
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#***************************************************************
$LOAD_PATH << 'lib'

require 'cgi'
require 'util'
require 'gfdmmix/const'
require 'gfdmmix/user_database'
require 'gfdmmix/skill_database'

begin
	text = ''

	u_db = GfDmMix::UserDatabase.new
	users = u_db.get_all_user
	u_db.close

	users.each do |user|
		s_db = GfDmMix::SkillDatabase.new(user)
		skill_set = s_db.get_all_skill
		skill_mtime = s_db.mtime
		s_db.close

		u_db = GfDmMix::UserDatabase.new
		u_db.save_skill_point(user, skill_set.skill_point, skill_mtime)
		u_db.close

		text += "User ID: #{user.uid}, RP: #{skill_set.skill_point}, Last Modified: #{skill_mtime}\n"
	end

	print "Content-Type: text/plain\n\n"
	print text
rescue
	print write_backtrace_for_cgi
end
