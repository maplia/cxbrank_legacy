#---------------------------------------------------------------
#	GFDMmix for CS - Library for Music Data Form
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'cgi'
require 'util'
require 'gfdmmix/util'
require 'gfdmmix/pagemaker'
require 'gfdmmix/music_util'
require 'gfdmmix/music_database'
require 'gfdmmix/music_validate'

module GfDmMix
	class MusicEditFormMaker < PageMaker
		include IconUtil
		include MusicEditUtil

		# 編集する曲の指定はCGIのパラメータからもらう
		def initialize(cgi, session)
			@cgi = cgi
			@session = session
			@template_html = 'template/music_edit.html'
		end

		def to_html
			mid = @cgi['mid']
			mode = @cgi['mode']
			rule = @cgi['version']

			error_no = validate_params_for_music_form(mid, mode, rule)
			if error_no != NO_ERROR
				return make_error_page(error_no)
			end

			html = read_template_html(true)

			# 曲情報の取得
			if @session['music']
				# 前のセッションから入力値を引き継いでいる場合はそれを初期表示とする
				# ↑登録確認画面で「いいえ」が選択された場合
				music = @session['music']
			else
				if mid.empty?
					# 曲IDの指定がない場合は空の曲データを作成する
					music = MusicItem.make_empty_item(rule)
				else
					m_db = MusicDatabase.new
					music = m_db.get(mid, rule)
					m_db.close
				end

				# 取得した曲の情報をセッション領域に記録しておく
				@session['music'] = music
			end

			# 指定した曲IDについての登録済み情報をすべて取得する
			m_db = MusicDatabase.new
			exists = m_db.get_mid_musics(mid)
			m_db.close

			html.gsub!(/<!--PRESET_MUSIC_EDIT_URI-->/, MUSIC_EDIT_PROGRAM)
			html.gsub!(/<!--PRESET_MUSIC_LIST_URI-->/, make_list_uri(mode, rule))
			html.gsub!(/<!--PRESET_MODE-->/, mode)
			html.gsub!(/<!--PRESET_MODE_NAME-->/, coalesce(MODES[mode], ''))
			html.gsub!(/<!--PRESET_SUBMIT_BUTTONS-->/, make_submit_button_html(music))

			# 曲情報の表示
			html.gsub!(/<!--PRESET_MUSIC_ID-->/, music.mid)
			html.gsub!(/<!--PRESET_MUSIC_TITLE-->/, coalesce_string(music.title, 'New Song'))
			html.gsub!(/<!--PRESET_LAST_MUSIC_STATUS-->/, make_exist_list_html(exists))
			html.gsub!(/<!--PRESET_MUSIC_EDIT_FORM-->/, music.to_html)

			return html
		end

		private
		def make_exist_list_html(exists)
			if exists.empty?
				return ''
			end

			html = ''
			music = exists.first

			html << '<div class="unit">'
			html << '<h2>現在の登録状況</h2>'
			html << '<div class="subunit">'
			html << '<p>'
			html << "曲タイプ: #{MUSIC_TYPES[music.mtype]} / "
			html << "初出バージョン: #{FIRST_VERSIONS[music.appear]}"
			html << '</p>'

			html << '<table class="list">'
			html << '<thead>'

			# ヘッダ1行目: パート表示
			html << '<tr>'
			html << '<th rowspan="3">＼</th>'
			MUSIC_PARTS_ORDER.each do |part|
				html << "<th colspan=\"#{MUSIC_DIFFS.size * 2}\">#{MUSIC_PARTS[part]}</th>"
			end
			html << '</tr>'

			# ヘッダ2行目: 譜面難易度表示
			html << '<tr>'
			MUSIC_PARTS.size.times do
				MUSIC_DIFFS_ORDER.each do |diff|
					html << "<th colspan=\"2\" class=\"#{MUSIC_DIFF_CLASSES[diff]}\">"
					html << make_diff_icon_html(diff) << '</th>'
				end
			end
			html << '</tr>'

			# ヘッダ3行目: データセル項目表示
			html << '<tr>'
			MUSIC_PARTS.size.times do
				MUSIC_DIFFS_ORDER.each do |diff|
					html << "<th class=\"#{MUSIC_DIFF_CLASSES[diff]}\">Lv</th>"
					html << "<th class=\"#{MUSIC_DIFF_CLASSES[diff]}\">Note</th>"
				end
			end
			html << '</tr>'
			html << '</thead>'
			exists.each do |music|
				html << music.to_html_for_exist
			end
			html << '</table>'
			html << '</div>'
			html << '</div>'

			return html
		end
	end

	class MusicCertifier < PageMaker
		include MusicEditUtil

		def initialize(cgi, session)
			@cgi = cgi
			@session = session
			@template_html = 'template/music_edit_conf.html'
		end

		def to_html
			mode = @cgi['mode']
			rule = @cgi['version']
			music = MusicItem.make_item_from_cgi_params(@cgi)
			@session['music'] = music

			error_no = music.validate
			if error_no != NO_ERROR
				return make_error_page(error_no, @cgi.script_name)
			end

			html = read_template_html(true)

			html.gsub!(/<!--PRESET_MUSIC_EDIT_URI-->/, MUSIC_EDIT_PROGRAM)
			html.gsub!(/<!--PRESET_MUSIC_LIST_URI-->/, make_list_uri(mode, rule))
			html.gsub!(/<!--PRESET_MUSIC_ID-->/, music.mid)
			html.gsub!(/<!--PRESET_MODE-->/, mode)
			html.gsub!(/<!--PRESET_MODE_NAME-->/, coalesce(MODES[mode], ''))
			html.gsub!(/<!--PRESET_VERSION-->/, rule)
			html.gsub!(/<!--PRESET_SUBMIT_NAME-->/, get_submit_name_from_cgi_params(@cgi))
			html.gsub!(/<!--PRESET_SUBMIT_TYPE_PARAM-->/, make_submit_type_param_html(@cgi))
			html.gsub!(/<!--PRESET_TITLE-->/, music.title)
			html.gsub!(/<!--PRESET_SORTKEY-->/, music.sortkey)
			html.gsub!(/<!--PRESET_TYPE_NAME-->/, MUSIC_TYPES[music.mtype])
			html.gsub!(/<!--PRESET_FIRST_VERSION_NAME-->/, FIRST_VERSIONS[music.appear])
			html.gsub!(/<!--PRESET_VERSION_NAME-->/, VERSIONS_FOR_EDIT[music.rule])
			html.gsub!(/<!--PRESET_MUSIC_SCORE_LIST-->/, music.to_html_for_confirm)

			return html
		end
	end

	class MusicRegister
		include MusicEditUtil

		def initialize(cgi, session)
			@cgi = cgi
			@session = session
		end

		def to_html
			mode = @cgi['mode']
			rule = @cgi['version']
			music = @session['music']

			# 曲情報のデータベースへの登録を実行する
			m_db = MusicDatabase.new
			if register_submit?(@cgi)
				edited_mid = m_db.edit(music)
			elsif delete_submit?(@cgi)
				m_db.delete(music)
			end
			m_db.close

			# 編集が確定したので、セッション変数の作業領域をクリアする
			@session.clear_work_area

			list_uri = ''
			list_uri << "#{MUSIC_LIST_EDIT_PROGRAM}?"
			list_uri << "mode=#{mode};" unless mode.empty?
			list_uri << "version=#{rule}"
			list_uri << "#m#{edited_mid}" if edited_mid

			return list_uri
		end
	end

	class MusicItem
		include IconUtil
		include MusicEditUtil

		def MusicItem.make_item_from_cgi_params(cgi)
			msi_hash = Hash.new
			MUSIC_PARTS.each_key do |part|
				msi_hash[part] = Hash.new

				MUSIC_DIFFS.each_key do |diff|
					key = GfDmMix::make_form_name_init(part, diff)
					level = cgi["#{key}_l"].to_i
					notes = cgi["#{key}_n"].to_i

					msi_hash[part][diff] =
						MusicScoreItem.new(part, diff, level, notes, cgi['sortkey'])
				end
			end

			# 実体参照での入力を取り込むために、意図的にエスケープをしない
			# その代わり、入力する際は確実に「&」などの文字を実体参照とすること
			return MusicItem.new(cgi['mid'], cgi['title'],
				cgi['mtype'], cgi['appear'], cgi['sortkey'], cgi['music_comment'],
				cgi['version'], msi_hash, cgi['score_comment'])
		end

		# music_form.rb用のメソッド上書き
		def to_html
			html = ''

			html << '<table class="edit">'
			html << '<thead>'
			html << '<tr><th colspan="2">項目</th><th>入力欄</th></tr>'
			html << '</thead>'
			html << '<tbody>'

			# 基本情報部分
			html << <<-"EOB"
				<tr>
					<th colspan="2">曲名</th>
					<td>#{make_text_input_element('title', @title, 40, 1, true)}</td>
				</tr>
				<tr>
					<th colspan="2">読み</th>
					<td>#{make_text_input_element('sortkey', @sortkey, 40, 2, true)}</td>
				</tr>
				<tr>
					<th colspan="2">曲タイプ</th>
					<td>#{make_select_element('mtype', MUSIC_TYPES, @mtype, 3)}</td>
				</tr>
				<tr>
					<th colspan="2">初出バージョン</th>
					<td>#{make_select_element('appear', FIRST_VERSIONS, @appear, 4)}</td>
				</tr>
				<tr>
					<th colspan="2">対象バージョン</th>
					<td>#{make_select_element('version', VERSIONS_FOR_EDIT, @rule, 5)}</td>
				</tr>
				<tr>
					<th colspan="2">備考</th>
					<td>#{make_text_input_element('music_comment', @music_comment, 40, 6, true)}</td>
				</tr>
			EOB
			tabindex = 7

			# 曲の譜面情報部分
			MUSIC_PARTS_ORDER.each_with_index do |part, i|
				MUSIC_DIFFS_ORDER.each_with_index do |diff, j|
					# tabindexは全譜面のレベル、全譜面のノート数（それぞれ難度順）の順で設定する
					# このブロックでの基点はこれまでのtabindexの最大値に続くものとする
					level_tabindex = MUSIC_DIFFS.size*i + j + tabindex
					notes_tabindex = level_tabindex + MUSIC_SCORE_COUNT

					html << @msi_hash[part][diff].to_html(level_tabindex, notes_tabindex)
				end
			end
			tabindex = tabindex + MUSIC_SCORE_COUNT*2

			html << <<-"EOB"
				<tr>
					<th colspan="2">バージョン備考</th>
					<td>
						#{make_text_input_element('score_comment', @score_comment, 40, tabindex, true)}
					</td>
				</tr>
			EOB

			html << '</tbody>'
			html << '</table>'

			return html.gsub!(/[\t\r\n]/, '')
		end

		def to_html_for_exist
			html = ''

			html << '<tr>'
			html << "<th>#{VERSIONS_ABBR_FOR_EDIT[@version]}</th>"
			MUSIC_PARTS_ORDER.each do |part|
				MUSIC_DIFFS_ORDER.each do |diff|
					html << @msi_hash[part][diff].to_html_for_exist
				end
			end
			html << '</tr>'

			return html
		end

		def to_html_for_confirm
			html = ''

			html << '<table class="list">'
			html << '<thead>'
			html << '<tr>'
			# ヘッダ1行目: パート表示
			html << '<th rowspan="2">＼</th>'
			MUSIC_PARTS_ORDER.each do |part|
				html << "<th colspan=\"2\">#{MUSIC_PARTS[part]}</th>"
			end
			html << '</tr>'
			# ヘッダ2行目: データセル項目表示
			html << '<tr>'
			MUSIC_PARTS.size.times do
				html << '<th>Lv</th><th>Note</th>'
			end
			html << '</tr>'
			html << '</thead>'

			# 確認用の表は入力フォームとは横と縦の表示軸を逆にする
			html << '<tbody>'
			MUSIC_DIFFS_ORDER.each do |diff|
				html << "<tr class=\"#{MUSIC_DIFF_CLASSES[diff]}\">"
				html << "<th class=\"#{MUSIC_DIFF_CLASSES[diff]}\">"
				html << make_diff_icon_html(diff) << '</th>'

				MUSIC_PARTS_ORDER.each do |part|
					html << @msi_hash[part][diff].to_html_for_confirm
				end
				html << '</tr>'
			end

			html << '</tbody>'
			html << '</table>'

			return html
		end
	end

	class MusicScoreItem
		include IconUtil
		include MusicDataCellUtil

		# music_form.rb用のメソッド上書き
		def to_html(level_tabindex, notes_tabindex)
			html = ''
			key = GfDmMix::make_form_name_init(@part, @diff)

			html << '<tr>'
			# BSC譜面の場合のみパート名を表示する
			if @diff == MUSIC_DIFF_BSC
				html << make_th_element(MUSIC_PARTS[@part], nil, MUSIC_DIFFS.size)
			end
			html << make_diff_head_cell_html(@diff)
			html << "<td class=\"#{MUSIC_DIFF_CLASSES[@diff]}\">"
			html << '<label>曲レベル: '
			html << make_input_element_for_level("#{key}_l", @level, level_tabindex)
			html << '</label> / '
			html << '<label>ノート数: '
			html << make_input_element_for_notes("#{key}_n", @notes, notes_tabindex)
			html << '</label>'
			html << '</td>'
			html << '</tr>'

			return html
		end

		def to_html_for_exist
			html = ''

			html << make_level_data_cell_html(@level, @diff)
			html << make_notes_data_cell_html(@notes, @level, @diff)

			return html
		end

		def to_html_for_confirm
			# 期待する出力結果は下の関数とまったく同じなので、処理を丸投げ
			return to_html_for_exist
		end

		private
		def make_input_element_for_level(name, level, tabindex)
			html = ''

			html << "<input type=\"text\" name=\"#{name}\""
			html << " size=\"#{LEVEL_FIGURE}\" maxlength=\"#{LEVEL_FIGURE}\""
			html << " tabindex=\"#{tabindex}\""
			html << " value=\"#{level}\"" if level > 0
			html << '>'

			return html
		end

		def make_input_element_for_notes(name, notes, tabindex)
			html = ''

			html << "<input type=\"text\" name=\"#{name}\""
			html << " size=\"#{NOTES_FIGURE}\" maxlength=\"#{NOTES_FIGURE}\""
			html << " tabindex=\"#{tabindex}\""
			html << " value=\"#{notes}\"" if notes > 0
			html << '>'

			return html
		end
	end
end
