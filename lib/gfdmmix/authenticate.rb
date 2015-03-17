#---------------------------------------------------------------
#	GFDMmix for CS - Library for Authentication
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'inifile'
require 'gfdmmix/util'
require 'gfdmmix/session'			# ユーザ認証クラスを含んでいるためにロードしている
require 'gfdmmix/pagemaker'
require 'gfdmmix/user_database'

module GfDmMix
	# 一般ユーザの認証を行うクラス
	class UserAuthenticator < PageMaker
		def initialize(cgi)
			@cgi = cgi
		end

		def to_html
			uid = @cgi['uid']
			password = @cgi['password']

			# 与えられたパラメータを検査して、エラーならメッセージを出して終了
			error_no = validate_params(uid, password)
			if error_no != NO_ERROR
				return make_error_page(error_no, SITE_TOP_PROGRAM)
			end

			# ユーザ情報を取得して、それをもってユーザセッションを初期化する
			user = UserDatabase.get(uid)
			session = UserSession.new(@cgi, user)
			session.close					# 特に何かをするわけでもないので、すぐに閉じておく

			# 戻り値は、ログイン直後に移動するページを指すURIとする
			return SKILL_LIST_EDIT_PROGRAM
		end

		private
		def validate_params(uid, password)
			# エラー: ユーザIDが入力されていない
			if uid.empty?
				return ERROR_USERID_IS_UNINPUTED
			end
			# エラー: パスワードが入力されていない
			if password.empty?
				return ERROR_PASSWORD1_IS_UNINPUTED
			end

			# ユーザ情報をデータベースから取得する
			user = UserDatabase.get(uid)

			# エラー: 入力されたIDに相当するユーザが存在しない
			unless user
				return ERROR_USERID_OR_PASS_IS_WRONG
			end
			# エラー: 入力されたパスワードが登録されているものと一致しない
			if user.password != password
				return ERROR_USERID_OR_PASS_IS_WRONG
			end

			return NO_ERROR
		end
	end
end
