#---------------------------------------------------------------
#	GFDMmix for CS - Library for Menu View
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'erb'
require 'gfdmmix/util'
require 'gfdmmix/pagemaker'

module GfDmMix
	class SiteTopMaker < PageMaker
		def initialize(cgi, mobile)
			@cgi = cgi
			@mobile = mobile
			if mobile
				@template_html = 'template/mobile/index.html.erb'
			else
				@template_html = 'template/index.html.erb'
			end
		end

		def get_last_modified
			return Time.now
		end

		def to_html
			html = read_template_html

			html.gsub!(/<!--PRESET_USER_LOGIN_URI-->/, USER_LOGIN_PROGRAM)
			html.gsub!(/<!--PRESET_USER_ADD_URI-->/, USER_ADD_PROGRAM)
			html.gsub!(/<!--PRESET_USER_ID_FIGURE-->/, USER_ID_FIGURE.to_s)
			html.gsub!(/<!--PRESET_DEMO_USER_ID-->/, DEMO_USER_ID)
			html.gsub!(/<!--PRESET_DEMO_USER_PASSWORD-->/, DEMO_USER_PASSWORD)

			return ERB.new(html).result(binding)
		end

		private
		# バージョン別の曲リストへのリンクを作成する（サイトトップ用）
		def make_top_music_link_html
			html = ''

			return html
		end

		# 計算規則別の総合スキル表用曲リストへのリンクを作成する（サイトトップ用）
		def make_top_music_mix_link_html
			html = ''

			return html
		end

		# 指定されたユーザのスキル表へのリンクを作成する（サイトトップ用）
		def make_top_skill_link_html(uid)
			html = ''

			return html
		end
	end

	# ログインフォームだけを表示させるトップページ
	# 通常のトップページの一部しか表示しないので、テンプレートだけの差し替えで済ませる
	class SiteTopMakerForLogin < SiteTopMaker
		def initialize(cgi)
			@cgi = cgi
			@template_html = 'template/login.html'
		end
	end

	class AdminSiteTopMaker < PageMaker
		def initialize(cgi)
			@cgi = cgi
			@template_html = 'template/admin.html'
		end

		def to_html
			html = read_template_html(true)

			html.gsub!(/<!--PRESET_ADMIN_LOGIN_URI-->/, ADMIN_LOGIN_PROGRAM)

			return html
		end
	end

	class AdminMenuMaker < PageMaker
		def initialize(cgi, session)
			@cgi = cgi
			@session = session
			@template_html = 'template/admin_menu.html'
		end

		def to_html
			html = read_template_html(true)

			html.gsub!(/<!--PRESET_ADMIN_TOP_URI-->/, ADMIN_TOP_PROGRAM)
			html.gsub!(/<!--PRESET_ADMIN_LOGOUT_URI-->/, ADMIN_LOGOUT_PROGRAM)
			html.gsub!(/<!--PRESET_MUSIC_EDIT_LINKS-->/, GfDmMix::make_music_edit_link_html)

			return html
		end
	end
end
