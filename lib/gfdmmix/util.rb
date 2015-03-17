#---------------------------------------------------------------
#	GFDMmix for CS - Global Method Definition
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'cgi'
require 'image_size'
require 'gfdmmix/const'

module GfDmMix
	module Util
	end

	# 譜面識別子周りの共通関数
	module ScoreKeyUtil
		# パートと難易度の組み合わせた譜面識別子を作成する
		def make_score_key(part, diff)
			part_name = MUSIC_PARTS[part].downcase
			diff_name = MUSIC_DIFFS[diff].downcase

			return "#{part_name[0, 1]}_#{diff_name}"
		end
	end

	# データ閲覧ページ用共通関数
	module ListUtil
		include Util
		include ScoreKeyUtil
	end

	# データ編集ページ用共通関数
	module EditUtil
		include Util
		include ScoreKeyUtil

		EDIT_SUBMIT_TYPE_REGISTER = 'reg'
		EDIT_SUBMIT_TYPE_REGISTER_NAME = '登録'
		EDIT_SUBMIT_TYPE_DELETE = 'del'
		EDIT_SUBMIT_TYPE_DELETE_NAME = '削除'
		EDIT_SUBMIT_TYPES = {
			EDIT_SUBMIT_TYPE_REGISTER => EDIT_SUBMIT_TYPE_REGISTER_NAME,
			EDIT_SUBMIT_TYPE_DELETE   => EDIT_SUBMIT_TYPE_DELETE_NAME
		}
		EDIT_SUBMIT_TYPES_ORDER = [EDIT_SUBMIT_TYPE_REGISTER, EDIT_SUBMIT_TYPE_DELETE]
		EDIT_SUBMIT_TYPE_PARAM_NAME = 'ctrl'

		# text形式のinput要素を作成する
		def make_text_input_element(name, default,
			size=nil, tabindex=nil, escape=false, size_fixed=false, readonly=false)
			html = ''
			value = (escape ? CGI.escapeHTML(default.to_s) : default)

			html << %q|<input type="text"|
			html << %Q{ name="#{name}"}
			html << %Q{ value="#{value}"} unless value.empty?
			html << %Q{ size="#{size}"} if size
			html << %Q{ tabindex="#{tabindex}"} if tabindex
			html << %Q{ maxlength="#{size}"} if size_fixed
			html << %q| readonly| if readonly
			html << %q|>|

			return html
		end

		# セレクトボックス（select要素とoption要素の組み合わせ）を作成する
		def make_select_element(name, hash_for_options, default=nil, tabindex=nil)
			html = ''

			html << %Q{<select name="#{name}"}
			html << %Q{ tabindex="#{tabindex}"} if tabindex
			html << %q|>|
			html << hash_to_option_html(hash_for_options, default)
			html << '</select>'

			return html
		end

		# textarea要素を作成する
		def make_textarea_element(name, default, rows, cols, tabindex=nil, escape=false)
			html = ''
			text = (escape ? CGI.escapeHTML(default) : default)

			html << %Q{<textarea name="#{name}" rows="#{rows}" cols="#{cols}"}
			html << %Q{ tabindex="#{tabindex}"} if tabindex
			html << %q|>|
			html << text
			html << %q|</textarea>|

			return html
		end

		# 編集ページのsubmitボタンを表示するためのHTML部品を作成する
		def make_submit_button_html(old_data)
			html = ''
			tabindex = 1001

			EDIT_SUBMIT_TYPES_ORDER.each do |type|
				html << %q|<input type="submit"|
				html << %Q{ name="#{type}" value="#{EDIT_SUBMIT_TYPES[type]}"}
#				html << %Q{ tabindex="#{tabindex}"}
				html << %q| disabled| if type == EDIT_SUBMIT_TYPE_DELETE and old_data.empty?
				html << %q|>|

				tabindex += 1
			end
