#---------------------------------------------------------------
#	GFDMmix for CS - Library for User Data Form
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'cgi'
require 'erb'
require 'util'
require 'gfdmmix/util'
require 'gfdmmix/session'
require 'gfdmmix/pagemaker'
require 'gfdmmix/user_database'

module GfDmMix
	class UserEditFormMaker < PageMaker
		def initialize(cgi, mobile, session)
			@cgi = cgi
			@mobile = mobile
			@session = session
			if session.kind_of?(UserSession)
				if @mobile
					@template_html = 'template/mobile/user_edit.html.erb'
				else
					@template_html = 'template/user_edit.html.erb'
				end
			else
				if @mobile
					@template_html = 'template/mobile/user_add.html.erb'
				else
					@template_html = 'template/user_add.html.erb'
				end
			end
		end

		def to_html
			# ユーザ情報の初期値を取得する
			if @session.kind_of?(UserSession)
				# ユーザ情報編集の場合
				if @session['temp_user']
					# 前のセッションから入力値を引き継いでいる場合はそれを初期表示とする
					# ↑登録確認画面で「いいえ」が選択された場合
					user = @session['temp_user']
				else
					# 引き継ぎ値がない場合は現在のセッション情報にあるユーザ情報を初期値として扱う
					user = @session.get_user
					@session['temp_user'] = user
				end
			else
				# ユーザ新規登録の場合
				if @session['temp_user']
					# 前のセッションから入力値を引き継いでいる場合はそれを初期表示とする
					# ↑登録確認画面で「いいえ」が選択された場合
					user = @session['temp_user']
				else
					# セッション自体がない場合（ユーザ新規登録の初回）、空データを初期値に
					# そして、新たにユーザ追加セッションを再起動させておく
					user = UserItem.make_empty_item
					@session.delete
					@session = UserAddSession.new(@cgi, true)
					@session.close
				end
			end

			html = ERB.new(read_template_html(false)).result(binding)

			if @session.kind_of?(UserSession)
				html.gsub!(/<!--PRESET_USER_EDIT_URI-->/, USER_EDIT_PROGRAM)
				html.gsub!(/<!--PRESET_USER_MENU_URI-->/, SKILL_LIST_EDIT_PROGRAM)
			else
				html.gsub!(/<!--PRESET_USER_EDIT_URI-->/, USER_ADD_PROGRAM)
			end
			html.gsub!(/<!--PRESET_USER_EDIT_FORM-->/, user.to_html)
			html.gsub!(/<!--PRESET_SUBMIT_TABINDEX-->/, 70.to_s)
			html.gsub!(/<!--PRESET_RESET_TABINDEX-->/, 80.to_s)

			return html
		end
	end

	class UserCertifier < PageMaker
		def initialize(cgi, mobile, session)
			@cgi = cgi
			@mobile = mobile
			@session = session
			if session.kind_of?(UserSession)
				if mobile
					@template_html = 'template/mobile/user_edit_conf.html.erb'
				else
					@template_html = 'template/user_edit_conf.html.erb'
				end
			else
				if mobile
					@template_html = 'template/mobile/user_add_conf.html.erb'
				else
					@template_html = 'template/user_add_conf.html.erb'
				end
			end
		end

		def to_html
			# フォームの入力からUserItemを作成する
			# ユーザIDだけはフォームから入力されないので、セッション情報から取得したものを使う
			uid = (@session.respond_to?(:get_user) ? @session.get_user.uid : '')
			user = UserItem.make_item_from_cgi_params(uid, @cgi)
			@session['temp_user'] = user

			error_no = user.validate
			if error_no != NO_ERROR
				return make_error_page(error_no, @cgi.script_name)
			end

			html = ERB.new(read_template_html(false)).result(binding)

			if @session.kind_of?(UserSession)
				html.gsub!(/<!--PRESET_USER_EDIT_URI-->/, USER_EDIT_PROGRAM)
				html.gsub!(/<!--PRESET_USER_MENU_URI-->/, SKILL_LIST_EDIT_PROGRAM)
			else
				html.gsub!(/<!--PRESET_USER_EDIT_URI-->/, USER_ADD_PROGRAM)
			end
			html.gsub!(/<!--PRESET_USER_INFO-->/, user.to_html_confirm)

			return html
		end
	end

	class UserRegistrar < PageMaker
		def initialize(cgi, mobile, session)
			@cgi = cgi
			@mobile = mobile
			@session = session
			if mobile
				@template_html = 'template/mobile/user_add_result.html.erb'		# 新規追加時のみ適用
			else
				@template_html = 'template/user_add_result.html.erb'		# 新規追加時のみ適用
			end
		end

		def to_html
			user = @session['temp_user']

			unless user.validate == NO_ERROR
				return ERROR_INVALID_ACCESS
			end

			# 入力された内容をデータベースに登録して、それを再取得する
			u_db = UserDatabase.new
			edited_uid = u_db.edit(user)
			user = u_db.get(edited_uid)
			u_db.close

			# セッションの種類で処理分岐させる
			if @session.kind_of?(UserSession)
				# セッションがある場合は、それをいったん閉じて、新ユーザ情報で再初期化
				@session.close
				@session = UserSession.new(@cgi, user)
				@session.close				# んで、また閉じる

				# 出力内容はユーザメニューのURI
				html = SKILL_LIST_EDIT_PROGRAM
			else
				#
				session = UserSession.new(@cgi, user)
				session.close					# 特に何もしないので閉じておく

				html = ERB.new(read_template_html(false)).result(binding)
				html.gsub!(/<!--PRESET_USER_ID-->/, user.uid)
				html.gsub!(/<!--PRESET_SKILL_EDIT_URI-->/, SKILL_LIST_EDIT_PROGRAM.gsub(/\.rb/, ''))
			end
			# データベースへの保存が終わったので、作業用のユーザ情報は削除する
			@session['temp_user'] = nil

			return html
		end
	end

	class UserItem
		def UserItem.make_item_from_cgi_params(uid, cgi)
			if cgi.params.empty?
				# CGIのパラメータに値がない場合は、CGI経由でのユーザ情報の入力はないとみなす
				return nil
			else
				return UserItem.new(uid, cgi['name'], cgi['password1'], cgi['password2'],
					cgi['cxbid'], normalize_textarea_data(cgi['comment']), 0.0, nil)
			end
		end

		def to_html
			html = ''
			tabindex = 1

			html << '<dl>'
			unless @uid.empty?			# 以下、uidが空文字列だと新規ユーザ登録とみなす
				html << '<dt>ユーザーID</dt>'
				html << "<dd><p>#{@uid}</p></dd>"
			end
			html << '<dt>ユーザー名 <em>*</em>（文字種の制限はありません。全角文字OKです）</dt>'
			html << '<dd>'
			html << '<input type="text" name="name" size="30" maxlength="30"'
			html << " value=\"#{CGI.escapeHTML(@name)}\" tabindex=\"#{tabindex}\""
			html << '></dd>'
			tabindex += 1
			html << '<dt>パスワード <em>*</em></dt>'
			html << '<dd>'
			html << '<input type="password" name="password1" size="20" maxlength="50"'
			html << " value=\"#{CGI.escapeHTML(@password1)}\" tabindex=\"#{tabindex}\""
			html << '></dd>'
			tabindex += 1
			html << '<dt>パスワード（確認用）<em>*</em></dt>'
			html << '<dd>'
			html << '<input type="password" name="password2" size="20" maxlength="50"'
			html << " value=\"#{CGI.escapeHTML(@password2)}\" tabindex=\"#{tabindex}\""
			html << '></dd>'
			tabindex += 1
			html << '<dt>CROSS&times;BEAT ID</dt>'
			html << '<dd>'
			html << '<input type="text" name="cxbid" size="8" maxlength="8"'
			html << " value=\"#{CGI.escapeHTML(@cxbid)}\" tabindex=\"#{tabindex}\""
			html << '></dd>'
			tabindex += 1
			html << '<dt>ユーザーコメント（HTMLタグによる文字装飾はできません。URLには自動的にリンクが設定されます）</dt>'
			html << '<dd>'
			html << '<textarea name="comment" rows="6" cols="70"'
			html << " tabindex=\"#{tabindex}\">"
			html << CGI.escapeHTML(@comment)
			html << '</textarea></dd>'
			tabindex += 1
			html << '</dl>'

			return html
		end

		def to_html_confirm
			html = ''

			html << '<table class="info">'
			unless @uid.empty?		# 編集フォーム同様、uidが空文字列だと新規ユーザ登録とみなす
				html << '<tr>'
				html << '<th>ユーザーID</th>'
				html << "<td>#{@uid}</td>"
				html << '</tr>'
			end
			html << '<tr>'
			html << '<th>ユーザー名</th>'
			html << "<td>#{CGI.escapeHTML(@name)}</td>"
			html << '</tr>'
			html << '<tr>'
			html << '<th>パスワード</th>'
			html << "<td>#{'*' * @password.size}</td>"
			html << '</tr>'
			html << '<tr>'
			html << '<th>CROSS&times;BEATS ID</th>'
			if @cxbid.empty?
				html << '<td>入力なし</td>'
			else
				html << "<td>#{CGI.escapeHTML(@cxbid)}</td>"
			end
			html << '</tr>'
			html << '<tr>'
			html << '<th>ユーザーコメント</th>'
			if @comment.empty?
				html << '<td>入力なし</td>'
			else
				html << "<td>#{textarea_data_to_html(CGI.escapeHTML(@comment))}</td>"
			end
			html << '</tr>'
			html << '</table>'

			return html
		end
	end
end
