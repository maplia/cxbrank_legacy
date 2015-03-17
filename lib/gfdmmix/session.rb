#---------------------------------------------------------------
#	GFDMmix for CS - Session Class Definition
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'cgi'
require 'cgi/session'
require 'cgi/session/pstore'
require 'gfdmmix/util'
require 'gfdmmix/pagemaker'
require 'gfdmmix/user_database'
require 'gfdmmix/music_database'
require 'gfdmmix/skill_database'

module GfDmMix
	# セッション管理クラスのベースクラス
	class BaseSession
		# セッション変数へのアクセサ
		def [](key)
			return @session[key]
		end
		def []=(key, value)
			return @session[key] = value
		end

		# セッションを閉じる
		def close
			@session.close
		end

		# セッションを終了する
		def delete
			@session.delete
		end
	end

	# ユーザのセッションを保持するクラス
	# CGI::Sessionとはhas-aの関係で、インスタンス変数で保持しておくことにする
	class UserSession < BaseSession
		# 最初のセッション作成時（ログインか新規ユーザ作成）には、必ずuserに値を渡すこと
		def initialize(cgi, user=nil)
			session_hash = {
				'database_manager' => CGI::Session::PStore,
				'session_expires' => Time.now + EXPIRE_MINUTES*60		# Timeにnを足すとn秒進む
			}
			@session = CGI::Session.new(cgi, session_hash)

			# userに値が渡されている場合に、その値でセッション変数を設定
			if user
				@session['user'] = user
			end
		end

		# セッションを実行しているユーザの情報を取得するためのバイパス
		def get_user
			return @session['user']
		end

		# スキル編集の際に使用するセッションデータ領域をクリアする
		def clear_work_area
			@session['music'] = nil
			@session['skill'] = nil
			@session['old_skill'] = nil
		end

		# ユーザのセッションが生きているかどうかを返す
		# 最初のセッション作成時に設定したセッション変数が有効かどうかで判断する
		def alive?
			return (not @session['user'].nil?)
		end
	end

	class UserSessionExecutor < PageMaker
		def initialize(cgi, session)
			@cgi = cgi
			@session = session
			@start_page_uri = SITE_TOP_PROGRAM
		end

		def to_html
			return make_error_page(ERROR_SESSION_IS_DEAD, @start_page_uri)
		end
	end

	class UserSessionTerminator < UserSessionExecutor
		def to_html
			@session.delete

			return make_error_page(ERROR_SESSION_IS_FINISHED, @start_page_uri)
		end
	end

	# ユーザ新規登録時のセッションを保持するクラス
	class UserAddSession < BaseSession
		# 最初のセッション作成時には、必ずfirstにtrueを渡すこと
		def initialize(cgi, first=false)
			session_hash = {
				'session_key' => '_user_add_session_id',
				'database_manager' => CGI::Session::PStore,
				'session_expires' => Time.now + EXPIRE_MINUTES*60		# Timeにnを足すとn秒進む
			}
			@session = CGI::Session.new(cgi, session_hash)

			# firstに値が渡されている場合に、その値でセッション変数を設定
			if first
				@session['alive'] = true				# 値自体には特に意味はない
			end
		end

		# ユーザのセッションが生きているかどうかを返す
		# 最初のセッション作成時に設定したセッション変数が有効かどうかで判断する
		def alive?
			return (not @session['alive'].nil?)
		end
	end

	class UserAddSessionExecutor < UserSessionExecutor
		def initialize(cgi, session)
			@cgi = cgi
			@session = session
			@start_page_uri = USER_ADD_PROGRAM
		end
	end

	# 管理者ユーザのセッションを保持するクラス
	class AdminSession < BaseSession
		# 最初のセッション作成時（ログイン）には、必ずfirstにtrueを渡すこと
		def initialize(cgi, first=false)
			session_hash = {
				'session_key' => '_admin_session_id',
				'database_manager' => CGI::Session::PStore,
				'session_expires' => Time.now + EXPIRE_MINUTES*60		# Timeにnを足すとn秒進む
			}
			@session = CGI::Session.new(cgi, session_hash)

			# firstに値が渡されている場合に、その値でセッション変数を設定
			if first
				@session['alive'] = true				# 値自体には特に意味はない
			end
		end

		def clear_work_area
			@session['music'] = nil
		end

		# ユーザのセッションが生きているかどうかを返す
		# 最初のセッション作成時に設定したセッション変数が有効かどうかで判断する
		def alive?
			return (not @session['alive'].nil?)
		end
	end

	class AdminSessionExecutor < UserSessionExecutor
		def initialize(cgi, session)
			@cgi = cgi
			@session = session
			@start_page_uri = ADMIN_TOP_PROGRAM
		end
	end

	class AdminSessionTerminator < AdminSessionExecutor
		def to_html
			@session.delete

			return make_error_page(ERROR_SESSION_IS_FINISHED, @start_page_uri)
		end
	end
end
