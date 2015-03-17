#---------------------------------------------------------------
#	GFDMmix for CS - Page Maker Base Class
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'time'
require 'util'
require 'gfdmmix/util'

module GfDmMix
	class PageMaker
		# ページの最終更新時刻として扱うTime値を取得する
		# セッション中なら0時刻、静的ページならテンプレートファイルの更新時刻を返す
		# それ以外の値を返したい場合は、このメソッドをオーバーライドすること
		def mtime
			if @session or @template_html.nil?
				return Time.at(0)
			else
				return File.mtime(@template_html)
			end
		end
		alias get_last_modified mtime

		private
		def read_template_html(is_admin=false)
			html = File.open(@template_html).read

			footer = ''
			footer << '<address>'
			footer << "Generated by <a href=\"/#{SITE_TOP_PROGRAM}\">#{ENGINE_NAME}</a>"
			footer << " #{ENGINE_VERSION}<br />"
			footer << "Powered by <a href=\"http://www.ruby-lang.org/\">Ruby</a>"
			footer << " #{RUBY_VERSION}"
			footer << '</address>'

			html.gsub!(/<!--PRESET_CHARSET-->/, DEFAULT_CHARSET)
			html.gsub!(/<!--PRESET_ENGINE_NAME-->/, ENGINE_NAME)
			if is_admin
				html.gsub!(/トップ/, 'システム管理トップ')
				html.gsub!(/<!--PRESET_SITE_TOP_URI-->/, ADMIN_TOP_PROGRAM)
			else
				html.gsub!(/<!--PRESET_SITE_TOP_URI-->/, SITE_TOP_PROGRAM)
			end
			html.gsub!(/<!--PRESET_STYLE_SHEET-->/, DEFAULT_STYLE_SHEET)
			html.gsub!(/<!--PRESET_STYLE_SHEET_URI-->/, DEFAULT_STYLE_SHEET)
			html.gsub!(/<!--PRESET_FOOTER-->/, footer)

			# スペース以外の空白文字はすべて消してしまう
			html.gsub!(/[\t\r\n]/, '')

			return html
		end

		def make_error_page(error_no, back_uri=nil)
			@template_html = 'template/error.html'		# テンプレートファイルを差し替え
			html = read_template_html

			# ログアウトのときは、ページのtitle要素の内容をそれっぽく置き換え
			if error_no == ERROR_SESSION_IS_FINISHED
				html.gsub!(/エラー/, 'ログアウト完了')
			end
			html.gsub!(/<!--ERROR_TEXT-->/, "<p>#{CGI.unescapeHTML(ERRORS[error_no])}</p>")

			if back_uri
				html.gsub!(/<!--BACK_LINK-->/, "<p><a href=\"#{back_uri}\">戻る</a></p>")
			else
				html.gsub!(/<!--BACK_LINK-->/, '')
			end

			return html
		end
	end
end
