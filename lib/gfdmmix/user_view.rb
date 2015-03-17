#---------------------------------------------------------------
#	GFDMmix for CS - Library for User Data Form
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'cgi'
require 'erb'
require 'util'
require 'gfdmmix/util'
require 'gfdmmix/pagemaker'
require 'gfdmmix/user_database'
require 'gfdmmix/skill_database'

module GfDmMix
	class UserListMaker < PageMaker
		def initialize(cgi, mobile)
			@cgi = cgi
			@mobile = mobile
			if mobile
				@template_html = 'template/mobile/user_list.html.erb'
			else
				@template_html = 'template/user_list.html.erb'
			end
		end

		def get_last_modified
			return Time.now
		end

		def to_html
			u_db = GfDmMix::UserDatabase.new
			users = u_db.get_all_user
			u_db.close

			users.sort!
			users.reverse!

			return ERB.new(read_template_html).result(binding)
		end
	end
end
