#---------------------------------------------------------------
#	GFDMmix for CS - Library for Skill Data View
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'cgi'
require 'erb'
require 'gfdmmix/util'
require 'gfdmmix/pagemaker'
require 'gfdmmix/skill_util'
require 'gfdmmix/user_database'
require 'gfdmmix/music_database'
require 'gfdmmix/skill_database'
require 'gfdmmix/skill_view'

module GfDmMix
	class SkillCompareMaker < PageMaker
		include SkillListUtil
		include SkillDataCellUtil

		def initialize(cgi, mobile=false)
			@cgi = cgi
			@mobile = mobile
			@template_html = 'template/skill_compare.html.erb'
		end

		def to_html
			user1 = UserDatabase.get((@cgi.path_info || '').split('/')[1])
			user2 = UserDatabase.get((@cgi.path_info || '').split('/')[2])

			html = read_template_html

			m_db = MusicDatabase.new
			musics = m_db.get_all_music
			m_db.close
			musics.sort!

			s_db = SkillDatabase.new(user1)
			skill_set1 = s_db.get_all_skill
			s_db.close

			s_db = SkillDatabase.new(user2)
			skill_set2 = s_db.get_all_skill
			s_db.close

			return ERB.new(html).result(binding).gsub(/[\t\r\n]/, '')
		end
	end
end
