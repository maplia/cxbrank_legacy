#---------------------------------------------------------------
#	GFDMmix for CS - Utility Library for Skill Data Page Making
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'gfdmmix/util'
require 'gfdmmix/skill_validate'

module GfDmMix
	module SkillUtil
		include SkillValidate

		# ユーザトップメニューのURIを取得する
		def get_menu_page_uri(user, edit=false)
			if edit
				return SKILL_MENU_EDIT_PROGRAM
			else
				return "#{SKILL_MENU_VIEW_PROGRAM}?uid=#{user.uid}"
			end
		end

		# スキル表のURIを取得する
		def get_list_page_uri(user, mode, rule, edit=false)
			if edit
				return "#{SKILL_LIST_EDIT_PROGRAM}?mode=#{mode};version=#{rule}"
			else
				return "#{SKILL_LIST_VIEW_PROGRAM}?uid=#{user.uid};mode=#{mode};version=#{rule}"
			end
		end

		# スキルポイントに応じてその表示色を表すクラスを取得する
		def get_skill_class(total_point, rule)
			case rule
			when VERSION_V1, VERSION_MPS;		rule_class = 'v1'
			when VERSION_V2, VERSION_MPG;		rule_class = 'v2'
			when VERSION_V3;								rule_class = 'v3'
			when AC_SKILL_RULE;							rule_class = 'v4'
			else;														raise 'must not happen'
			end

			case total_point
			when    0.00... 200.00;					point_class = 's0'		# 1000.00までは200刻み
			when  200.00... 400.00;					point_class = 's1'
			when  400.00... 600.00;					point_class = 's2'
			when  600.00... 800.00;					point_class = 's3'
			when  800.00...1000.00;					point_class = 's4'
			when 1000.00...1100.00;					point_class = 's5'		# 1000.00以降は100刻み
			when 1100.00...1200.00;					point_class = 's6'
			when 1200.00...1300.00;					point_class = 's7'
			when 1300.00...1400.00;					point_class = 's8'
			when 1400.00...1500.00;					point_class = 's9'
			when 1500.00...9999.99;					point_class = 'sa'		# 1600.00以上は今のところない
			else;														raise 'must not happen'
			end

			return "#{rule_class}_#{point_class}"
		end
	end

	module SkillListUtil
		include NavigateUtil
		include ListUtil
		include SkillUtil

		def get_tr_class(diff, row)
			return MUSIC_DIFF_CLASSES[diff] + (row%2 == 0 ? '_even' : '_odd')
		end

		def get_td_class(diff, row)
			return get_tr_class(diff, row)
		end

		module_function :get_tr_class, :get_td_class
	end

	module SkillEditUtil
		include EditUtil
		include SkillUtil
	end

	module SkillDataCellUtil
		include IconUtil
		include SkillUtil
		include DataCellUtil

		def make_point_sum_data_cell_html(point, total_point, rule, link_uri=nil)
			text = ''
			skill_class = get_skill_class(total_point, rule)

			text << "<a href=\"#{link_uri}\">" if link_uri
			text << "<span class=\"#{skill_class}\">#{sprintf_for_point(point)}</span>"
			text << "</a>" if link_uri

			return make_td_element(text)
		end

		def make_title_data_cell_html(music, mode, rule, stat, part, edit)
			title_text = ''

			if edit
				title_text << "<a href=\"#{SKILL_EDIT_PROGRAM}?"
				title_text << "mid=#{music.mid};mode=#{mode};version=#{rule}\">"
				title_text << music.title
				title_text << '</a>'
			else
				title_text << music.title
			end

			# クリアしている場合はパートによってパート名を表示
			case stat
			when SP_STATUS_BY_RATE, SP_STATUS_BY_JUDGE
				title_text << " #{make_part_icon_html(part)}"		# タイトルとの間にスペースを挟む
			end

			return make_text_data_cell_html(title_text)
		end

		def make_level_data_cell_html(level, diff=nil)
			text = ''

			# 譜面種別が与えられている場合は、アイコンも併せて表示する
			text << "#{make_diff_icon_html(diff)} " if diff
			text << sprintf_for_level(level)

			return make_td_element(text)
		end

		def make_point_data_cell_html(point)
			text = sprintf_for_point(point)

			if point == 0.0
				return make_mark_data_cell_html(text)
			else
				return make_td_element(text)
			end
		end

		def make_difference_data_cell_html(difference)
			if difference == 0.0
				return make_mark_data_cell_html('&ndash;')
			else
				if difference > 0.0
					cell_classes = ['inc']
				elsif difference < 0.0
					cell_classes = ['dec']
				end

				return make_td_element(sprintf("%+.2f", difference), cell_classes)
			end
		end

		def make_rate_data_cell_html(rate, stat, fcm=nil)
			text = sprintf_for_rate(rate, stat)

			case stat
			when SP_STATUS_FAILURE, SP_STATUS_NO_PLAY
				return make_mark_data_cell_html(text)
			else
				if rate == 100.0
					return make_mark_data_cell_html(text, ['max'])
				else
					return make_td_element(text)
				end
			end
		end

		def make_rank_data_cell_html(calculated_rank, rank, stat)
			if stat == SP_STATUS_BY_JUDGE and rank != SP_RANK_STATUS_NO
				# 判定値入力形式でランクが手動入力の場合は、その入力を優先して表示する
				return make_mark_data_cell_html(SP_RANK_STATUSES[rank], ['overwrote'])
			else
				return make_mark_data_cell_html(SP_RANK_STATUSES[calculated_rank])
			end
		end

		# スキルポイント用sprintf
		def sprintf_for_point(point)
			if point == 0.0
				return '&ndash;'
			else
				return sprintf("%.2f", point)
			end
		end
	end
end
