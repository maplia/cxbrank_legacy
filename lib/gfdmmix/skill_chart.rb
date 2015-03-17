#---------------------------------------------------------------
#	GFDMmix for CS - Library for Skill Data View
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'cgi'
require 'erb'
require 'gfdmmix/util'
require 'gfdmmix/session'
require 'gfdmmix/pagemaker'
require 'gfdmmix/skill_util'
require 'gfdmmix/user_database'
require 'gfdmmix/music_database'
require 'gfdmmix/skill_database'
require 'gfdmmix/skill_view'

module GfDmMix
	class SkillChartMaker < PageMaker
		include SkillListUtil
		include SkillDataCellUtil

		def initialize(cgi, mobile=false)
			@cgi = cgi
			@mobile = mobile
			if mobile
				@template_html = 'template/mobile/skill_chart.html.erb'
			else
				@template_html = 'template/skill_chart.html.erb'
			end
		end

		def get_last_modified
			user = UserDatabase.get((@cgi.path_info || '').split('/')[1])
			s_db = SkillDatabase.new(user)
			mtime = s_db.mtime
			s_db.close

			return mtime
		end

		def to_html
			uid = (@cgi.path_info || '').split('/')[1]

			error_no = validate_uid_param(uid)
			if error_no != NO_ERROR
				return make_error_page(error_no)
			end
			user = UserDatabase.get(uid)

			html = read_template_html

			# 現在のスキル登録情報を取得する
			s_db = SkillDatabase.new(user)
			skill_set = s_db.get_all_skill
			s_db.close

			skills = skill_set.skills

			skills.each do |skill|
				def skill.to_html_for_chart(mobile, row)
					if mobile
						template = 'template/mobile/skill_chart_item.html.erb'
					else
						template = 'template/skill_chart_item.html.erb'
					end

					return ERB.new(File.read(template)).result(binding)
				end

				def skill.<=>(other)
					return @music.number <=> other.music.number
				end
			end

			skills.sort!

			cleared_stage_count = 0
			cleared_master_count = 0
			fullcombo_stage_count = 0
			ultimate_stage_count = 0
			srank_stage_count = 0
			cleared_max_level = 0
			fullcombo_max_level = 0
			ultimate_max_level = 0
			sprank_max_level = 0

			skills.each do |skill|
				MUSIC_DIFFS.keys.each do |diff|
					skill_score_item = skill.diff_skills[diff]
					stage_level = skill_score_item.music.level(diff)
					next unless skill_score_item

					if skill_score_item.cleared?
						# クリア譜面数
						cleared_stage_count += 1
						# クリア最高レベル
						cleared_max_level = stage_level if stage_level > cleared_max_level
						# MASTERクリア曲数
						if diff == MUSIC_DIFF_EXT
							cleared_master_count += 1
						end
						# ULTIMATEクリア譜面数
						if skill_score_item.ultimate?
							ultimate_stage_count += 1
							# ULTIMATEクリア最高レベル
							ultimate_max_level = stage_level if stage_level > ultimate_max_level
						end
						# フルコンボ譜面数
						if skill_score_item.fullcombo?
							fullcombo_stage_count += 1
							# フルコンボ最高レベル
							fullcombo_max_level = stage_level if stage_level > fullcombo_max_level
						end
						# Sランク取得譜面数
						if [SP_RANK_STATUS_SPP, SP_RANK_STATUS_SP, SP_RANK_STATUS_S].include?(skill_score_item.rank)
							srank_stage_count += 1
							# S+ランク取得最高レベル
							if skill_score_item.rank != SP_RANK_STATUS_S
								sprank_max_level = stage_level if stage_level > sprank_max_level
							end
						end
					end
				end
			end

			html.gsub!(/<!--PRESET_USER_ID-->/, user.uid)
			html.gsub!(/<!--PRESET_USER_NAME-->/, user.name)

			html.gsub!(/<!--PRESET_USER_COMMENT-->/, user.to_html(@cgi, false))

			return ERB.new(html).result(binding).gsub(/[\t\r\n]/, '')
		end
	end
end
