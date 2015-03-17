#---------------------------------------------------------------
#	GFDMmix for CS - Library for Skill Data Form
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'cgi'
require 'erb'
require 'util'
require 'gfdmmix/util'
require 'gfdmmix/pagemaker'
require 'gfdmmix/music_database'
require 'gfdmmix/skill_util'
require 'gfdmmix/skill_database'
require 'gfdmmix/skill_validate'

module GfDmMix
	class SkillEditFormMaker < PageMaker
		include SkillValidate

		# スキルを編集する曲の指定はCGIのパラメータからもらう
		def initialize(cgi, mobile, session)
			@cgi = cgi
			@session = session
			@mobile = mobile
			if mobile
				@template_html = 'template/mobile/skill_edit.html.erb'
			else
				@template_html = 'template/skill_edit.html.erb'
			end
		end

		def to_html
			text_id = (@cgi.path_info || '').split('/')[1]
			user = @session.get_user

			if text_id
				error_no = validate_params_for_skill_form(text_id)
				if error_no != NO_ERROR
					return make_error_page(error_no)
				end
			end

			html = read_template_html

			# 曲情報の取得
			if @session['music']
				# 前のセッションから入力値を引き継いでいる場合はそれを初期表示とする
				# ↑登録確認画面で「いいえ」が選択された場合
				music = @session['music']
			else
				m_db = MusicDatabase.new
				music = m_db.get(text_id)
				m_db.close

				# 取得した曲の情報をセッション領域に記録しておく
				@session['music'] = music
			end

			# スキル情報の取得
			if @session['skill']
				# 前のセッションから入力値を引き継いでいる場合はそれを初期表示とする
				# ↑登録確認画面で「いいえ」が選択された場合
				skill = @session['skill']
			else
				s_db = SkillDatabase.new(user)
				skill = s_db.get(music)
				s_db.close
				# 見つからない場合は全パートプレイなしのデータで代替する
				unless skill
					skill = SkillItem.make_empty_item(user, music)
				end

				# 取得したスキル情報を旧情報としてセッション領域に記憶させておく
				@session['old_skill'] = skill
			end

			# 画面にあったモードや曲の情報を表示に反映させる
			html.gsub!(/<!--PRESET_MUSIC_TITLE-->/, music.title)
			html.gsub!(/<!--PRESET_SKILL_LIST_URI-->/, SKILL_LIST_EDIT_PROGRAM)
			html.gsub!(/<!--PRESET_SKILL_EDIT_URI-->/, SKILL_ITEM_EDIT_PROGRAM)

			# 編集リスト画面からもらったクエリはそのまま保持させておく
			html.gsub!(/<!--PRESET_MUSIC_ID-->/, music.mid.to_s)

			# 現在の登録スキル情報を表示
			html.gsub!(/<!--PRESET_LAST_SKILL-->/, @session['old_skill'].to_html_for_exist)
			html.gsub!(/<!--PRESET_SKILL_EDIT_FORM-->/, skill.to_html(@mobile))
			# スキル情報が登録されていない場合は削除ボタンをつぶしておく
			if @session['old_skill'].empty?
				html.gsub!(/<!--PRESET_DELETE_ACTIVATE-->/, 'disabled')
			else
				html.gsub!(/<!--PRESET_DELETE_ACTIVATE-->/, '')
			end

			return ERB.new(html).result(binding)
		end
	end

	class SkillRegister
		def initialize(cgi, mobile, session)
			@cgi = cgi
			@mobile = mobile
			@session = session
		end

		def execute
			music = @session['music']
			mid = music.mid

			if @cgi['y'].size > 0				# 「はい」が選択されたので確定
				s_db = SkillDatabase.new(@session.get_user)
				case @cgi['ctrl']
				when 'reg'
					s_db.edit(music, @session['skill'])
				when 'del'
					s_db.delete(music)
				end
				s_db.close
			elsif @cgi['n'].size > 0		# 「いいえ」が選択されたらやり直し
				;		# 何もしない
			else
				# ここで入力チェックを起動
				# エラーがある場合は@error_noに出たエラーの情報を残す
				# 入力情報をセッション情報に入れるため、エラーチェックでこけてもこの関数は最後まで実行
				@error_no = check(@cgi)

				skill_items_hash = Hash.new
				MUSIC_DIFFS_ORDER.each do |diff|
					name_init = MUSIC_DIFF_CLASSES[diff]
					skill_item = SkillScoreItem.new(music, diff,
						@cgi["#{name_init}_stat"], @cgi["#{name_init}_locked"].to_i,
						@cgi["#{name_init}_point"].to_f, @cgi["#{name_init}_rate"].to_f,
						@cgi["#{name_init}_rank"], @cgi["#{name_init}_fcs"],
						@cgi["#{name_init}_ultimate"].to_i)
					skill_items_hash[diff] = skill_item
				end

				skill = SkillItem.new(@session.get_user, nil, music,
					skill_items_hash[MUSIC_DIFF_BSC], skill_items_hash[MUSIC_DIFF_ADV],
					skill_items_hash[MUSIC_DIFF_EXT], CGI.unescapeHTML(@cgi['comment']))

				# フォームから入力された値を基にしたスキルデータをセッション領域に記憶
				@session['skill'] = skill
			end
		end

		def to_html
			html = ''
			music = @session['music']
			skill = @session['skill']
			old_skill = @session['old_skill']
			user = @session.get_user

			# execute関数でエラーが発生している場合はエラー内容だけ表示して先に進ませない
			if not @error_no.nil?
				back_uri = "/#{SKILL_EDIT_PROGRAM}/#{music.text_id}"

				return GfDmMix::make_error_page(@error_no, back_uri)
			end

			if @cgi['y'].size != 0				# 一覧ページへのリンクおよび自動移動を行う
				list_uri = "list"

				# 作業終了につき、スキルに関するセッション情報は破棄する
				@session['music'] = nil
				@session['skill'] = nil
				@session['old_skill'] = nil

				# Locationヘッダを出力して、ここでプログラムを終わらせる
				print @cgi.header({'Location' => list_uri})
				exit
			elsif @cgi['n'].size != 0			# 入力されていた内容で前のページからやり直し
				s_edit = SkillEditFormMaker.new(@cgi, @mobile, @session)
				html << s_edit.to_html
			else													# ただの確認画面表示
				if @mobile
					html << GfDmMix::read_temp_html('template/mobile/skill_edit_conf.html.erb')
				else
					html << GfDmMix::read_temp_html('template/skill_edit_conf.html.erb')
				end
				html.gsub!(/<!--PRESET_CTRL_NAME-->/, get_ctrl_name(@cgi))
				html.gsub!(/<!--PRESET_CTRL_TYPE-->/, get_ctrl_type(@cgi))

				# formのaction属性にプログラム名を設定する
				html.gsub!(/<!--PRESET_SKILL_EDIT_PROGRAM-->/, SKILL_ITEM_EDIT_PROGRAM)

				# 画面にあったモードや曲の情報を表示に反映させる
				html.gsub!(/<!--PRESET_USER_ID-->/, user.uid)
				html.gsub!(/<!--PRESET_USER_NAME-->/, user.name)
				html.gsub!(/<!--PRESET_MUSIC_TITLE-->/, music.title)
				html.gsub!(/<!--PRESET_SKILL_LIST_URI-->/, SKILL_LIST_EDIT_PROGRAM)

				# 編集リスト画面からもらったクエリは引き続きそのまま保持させておく
				html.gsub!(/<!--PRESET_MUSIC_ID-->/, music.mid.to_s)

				case get_ctrl_type(@cgi)
				when 'reg'
					html.gsub!(/<!--PRESET_SKILL_DATA-->/, skill.to_html_for_confirm(old_skill))
				else
					html.gsub!(/<!--PRESET_SKILL_DATA-->/, skill.to_html_for_confirm)
				end
			end

			return ERB.new(html).result(binding)
		end

		private
		def check(cgi)
			# パート+譜面の組み合わせごとのエラーを定義する
			rate_not_exist = {
				'g_bsc' => ERROR_G_BSC_RATE_NOT_EXIST, 'g_adv' => ERROR_G_ADV_RATE_NOT_EXIST, 'g_ext' => ERROR_G_EXT_RATE_NOT_EXIST,
				'b_bsc' => ERROR_B_BSC_RATE_NOT_EXIST, 'b_adv' => ERROR_B_ADV_RATE_NOT_EXIST, 'b_ext' => ERROR_B_EXT_RATE_NOT_EXIST,
				'o_bsc' => ERROR_O_BSC_RATE_NOT_EXIST, 'o_adv' => ERROR_O_ADV_RATE_NOT_EXIST, 'o_ext' => ERROR_O_EXT_RATE_NOT_EXIST,
				'd_bsc' => ERROR_D_BSC_RATE_NOT_EXIST, 'd_adv' => ERROR_D_ADV_RATE_NOT_EXIST, 'd_ext' => ERROR_D_EXT_RATE_NOT_EXIST
			}
			rate_not_numeric = {
				'g_bsc' => ERROR_G_BSC_RATE_NOT_NUMERIC, 'g_adv' => ERROR_G_ADV_RATE_NOT_NUMERIC, 'g_ext' => ERROR_G_EXT_RATE_NOT_NUMERIC,
				'b_bsc' => ERROR_B_BSC_RATE_NOT_NUMERIC, 'b_adv' => ERROR_B_ADV_RATE_NOT_NUMERIC, 'b_ext' => ERROR_B_EXT_RATE_NOT_NUMERIC,
				'o_bsc' => ERROR_O_BSC_RATE_NOT_NUMERIC, 'o_adv' => ERROR_O_ADV_RATE_NOT_NUMERIC, 'o_ext' => ERROR_O_EXT_RATE_NOT_NUMERIC,
				'd_bsc' => ERROR_D_BSC_RATE_NOT_NUMERIC, 'd_adv' => ERROR_D_ADV_RATE_NOT_NUMERIC, 'd_ext' => ERROR_D_EXT_RATE_NOT_NUMERIC
			}
			rate_out_of_range = {
				'g_bsc' => ERROR_G_BSC_RATE_OUT_OF_RANGE, 'g_adv' => ERROR_G_ADV_RATE_OUT_OF_RANGE, 'g_ext' => ERROR_G_EXT_RATE_OUT_OF_RANGE,
				'b_bsc' => ERROR_B_BSC_RATE_OUT_OF_RANGE, 'b_adv' => ERROR_B_ADV_RATE_OUT_OF_RANGE, 'b_ext' => ERROR_B_EXT_RATE_OUT_OF_RANGE,
				'o_bsc' => ERROR_O_BSC_RATE_OUT_OF_RANGE, 'o_adv' => ERROR_O_ADV_RATE_OUT_OF_RANGE, 'o_ext' => ERROR_O_EXT_RATE_OUT_OF_RANGE,
				'd_bsc' => ERROR_D_BSC_RATE_OUT_OF_RANGE, 'd_adv' => ERROR_D_ADV_RATE_OUT_OF_RANGE, 'd_ext' => ERROR_D_EXT_RATE_OUT_OF_RANGE
			}
			perfect_not_exist = {
				'g_bsc' => ERROR_G_BSC_PERFECT_NOT_EXIST, 'g_adv' => ERROR_G_ADV_PERFECT_NOT_EXIST, 'g_ext' => ERROR_G_EXT_PERFECT_NOT_EXIST,
				'b_bsc' => ERROR_B_BSC_PERFECT_NOT_EXIST, 'b_adv' => ERROR_B_ADV_PERFECT_NOT_EXIST, 'b_ext' => ERROR_B_EXT_PERFECT_NOT_EXIST,
				'o_bsc' => ERROR_O_BSC_PERFECT_NOT_EXIST, 'o_adv' => ERROR_O_ADV_PERFECT_NOT_EXIST, 'o_ext' => ERROR_O_EXT_PERFECT_NOT_EXIST,
				'd_bsc' => ERROR_D_BSC_PERFECT_NOT_EXIST, 'd_adv' => ERROR_D_ADV_PERFECT_NOT_EXIST, 'd_ext' => ERROR_D_EXT_PERFECT_NOT_EXIST
			}
			perfect_not_numeric = {
				'g_bsc' => ERROR_G_BSC_PERFECT_NOT_NUMERIC, 'g_adv' => ERROR_G_ADV_PERFECT_NOT_NUMERIC, 'g_ext' => ERROR_G_EXT_PERFECT_NOT_NUMERIC,
				'b_bsc' => ERROR_B_BSC_PERFECT_NOT_NUMERIC, 'b_adv' => ERROR_B_ADV_PERFECT_NOT_NUMERIC, 'b_ext' => ERROR_B_EXT_PERFECT_NOT_NUMERIC,
				'o_bsc' => ERROR_O_BSC_PERFECT_NOT_NUMERIC, 'o_adv' => ERROR_O_ADV_PERFECT_NOT_NUMERIC, 'o_ext' => ERROR_O_EXT_PERFECT_NOT_NUMERIC,
				'd_bsc' => ERROR_D_BSC_PERFECT_NOT_NUMERIC, 'd_adv' => ERROR_D_ADV_PERFECT_NOT_NUMERIC, 'd_ext' => ERROR_D_EXT_PERFECT_NOT_NUMERIC
			}
			perfect_out_of_range = {
				'g_bsc' => ERROR_G_BSC_PERFECT_OUT_OF_RANGE, 'g_adv' => ERROR_G_ADV_PERFECT_OUT_OF_RANGE, 'g_ext' => ERROR_G_EXT_PERFECT_OUT_OF_RANGE,
				'b_bsc' => ERROR_B_BSC_PERFECT_OUT_OF_RANGE, 'b_adv' => ERROR_B_ADV_PERFECT_OUT_OF_RANGE, 'b_ext' => ERROR_B_EXT_PERFECT_OUT_OF_RANGE,
				'o_bsc' => ERROR_O_BSC_PERFECT_OUT_OF_RANGE, 'o_adv' => ERROR_O_ADV_PERFECT_OUT_OF_RANGE, 'o_ext' => ERROR_O_EXT_PERFECT_OUT_OF_RANGE,
				'd_bsc' => ERROR_D_BSC_PERFECT_OUT_OF_RANGE, 'd_adv' => ERROR_D_ADV_PERFECT_OUT_OF_RANGE, 'd_ext' => ERROR_D_EXT_PERFECT_OUT_OF_RANGE
			}
			great_not_exist = {
				'g_bsc' => ERROR_G_BSC_GREAT_NOT_EXIST, 'g_adv' => ERROR_G_ADV_GREAT_NOT_EXIST, 'g_ext' => ERROR_G_EXT_GREAT_NOT_EXIST,
				'b_bsc' => ERROR_B_BSC_GREAT_NOT_EXIST, 'b_adv' => ERROR_B_ADV_GREAT_NOT_EXIST, 'b_ext' => ERROR_B_EXT_GREAT_NOT_EXIST,
				'o_bsc' => ERROR_O_BSC_GREAT_NOT_EXIST, 'o_adv' => ERROR_O_ADV_GREAT_NOT_EXIST, 'o_ext' => ERROR_O_EXT_GREAT_NOT_EXIST,
				'd_bsc' => ERROR_D_BSC_GREAT_NOT_EXIST, 'd_adv' => ERROR_D_ADV_GREAT_NOT_EXIST, 'd_ext' => ERROR_D_EXT_GREAT_NOT_EXIST
			}
			great_not_numeric = {
				'g_bsc' => ERROR_G_BSC_GREAT_NOT_NUMERIC, 'g_adv' => ERROR_G_ADV_GREAT_NOT_NUMERIC, 'g_ext' => ERROR_G_EXT_GREAT_NOT_NUMERIC,
				'b_bsc' => ERROR_B_BSC_GREAT_NOT_NUMERIC, 'b_adv' => ERROR_B_ADV_GREAT_NOT_NUMERIC, 'b_ext' => ERROR_B_EXT_GREAT_NOT_NUMERIC,
				'o_bsc' => ERROR_O_BSC_GREAT_NOT_NUMERIC, 'o_adv' => ERROR_O_ADV_GREAT_NOT_NUMERIC, 'o_ext' => ERROR_O_EXT_GREAT_NOT_NUMERIC,
				'd_bsc' => ERROR_D_BSC_GREAT_NOT_NUMERIC, 'd_adv' => ERROR_D_ADV_GREAT_NOT_NUMERIC, 'd_ext' => ERROR_D_EXT_GREAT_NOT_NUMERIC
			}
			great_out_of_range = {
				'g_bsc' => ERROR_G_BSC_GREAT_OUT_OF_RANGE, 'g_adv' => ERROR_G_ADV_GREAT_OUT_OF_RANGE, 'g_ext' => ERROR_G_EXT_GREAT_OUT_OF_RANGE,
				'b_bsc' => ERROR_B_BSC_GREAT_OUT_OF_RANGE, 'b_adv' => ERROR_B_ADV_GREAT_OUT_OF_RANGE, 'b_ext' => ERROR_B_EXT_GREAT_OUT_OF_RANGE,
				'o_bsc' => ERROR_O_BSC_GREAT_OUT_OF_RANGE, 'o_adv' => ERROR_O_ADV_GREAT_OUT_OF_RANGE, 'o_ext' => ERROR_O_EXT_GREAT_OUT_OF_RANGE,
				'd_bsc' => ERROR_D_BSC_GREAT_OUT_OF_RANGE, 'd_adv' => ERROR_D_ADV_GREAT_OUT_OF_RANGE, 'd_ext' => ERROR_D_EXT_GREAT_OUT_OF_RANGE
			}
			good_not_exist = {
				'g_bsc' => ERROR_G_BSC_GOOD_NOT_EXIST, 'g_adv' => ERROR_G_ADV_GOOD_NOT_EXIST, 'g_ext' => ERROR_G_EXT_GOOD_NOT_EXIST,
				'b_bsc' => ERROR_B_BSC_GOOD_NOT_EXIST, 'b_adv' => ERROR_B_ADV_GOOD_NOT_EXIST, 'b_ext' => ERROR_B_EXT_GOOD_NOT_EXIST,
				'o_bsc' => ERROR_O_BSC_GOOD_NOT_EXIST, 'o_adv' => ERROR_O_ADV_GOOD_NOT_EXIST, 'o_ext' => ERROR_O_EXT_GOOD_NOT_EXIST,
				'd_bsc' => ERROR_D_BSC_GOOD_NOT_EXIST, 'd_adv' => ERROR_D_ADV_GOOD_NOT_EXIST, 'd_ext' => ERROR_D_EXT_GOOD_NOT_EXIST
			}
			good_not_numeric = {
				'g_bsc' => ERROR_G_BSC_GOOD_NOT_NUMERIC, 'g_adv' => ERROR_G_ADV_GOOD_NOT_NUMERIC, 'g_ext' => ERROR_G_EXT_GOOD_NOT_NUMERIC,
				'b_bsc' => ERROR_B_BSC_GOOD_NOT_NUMERIC, 'b_adv' => ERROR_B_ADV_GOOD_NOT_NUMERIC, 'b_ext' => ERROR_B_EXT_GOOD_NOT_NUMERIC,
				'o_bsc' => ERROR_O_BSC_GOOD_NOT_NUMERIC, 'o_adv' => ERROR_O_ADV_GOOD_NOT_NUMERIC, 'o_ext' => ERROR_O_EXT_GOOD_NOT_NUMERIC,
				'd_bsc' => ERROR_D_BSC_GOOD_NOT_NUMERIC, 'd_adv' => ERROR_D_ADV_GOOD_NOT_NUMERIC, 'd_ext' => ERROR_D_EXT_GOOD_NOT_NUMERIC
			}
			good_out_of_range = {
				'g_bsc' => ERROR_G_BSC_GOOD_OUT_OF_RANGE, 'g_adv' => ERROR_G_ADV_GOOD_OUT_OF_RANGE, 'g_ext' => ERROR_G_EXT_GOOD_OUT_OF_RANGE,
				'b_bsc' => ERROR_B_BSC_GOOD_OUT_OF_RANGE, 'b_adv' => ERROR_B_ADV_GOOD_OUT_OF_RANGE, 'b_ext' => ERROR_B_EXT_GOOD_OUT_OF_RANGE,
				'o_bsc' => ERROR_O_BSC_GOOD_OUT_OF_RANGE, 'o_adv' => ERROR_O_ADV_GOOD_OUT_OF_RANGE, 'o_ext' => ERROR_O_EXT_GOOD_OUT_OF_RANGE,
				'd_bsc' => ERROR_D_BSC_GOOD_OUT_OF_RANGE, 'd_adv' => ERROR_D_ADV_GOOD_OUT_OF_RANGE, 'd_ext' => ERROR_D_EXT_GOOD_OUT_OF_RANGE
			}
			poor_not_exist = {
				'g_bsc' => ERROR_G_BSC_POOR_NOT_EXIST, 'g_adv' => ERROR_G_ADV_POOR_NOT_EXIST, 'g_ext' => ERROR_G_EXT_POOR_NOT_EXIST,
				'b_bsc' => ERROR_B_BSC_POOR_NOT_EXIST, 'b_adv' => ERROR_B_ADV_POOR_NOT_EXIST, 'b_ext' => ERROR_B_EXT_POOR_NOT_EXIST,
				'o_bsc' => ERROR_O_BSC_POOR_NOT_EXIST, 'o_adv' => ERROR_O_ADV_POOR_NOT_EXIST, 'o_ext' => ERROR_O_EXT_POOR_NOT_EXIST,
				'd_bsc' => ERROR_D_BSC_POOR_NOT_EXIST, 'd_adv' => ERROR_D_ADV_POOR_NOT_EXIST, 'd_ext' => ERROR_D_EXT_POOR_NOT_EXIST
			}
			poor_not_numeric = {
				'g_bsc' => ERROR_G_BSC_POOR_NOT_NUMERIC, 'g_adv' => ERROR_G_ADV_POOR_NOT_NUMERIC, 'g_ext' => ERROR_G_EXT_POOR_NOT_NUMERIC,
				'b_bsc' => ERROR_B_BSC_POOR_NOT_NUMERIC, 'b_adv' => ERROR_B_ADV_POOR_NOT_NUMERIC, 'b_ext' => ERROR_B_EXT_POOR_NOT_NUMERIC,
				'o_bsc' => ERROR_O_BSC_POOR_NOT_NUMERIC, 'o_adv' => ERROR_O_ADV_POOR_NOT_NUMERIC, 'o_ext' => ERROR_O_EXT_POOR_NOT_NUMERIC,
				'd_bsc' => ERROR_D_BSC_POOR_NOT_NUMERIC, 'd_adv' => ERROR_D_ADV_POOR_NOT_NUMERIC, 'd_ext' => ERROR_D_EXT_POOR_NOT_NUMERIC
			}
			poor_out_of_range = {
				'g_bsc' => ERROR_G_BSC_POOR_OUT_OF_RANGE, 'g_adv' => ERROR_G_ADV_POOR_OUT_OF_RANGE, 'g_ext' => ERROR_G_EXT_POOR_OUT_OF_RANGE,
				'b_bsc' => ERROR_B_BSC_POOR_OUT_OF_RANGE, 'b_adv' => ERROR_B_ADV_POOR_OUT_OF_RANGE, 'b_ext' => ERROR_B_EXT_POOR_OUT_OF_RANGE,
				'o_bsc' => ERROR_O_BSC_POOR_OUT_OF_RANGE, 'o_adv' => ERROR_O_ADV_POOR_OUT_OF_RANGE, 'o_ext' => ERROR_O_EXT_POOR_OUT_OF_RANGE,
				'd_bsc' => ERROR_D_BSC_POOR_OUT_OF_RANGE, 'd_adv' => ERROR_D_ADV_POOR_OUT_OF_RANGE, 'd_ext' => ERROR_D_EXT_POOR_OUT_OF_RANGE
			}
			miss_not_exist = {
				'g_bsc' => ERROR_G_BSC_MISS_NOT_EXIST, 'g_adv' => ERROR_G_ADV_MISS_NOT_EXIST, 'g_ext' => ERROR_G_EXT_MISS_NOT_EXIST,
				'b_bsc' => ERROR_B_BSC_MISS_NOT_EXIST, 'b_adv' => ERROR_B_ADV_MISS_NOT_EXIST, 'b_ext' => ERROR_B_EXT_MISS_NOT_EXIST,
				'o_bsc' => ERROR_O_BSC_MISS_NOT_EXIST, 'o_adv' => ERROR_O_ADV_MISS_NOT_EXIST, 'o_ext' => ERROR_O_EXT_MISS_NOT_EXIST,
				'd_bsc' => ERROR_D_BSC_MISS_NOT_EXIST, 'd_adv' => ERROR_D_ADV_MISS_NOT_EXIST, 'd_ext' => ERROR_D_EXT_MISS_NOT_EXIST
			}
			miss_not_numeric = {
				'g_bsc' => ERROR_G_BSC_MISS_NOT_NUMERIC, 'g_adv' => ERROR_G_ADV_MISS_NOT_NUMERIC, 'g_ext' => ERROR_G_EXT_MISS_NOT_NUMERIC,
				'b_bsc' => ERROR_B_BSC_MISS_NOT_NUMERIC, 'b_adv' => ERROR_B_ADV_MISS_NOT_NUMERIC, 'b_ext' => ERROR_B_EXT_MISS_NOT_NUMERIC,
				'o_bsc' => ERROR_O_BSC_MISS_NOT_NUMERIC, 'o_adv' => ERROR_O_ADV_MISS_NOT_NUMERIC, 'o_ext' => ERROR_O_EXT_MISS_NOT_NUMERIC,
				'd_bsc' => ERROR_D_BSC_MISS_NOT_NUMERIC, 'd_adv' => ERROR_D_ADV_MISS_NOT_NUMERIC, 'd_ext' => ERROR_D_EXT_MISS_NOT_NUMERIC
			}
			miss_out_of_range = {
				'g_bsc' => ERROR_G_BSC_MISS_OUT_OF_RANGE, 'g_adv' => ERROR_G_ADV_MISS_OUT_OF_RANGE, 'g_ext' => ERROR_G_EXT_MISS_OUT_OF_RANGE,
				'b_bsc' => ERROR_B_BSC_MISS_OUT_OF_RANGE, 'b_adv' => ERROR_B_ADV_MISS_OUT_OF_RANGE, 'b_ext' => ERROR_B_EXT_MISS_OUT_OF_RANGE,
				'o_bsc' => ERROR_O_BSC_MISS_OUT_OF_RANGE, 'o_adv' => ERROR_O_ADV_MISS_OUT_OF_RANGE, 'o_ext' => ERROR_O_EXT_MISS_OUT_OF_RANGE,
				'd_bsc' => ERROR_D_BSC_MISS_OUT_OF_RANGE, 'd_adv' => ERROR_D_ADV_MISS_OUT_OF_RANGE, 'd_ext' => ERROR_D_EXT_MISS_OUT_OF_RANGE
			}
			combo_not_exist = {
				'g_bsc' => ERROR_G_BSC_COMBO_NOT_EXIST, 'g_adv' => ERROR_G_ADV_COMBO_NOT_EXIST, 'g_ext' => ERROR_G_EXT_COMBO_NOT_EXIST,
				'b_bsc' => ERROR_B_BSC_COMBO_NOT_EXIST, 'b_adv' => ERROR_B_ADV_COMBO_NOT_EXIST, 'b_ext' => ERROR_B_EXT_COMBO_NOT_EXIST,
				'o_bsc' => ERROR_O_BSC_COMBO_NOT_EXIST, 'o_adv' => ERROR_O_ADV_COMBO_NOT_EXIST, 'o_ext' => ERROR_O_EXT_COMBO_NOT_EXIST,
				'd_bsc' => ERROR_D_BSC_COMBO_NOT_EXIST, 'd_adv' => ERROR_D_ADV_COMBO_NOT_EXIST, 'd_ext' => ERROR_D_EXT_COMBO_NOT_EXIST
			}
			combo_not_numeric = {
				'g_bsc' => ERROR_G_BSC_COMBO_NOT_NUMERIC, 'g_adv' => ERROR_G_ADV_COMBO_NOT_NUMERIC, 'g_ext' => ERROR_G_EXT_COMBO_NOT_NUMERIC,
				'b_bsc' => ERROR_B_BSC_COMBO_NOT_NUMERIC, 'b_adv' => ERROR_B_ADV_COMBO_NOT_NUMERIC, 'b_ext' => ERROR_B_EXT_COMBO_NOT_NUMERIC,
				'o_bsc' => ERROR_O_BSC_COMBO_NOT_NUMERIC, 'o_adv' => ERROR_O_ADV_COMBO_NOT_NUMERIC, 'o_ext' => ERROR_O_EXT_COMBO_NOT_NUMERIC,
				'd_bsc' => ERROR_D_BSC_COMBO_NOT_NUMERIC, 'd_adv' => ERROR_D_ADV_COMBO_NOT_NUMERIC, 'd_ext' => ERROR_D_EXT_COMBO_NOT_NUMERIC
			}
			combo_out_of_range = {
				'g_bsc' => ERROR_G_BSC_COMBO_OUT_OF_RANGE, 'g_adv' => ERROR_G_ADV_COMBO_OUT_OF_RANGE, 'g_ext' => ERROR_G_EXT_COMBO_OUT_OF_RANGE,
				'b_bsc' => ERROR_B_BSC_COMBO_OUT_OF_RANGE, 'b_adv' => ERROR_B_ADV_COMBO_OUT_OF_RANGE, 'b_ext' => ERROR_B_EXT_COMBO_OUT_OF_RANGE,
				'o_bsc' => ERROR_O_BSC_COMBO_OUT_OF_RANGE, 'o_adv' => ERROR_O_ADV_COMBO_OUT_OF_RANGE, 'o_ext' => ERROR_O_EXT_COMBO_OUT_OF_RANGE,
				'd_bsc' => ERROR_D_BSC_COMBO_OUT_OF_RANGE, 'd_adv' => ERROR_D_ADV_COMBO_OUT_OF_RANGE, 'd_ext' => ERROR_D_EXT_COMBO_OUT_OF_RANGE
			}
			judges_is_shortage = {
				'g_bsc' => ERROR_G_BSC_JUDGES_IS_SHORTAGE, 'g_adv' => ERROR_G_ADV_JUDGES_IS_SHORTAGE, 'g_ext' => ERROR_G_EXT_JUDGES_IS_SHORTAGE,
				'b_bsc' => ERROR_B_BSC_JUDGES_IS_SHORTAGE, 'b_adv' => ERROR_B_ADV_JUDGES_IS_SHORTAGE, 'b_ext' => ERROR_B_EXT_JUDGES_IS_SHORTAGE,
				'o_bsc' => ERROR_O_BSC_JUDGES_IS_SHORTAGE, 'o_adv' => ERROR_O_ADV_JUDGES_IS_SHORTAGE, 'o_ext' => ERROR_O_EXT_JUDGES_IS_SHORTAGE,
				'd_bsc' => ERROR_D_BSC_JUDGES_IS_SHORTAGE, 'd_adv' => ERROR_D_ADV_JUDGES_IS_SHORTAGE, 'd_ext' => ERROR_D_EXT_JUDGES_IS_SHORTAGE
			}
			judges_out_of_range = {
				'g_bsc' => ERROR_G_BSC_JUDGES_OUT_OF_RANGE, 'g_adv' => ERROR_G_ADV_JUDGES_OUT_OF_RANGE, 'g_ext' => ERROR_G_EXT_JUDGES_OUT_OF_RANGE,
				'b_bsc' => ERROR_B_BSC_JUDGES_OUT_OF_RANGE, 'b_adv' => ERROR_B_ADV_JUDGES_OUT_OF_RANGE, 'b_ext' => ERROR_B_EXT_JUDGES_OUT_OF_RANGE,
				'o_bsc' => ERROR_O_BSC_JUDGES_OUT_OF_RANGE, 'o_adv' => ERROR_O_ADV_JUDGES_OUT_OF_RANGE, 'o_ext' => ERROR_O_EXT_JUDGES_OUT_OF_RANGE,
				'd_bsc' => ERROR_D_BSC_JUDGES_OUT_OF_RANGE, 'd_adv' => ERROR_D_ADV_JUDGES_OUT_OF_RANGE, 'd_ext' => ERROR_D_EXT_JUDGES_OUT_OF_RANGE
			}
			judge_symbols = {
				'perfect' => 'j1', 'great' => 'j2', 'good' => 'j3',
				'poor' => 'j4', 'miss' => 'j5', 'combo' => 'j6'
			}
			judge_symbols_order = ['perfect', 'great', 'good', 'poor', 'miss', 'combo']
			judge_not_exist = {
				'perfect' => perfect_not_exist, 'great' => great_not_exist,
				'good' => good_not_exist, 'poor' => poor_not_exist,
				'miss' => miss_not_exist, 'combo' => combo_not_exist
			}
			judge_not_numeric = {
				'perfect' => perfect_not_numeric, 'great' => great_not_numeric,
				'good' => good_not_numeric, 'poor' => poor_not_numeric,
				'miss' => miss_not_numeric, 'combo' => combo_not_numeric
			}
			judge_out_of_range = {
				'perfect' => perfect_out_of_range, 'great' => great_out_of_range,
				'good' => good_out_of_range, 'poor' => poor_out_of_range,
				'miss' => miss_out_of_range, 'combo' => combo_out_of_range
			}

			MUSIC_PARTS_ORDER.each do |part|
				MUSIC_DIFFS_ORDER.each do |diff|
					name_init = GfDmMix::make_form_name_init(part, diff)

					# クリア区分がそもそも存在しない場合は以下のエラーチェックはすべてスルー
					type = cgi[name_init + '_t']
					next if type.size == 0

					# 達成率を取得、チェック
					rate = cgi[name_init + '_rt']
					# 達成率入力を選択しているにもかかわらず入力が欠けている場合
					if type == SP_STATUS_BY_RATE and rate.empty?
						return rate_not_exist[name_init]
					end
					# これから先は達成率の入力がある場合に無条件でチェック
					if rate.size > 0
						# 達成率の入力に数字と小数点以外の文字が含まれている場合
						unless rate.is_f?
							return rate_not_numeric[name_init]
						end
						# 達成率が0～100の範囲に収まっていない場合
						if not (0.0..100.0).include?(rate.to_f)
							return rate_out_of_range[name_init]
						end
					end

					# 譜面のノート数がシステム側にない場合は以下のエラーチェックはすべてスルー
					notes = cgi[name_init + '_n'].to_i
					next if notes == 0

					# これから先は判定数入力を選択している場合のみチェック
					if type == SP_STATUS_BY_JUDGE
						# 各判定数のチェック
						judge_symbols_order.each do |j_symbol|
							value = cgi[name_init + '_' + judge_symbols[j_symbol]]
							# 判定数入力を選択しているにもかかわらず入力が欠けている場合
							if type == SP_STATUS_BY_JUDGE and value.empty?
								return judge_not_exist[j_symbol][name_init]
							end
							# ここから先は判定数の入力がある場合に無条件でチェック
							if value.size > 0
								# 判定数の入力に数字以外の文字が含まれている場合
								unless value.is_i?
									return judge_not_numeric[j_symbol][name_init]
								end
								# 判定数が0～譜面ノート数の範囲に収まっていない場合
								if not (0..notes).include?(value.to_i)
									return judge_out_of_range[j_symbol][name_init]
								end
							end
						end

						# 判定数全体での総合エラーチェック
						# POORまでの判定数合計が譜面のノート数の範囲に収まっていない場合
						# MISSは空打ちも含み、足すとノート数を超える場合もあるため、計算から除く
						sum = cgi[name_init + '_' + judge_symbols['perfect']].to_i
						sum	+= cgi[name_init + '_' + judge_symbols['great']].to_i
						sum	+= cgi[name_init + '_' + judge_symbols['good']].to_i
						sum	+= cgi[name_init + '_' + judge_symbols['poor']].to_i
						if not (0..notes).include?(sum)
							return judges_out_of_range[name_init]
						end

						# 判定数の入力があって、かつ全判定数合計が譜面のノート数よりも少ない場合
						sum += cgi[name_init + '_' + judge_symbols['miss']].to_i
						if sum < notes and sum > 0
							return judges_is_shortage[name_init]
						end
					end
				end
			end

			return nil		# エラーなし
		end

		def get_ctrl_name(cgi)
			if cgi['reg'].size > 0
				return '登録'
			elsif cgi['del'].size > 0
				return '削除'
			end
		end

		def get_ctrl_type(cgi)
			if cgi['reg'].size > 0
				return 'reg'
			elsif cgi['del'].size > 0
				return 'del'
			end
		end
	end

	class SkillItem
		# skill_form.rb用のメソッド上書き
		def to_html(mobile=false)
			html = ''

			html << '<table class="edit"'
			html << ' class="width: 100%"' if mobile
			html << '>'
			html << '<tbody>'
			MUSIC_DIFFS_ORDER.each_with_index do |diff, i|
				html << @diff_skills[diff].to_html(mobile)
			end
			if mobile
				html << '<tr>'
				html << '<th colspan="2">コメント</th>'
				html << '</tr>'
				html << '<tr>'
				html << '<td colspan="2">'
				html << '<input type="text" name="comment"'
				html << ' style="width: 90%" maxlength="80"'
				html << ' value="' << CGI.escapeHTML(@comment.to_s) << '">'
				html << '</td>'
				html << '</tr>'
			else
				html << '<tr>'
				html << '<th>コメント</th>'
				html << '<td>'
				html << '<input type="text" name="comment"'
				html << ' size="80" maxlength="80"'
				html << ' value="' << CGI.escapeHTML(@comment.to_s) << '">'
				html << '</td>'
				html << '</tr>'
			end
			html << '</tbody>'
			html << '</table>'

			return html
		end

		def to_html_for_exist
			if empty?
				return '<p>この曲のプレイ情報は登録されていません。</p>'
			else
				# 表を作成する場合は差異表示のない確認画面と同じなので、下の関数にそのまま丸投げ
				return to_html_for_confirm
			end
		end

		# otherにSkillItemが指定されている場合は、それとのポイント差異も表示する
		def to_html_for_confirm(other=nil)
			html = ''

			html << '<table>'
			html << '<thead>'
			html << '<tr><th colspan="2">レベル</th>'
			html << '<th>&nbsp;<img src="/images/padlocpadloc004.png" alt="[未取得]" height="12"/>&nbsp;</th>'
			html << '<th>RP</th>'
			html << '<th>差異</th>' if other
			html << '<th>RATE</th><th><img src="/images/ult.png" alt="U" height="12"/>RATE</th>'
			html << '<th>ランク</th><th>コンボ</th>'
			html << '<th>ULT</th>'
			html << '</tr>'
			html << '</thead>'
			html << '<tbody>'

			MUSIC_DIFFS_ORDER.each do |diff|
				skill = @diff_skills[diff]
				old_skill = other.diff_skills[diff] if other

				if other
					html << skill.to_html_for_confirm(old_skill)
				else
					html << skill.to_html_for_confirm
				end
			end
			html << '</tbody>'
			html << '</table>'

			if (@comment || '').size > 0
				html << '<p>コメント: ' << CGI.unescapeHTML(@comment.to_s) << '</p>'
			end

			return html
		end

		# 有効なスキル情報の有無を取得する
		def empty?
			return @max_skill.point.nil?
		end
	end

	class SkillScoreItem
		include IconUtil
		include SkillDataCellUtil

		# skill_form.rb用のメソッド上書き
		def to_html(mobile=false)
			html = ''
			name_init = MUSIC_DIFF_CLASSES[@diff]

			html << "<tr class=\"#{MUSIC_DIFF_CLASSES[@diff]}\">"
			html << "<th rowspan=\"2\" class=\"#{MUSIC_DIFF_CLASSES[@diff]}\">"
			html << MUSIC_DIFFS[@diff] << '</th>'
			# 1行目: 達成率入力（判定とコンボの欄を用意）
			html << '<td>'
			html << "<label><input type=\"radio\" name=\"#{name_init}_stat\""
			html << " value=\"#{SP_STATUS_CLEAR}\""
			html << " checked" if @stat == SP_STATUS_CLEAR
			html << ">#{SP_STATUSES[SP_STATUS_CLEAR]}</label>: "
			html << "<label>RP: <input type=\"text\" name=\"#{name_init}_point\""
			html << " maxlength=\"#{RATE_FIGURE}\" style=\"width: 3.0em\; ime-mode: disabled\""
			html << " value=\"#{sprintf('%.2f', @point)}\"" if @point and @point > 0.0
			html << '></label> '
			html << '<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' if mobile
			html << "<label>CLEAR RATE: <input type=\"text\" name=\"#{name_init}_rate\""
			html << " maxlength=\"#{RATE_FIGURE}\" style=\"width: 2.0em\"; ime-mode: disabled\""
			html << " value=\"#{sprintf('%d', @rate)}\"" if @rate and @rate > 0
			html << '> %</label> '
			html << '<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' if mobile
			html << "<label>ランク: <select name=\"#{name_init}_rank\">"
			html << hash_to_option_html(SP_RANK_STATUSES, @rank)
			html << '</select></label> '
			html << '<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' if mobile
			html << "<label>フルコンボ: <select name=\"#{name_init}_fcs\">"
			html << hash_to_option_html(SP_COMBO_STATUSES, @fcs)
			html << '</select></label> '
			html << '<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' if mobile
			html << "<label><input type=\"checkbox\" name=\"#{name_init}_ultimate\""
			html << " value=\"1\""
			html << " checked" if ultimate?
			html << ">ULTIMATE</label>"
			html << '</td>'
			html << '</tr>'
			# 3行目: 失敗/未プレイ
			html << "<tr class=\"#{MUSIC_DIFF_CLASSES[@diff]}\">"
			html << '<td>'
			html << "<label><input type=\"radio\" name=\"#{name_init}_stat\""
			html << " value=\"#{SP_STATUS_FAILED}\""
			html << " checked" if @stat == SP_STATUS_FAILED
			html << ">#{SP_STATUSES[SP_STATUS_FAILED]}</label> / "
			html << "<label><input type=\"radio\" name=\"#{name_init}_stat\""
			html << " value=\"#{SP_STATUS_NO_PLAY}\""
			html << " checked" if @stat == SP_STATUS_NO_PLAY
			html << ">#{SP_STATUSES[SP_STATUS_NO_PLAY]}</label> "
			html << '<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' if mobile
			html << "<label><input type=\"checkbox\" name=\"#{name_init}_locked\""
			html << " value=\"1\""
			html << " checked" if locked?
			html << ">未取得/ロック譜面</label>"
			html << '</td>'
			html << '</tr>'

			return html
		end

		def to_html_for_confirm(other=nil)
			html = ''

			html << "<tr class=\"#{MUSIC_DIFF_CLASSES[@diff]}\">"

			# スキルポイント表示
			html << "<th class=\"#{MUSIC_DIFF_CLASSES[@diff]}\">"
			html << "#{MUSIC_DIFFS[@diff]}</th>"
			# レベル表示
			html << make_level_data_cell_html(@music.level(@diff))
			# 所持ステータス表示
			if locked?
				html << '<td class="mark"><img src="/images/padlocpadloc004.png" alt="[未取得]" height="12"/></td>'
			else
				html << '<td></td>'
			end
			# スキルポイント表示
			html << '<td class="point">'
			html << sprintf('%.2f', @point)
			html << '</td>'
			# スキルポイント差異表示
			if other
				html << make_difference_data_cell_html(@point - (other.point || 0.0))
			end

			# 達成率以降の成績詳細
			case @stat
			when SP_STATUS_FAILED, SP_STATUS_NO_PLAY
				# 失敗時と未プレイ時は詳細情報を表示しない
				html << "<td colspan=\"5\" class=\"none\">"
				html << SP_STATUSES[@stat] << '</td>'
			else
				html << "<td class=\"rate\">#{sprintf_for_rate(@rate)}</td>"
				html << "<td class=\"rate\">#{sprintf_for_rate(@u_rate)}</td>"
				html << '<td class="mark">' << SP_RANK_STATUSES[@rank] << '</td>'
				html << '<td class="mark">' << SP_COMBO_STATUSES[@fcs] << '</td>'
				html << '<td class="mark">' << (ultimate? ? '○' : '') << '</td>'
			end

			html << '</tr>'

			return html
		end
	end
end