#			html << %Q{<input type="reset" value="入力リセット" tabindex="#{tabindex}">}

			return html
		end

		# 編集確認ページに編集の種類を反映するためのHTML部品を作成する
		def make_submit_type_param_html(cgi)
			html = ''

			html << %Q{<input type="hidden" name="#{EDIT_SUBMIT_TYPE_PARAM_NAME}"}
			html << %Q{ value="#{get_submit_type_from_cgi_params(cgi)}">}

			return html
		end

		# 編集の種類が登録かどうかを取得する
		def register_submit?(cgi)
			return cgi[EDIT_SUBMIT_TYPE_PARAM_NAME] == EDIT_SUBMIT_TYPE_REGISTER
		end

		# 編集の種類が削除かどうかを取得する
		def delete_submit?(cgi)
			return cgi[EDIT_SUBMIT_TYPE_PARAM_NAME] == EDIT_SUBMIT_TYPE_DELETE
		end

		# CGIのパラメータから編集の種類を取得する
		def get_submit_type_from_cgi_params(cgi)
			if cgi[EDIT_SUBMIT_TYPE_REGISTER].size > 0
				return EDIT_SUBMIT_TYPE_REGISTER
			elsif cgi[EDIT_SUBMIT_TYPE_DELETE].size > 0
				return EDIT_SUBMIT_TYPE_DELETE
			else
				raise 'must not happen'
			end
		end

		# CGIのパラメータから編集の種類の名前を取得する
		def get_submit_name_from_cgi_params(cgi)
			return EDIT_SUBMIT_TYPES[get_submit_type_from_cgi_params(cgi)]
		end
	end

	# アイコン表示関数
	module IconUtil
		# 指定した演奏パートを示すアイコンを表示するためのHTML部品を作成する
		def make_part_icon_html(part)
			if MUSIC_PART_IMAGES.include?(part)
				return make_img_element(MUSIC_PART_IMAGES[part], "[#{MUSIC_PARTS[part]}]")
			else
				return ''
			end
		end

		# 指定した譜面難易度を示すアイコンを表示するためのHTML部品を作成する
		def make_diff_icon_html(diff)
			return make_img_element(MUSIC_DIFF_IMAGES[diff], MUSIC_DIFFS[diff])
		end

		# 画像ファイル名からそれを表示するためのimg要素を作成する
		def make_img_element(image_path, alt='')
			html = ''
			image_size = ImageSize.new(File.open(image_path, 'rb').read)	# read & binary

			html << %Q{<img src="#{image_path}" alt="#{alt}"}
			html << %Q{ width="#{image_size.width}" height="#{image_size.height}">}

			return html
		end
	end

	# テーブルのデータセル出力関数
	module DataCellUtil
		include IconUtil

		# 指定されたテキストを含むデータセルを表示するためのHTML部品を作成する
		def make_text_data_cell_html(text, add_classes=nil)
			cell_classes = ['text']
			cell_classes.concat(add_classes) if add_classes

			return make_td_element(text, cell_classes)
		end

		# 指定されたマークを含むデータセルを表示するためのHTML部品を作成する
		def make_mark_data_cell_html(text, add_classes=nil)
			cell_classes = ['mark']
			cell_classes.concat(add_classes) if add_classes

			return make_td_element(text, cell_classes)
		end

		# 指定した難易度レベルを含むデータセルを表示するためのHTML部品を作成する
		def make_level_data_cell_html(level, diff=nil)
			cell_classes = ['level']
			cell_classes << MUSIC_DIFF_CLASSES[diff] if diff

			return make_td_element(sprintf_for_level(level), cell_classes)
		end

		# 指定したノート数を含むデータセルを表示するためのHTML部品を作成する
		def make_notes_data_cell_html(notes, level, diff=nil)
			cell_classes = ['notes']
			cell_classes << MUSIC_DIFF_CLASSES[diff] if diff

			return make_td_element(sprintf_for_notes(notes, level), cell_classes)
		end

		# 指定した譜面難度を示すヘッダセルを表示するためのHTML部品を作成する
		def make_diff_head_cell_html(diff, rowspan=1, colspan=1)
			return make_th_element(
				make_diff_icon_html(diff), [MUSIC_DIFF_CLASSES[diff]], rowspan, colspan)
		end

		# データセルを表示するためのHTML部品を作成する
		def make_td_element(text, cell_classes=nil)
			html = ''

			html << %q|<td|
			html << %Q{ class="#{cell_classes.join(' ')}"} if cell_classes
			html << %Q{>#{text}</td>}

			return html
		end

		# ヘッダセルを表示するためのHTML部品を作成する
		def make_th_element(text, cell_classes=nil, rowspan=1, colspan=1)
			html = ''

			html << %q|<th|
			html << %Q{ class="#{cell_classes.join(' ')}"} if cell_classes
			html << %Q{ rowspan="#{rowspan}"} if rowspan > 1
			html << %Q{ colspan="#{colspan}"} if colspan > 1
			html << %Q{>#{text}</th>}

			return html
		end

		# 難易度レベル用sprintf
		def sprintf_for_level(level)
			if level == 0
				return ''
			else
				return sprintf("%.1f", level)
			end
		end

		# ノート数用sprintf
		def sprintf_for_notes(notes)
			if notes == 0
				return '??'
			else
				return sprintf("%d", notes)
			end
		end

		# 達成率用sprintf
		def sprintf_for_rate(rate)
			if rate == 0
				return '&ndash;'
			else
				return sprintf("%d%%", rate)
			end
		end
	end

	module NavigateUtil
	end

	# フォームのコントロール名で使用するパート+難易度の識別子の先頭部分を作成する
	def make_form_name_init(part, diff)
		return MUSIC_PARTS[part].downcase[0, 1] + '_' + MUSIC_DIFFS[diff].downcase
	end
	alias :make_score_key :make_form_name_init		# 便利なので譜面識別子の生成関数に流用

	# HTMLテンプレートファイルを読み込む
	def read_temp_html(file)
		html = File.open(file).read

		footer = ''
		footer << '<address>'
		footer << 'Generated by '
		footer << "<a href=\"/#{SITE_TOP_PROGRAM}\">#{ENGINE_NAME}</a> #{ENGINE_VERSION}<br>"
		footer << "Powered by Ruby #{RUBY_VERSION}"
		footer << '</address>'

		html.gsub!(/<!--PRESET_CHARSET-->/, DEFAULT_CHARSET)
		html.gsub!(/<!--PRESET_ENGINE_NAME-->/, ENGINE_NAME)
		html.gsub!(/<!--PRESET_SITE_TOP_URI-->/, SITE_TOP_PROGRAM)
		html.gsub!(/<!--PRESET_STYLE_SHEET-->/, DEFAULT_STYLE_SHEET)
		html.gsub!(/<!--PRESET_STYLE_SHEET_URI-->/, DEFAULT_STYLE_SHEET)
		html.gsub!(/<!--PRESET_FOOTER-->/, footer)
		html.gsub!(/[\t\r\n]/, '')		# スペース以外の空白文字はすべて消してしまう

		return html
	end

	# エラー発生時のページを作成する
	def make_error_page(error_no, back_uri=nil, cgi=nil)
		html = read_temp_html('template/error.html')

		# ログアウトのときは、ページのtitle要素の内容をそれっぽく置き換え
		if error_no == ERROR_SESSION_IS_FINISHED
			html.gsub!('エラー', 'ログアウト完了')
		end
		html.gsub!(/<!--ERROR_TEXT-->/, "<p>#{CGI.unescapeHTML(ERRORS[error_no])}</p>")

		if back_uri
			if cgi
				# cgiが渡されてきた場合は、持っている情報をhidden形式のinputに展開する
				back_part = ''
				back_part << %Q{<form method="post" action="#{back_uri}">}
				cgi.params.each do |key, value|
					back_part << %Q{<input type="hidden" name="#{key}" value="#{value}">}
				end
				back_part << '<input type="submit" name="n" value="戻る">'
				back_part << '</form>'
			else
				back_part = %Q{<p><a href="#{back_uri}">戻る</a></p>}
			end

			html.gsub!(/<!--BACK_LINK-->/, back_part)
		else
			html.gsub!(/<!--BACK_LINK-->/, '')
		end

		return html
	end

	module_function :make_form_name_init, :make_score_key
	module_function :read_temp_html, :make_error_page
end
