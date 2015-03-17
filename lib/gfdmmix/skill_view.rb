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
require 'gfdmmix/skill_validate'

module GfDmMix
	class SkillListMaker < PageMaker
		include SkillListUtil
		include SkillDataCellUtil

		def initialize(cgi, mobile=false, session=nil)
			@cgi = cgi
			@mobile = mobile
			@session = session
			@edit = (not session.nil?)
			if mobile
				@template_html = 'template/mobile/skill_list.html.erb'
			else
				@template_html = 'template/skill_list.html.erb'
			end
		end

		def get_last_modified
			if @session
				s_db = SkillDatabase.new(@session.get_user)
				mtime = s_db.mtime
				s_db.close
			else
				user = UserDatabase.get((@cgi.path_info || '').split('/')[1])
				s_db = SkillDatabase.new(user)
				mtime = s_db.mtime
				s_db.close
			end

			return Time.now
		end

		def to_html
			# 表示の対象となるユーザの登録情報を取得する
			if @session
				user = @session.get_user
			else
				uid = (@cgi.path_info || '').split('/')[1]

				error_no = validate_uid_param(uid)
				if error_no != NO_ERROR
					return make_error_page(error_no)
				end
				user = UserDatabase.get(uid)
			end

			html = read_template_html

			# 現在のスキル登録情報を取得する
			s_db = SkillDatabase.new(user)
			skill_set = s_db.get_all_skill
			s_db.close

			skill_items_hash = skill_set.skill_hash
			skill_point_hash = skill_set.skill_point_hash

			html.gsub!(/<!--PRESET_USER_ID-->/, user.uid)
			html.gsub!(/<!--PRESET_USER_NAME-->/, user.name)

			html.gsub!(/<!--PRESET_USER_COMMENT-->/, user.to_html(@cgi, @edit))

			return ERB.new(html).result(binding).gsub(/[\t\r\n]/, '')
		end
	end

	class SkillIgLockListMaker < SkillListMaker
		def initialize(cgi, mobile=false)
			@cgi = cgi
			@mobile = mobile
			if mobile
				@template_html = 'template/mobile/skill_list.html.erb'
			else
				@template_html = 'template/skill_list.html.erb'
			end
		end

		def to_html
			# 表示の対象となるユーザの登録情報を取得する
			if @session
				user = @session.get_user
			else
				uid = (@cgi.path_info || '').split('/')[1]

				error_no = validate_uid_param(uid)
				if error_no != NO_ERROR
					return make_error_page(error_no)
				end
				user = UserDatabase.get(uid)
			end

			html = read_template_html

			# 現在のスキル登録情報を取得する
			s_db = SkillDatabase.new(user)
			skill_set = s_db.get_all_skill(true)
			s_db.close

			skill_items_hash = skill_set.skill_hash
			skill_point_hash = skill_set.skill_point_hash

			html.gsub!(/<!--PRESET_USER_ID-->/, user.uid)
			html.gsub!(/<!--PRESET_USER_NAME-->/, user.name)

			html.gsub!(/<!--PRESET_USER_COMMENT-->/, user.to_html(@cgi, @edit))

			return ERB.new(html).result(binding).gsub(/[\t\r\n]/, '')
		end
	end

	class SkillRankListMaker < PageMaker
		include SkillListUtil
		include SkillDataCellUtil
		include SkillValidate

		def initialize(cgi, mobile=false)
			@cgi = cgi
			@mobile = mobile
		end

		def get_last_modified
			return Time.now
		end

		def to_html
			html = ''
			text_id = (@cgi.path_info || '').split('/')[1]

			if text_id
				error_no = validate_params_for_skill_form(text_id)
				if error_no != NO_ERROR
					return make_error_page(error_no)
				end

				if @mobile
					@template_html = 'template/skill_rank_list.html.erb'
				else
					@template_html = 'template/skill_rank_list.html.erb'
				end
				html = read_template_html

				m_db = MusicDatabase.new
				music = m_db.get(text_id)
				m_db.close

				s_db = SkillDatabase.new(nil)
				skills = s_db.get_all_user_skill(music)
				s_db.close

				skills.sort! do |a, b|
					if a.max_skill.point == b.max_skill.point
						a.max_skill.fcs <=> b.max_skill.fcs
					else
						a.max_skill.point <=> b.max_skill.point
					end
				end
				skills.reverse!

				html = ERB.new(html).result(binding).gsub(/[\t\r\n]/, '')
			else
				if @mobile
					@template_html = 'template/skill_music_list.html.erb'
				else
					@template_html = 'template/skill_music_list.html.erb'
				end
				html = read_template_html

				m_db = MusicDatabase.new
				musics = m_db.get_all_music
				m_db.close

				musics.sort! do |a, b| a.number <=> b.number end

				html = ERB.new(html).result(binding).gsub(/[\t\r\n]/, '')
			end

			return html
		end
	end

	class UserItem
		include DataCellUtil

		# skill_view.rb用のメソッド上書き
		def to_html(cgi, edit)
			html = ''

			html << '<div class="unit">'
			html << '<div class="subunit">'
			html << '<table>'
			html << '<tbody>'
 			html << "<tr><th>ユーザー名</th>#{make_text_data_cell_html(@name)}</tr>"
			if edit
				# 公開用URI表示は編集モード（ユーザログイン時）のみとする
				menu_uri = "#{SKILL_LIST_VIEW_PROGRAM}/#{@uid}"
				full_uri = "#{get_request_path(cgi)}#{menu_uri}"

	 			html << '<tr>'
	 			html << '<th>RP表公開URL</th>'
				html << "<td class=\"text\"><a href=\"/#{menu_uri}\">#{full_uri}</a>"
				html << '<br />'

				menu_uri = "#{SKILL_LIST_VIEW_IGLOCK_PROGRAM}/#{@uid}"
				full_uri = "#{get_request_path(cgi)}#{menu_uri}"

				html << "<a href=\"/#{menu_uri}\">#{full_uri}</a>"
				html << '（未取得/ロックフラグ無視版）</td>'
	 			html << '</tr>'

				menu_uri = "#{CLEAR_LIST_VIEW_PROGRAM}/#{@uid}"
				full_uri = "#{get_request_path(cgi)}#{menu_uri}"

	 			html << '<tr>'
	 			html << '<th>クリア表公開URL</th>'
	 			html << make_text_data_cell_html("<a href=\"/#{menu_uri}\">#{full_uri}</a>")
	 			html << '</tr>'
			end
			unless (@cxbid || '').empty?
				html << '<tr>'
				html << '<th>C&times;B ID</th>'
				html << make_text_data_cell_html(@cxbid)
				html << '</tr>'
			end
			unless (@comment || '').empty?
				escaped_comment = textarea_data_to_html(CGI.escapeHTML(@comment), true)

				html << '<tr>'
				html << '<th>コメント</th>'
				html << make_text_data_cell_html(escaped_comment)
				html << '</tr>'
			end
			html << '</tbody>'
			html << '</table>'
			if edit
				html << '<a href="/user_edit">ユーザー情報編集</a>'
			else
				html << "<a href=\"/view/#{@uid}\">通常RP表</a> / "
				html << "<a href=\"/iglock/#{@uid}\">ロック状態無視RP表</a>"
			end
			html << '</div>'
			html << '</div>'

			return html
		end
	end
end
