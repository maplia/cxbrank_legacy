#!/usr/local/bin/ruby -Ku
#***************************************************************
#	GFDMmix for CS - User Edit
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#***************************************************************
$LOAD_PATH << 'lib'

require 'cgi'
require 'util'
require 'gfdmmix/util'
require 'gfdmmix/session'
require 'gfdmmix/user_form'

begin
	cgi = CGI.new
	session = GfDmMix::UserSession.new(cgi)

	# セッションが生きていなければ、エラーを出して終了
	unless session.alive?
		print respond_to_http_request(cgi, GfDmMix::UserSessionExecutor.new(cgi, session))
		exit
	end

	case cgi.request_method.downcase
	when 'get'
		# ユーザー登録フォーム立ち上げ
		u_edit = GfDmMix::UserEditFormMaker.new(cgi, sp_access?(cgi), session)
	when 'post'				# ユーザー登録確認/実行
		if cgi['y'].empty? and cgi['n'].empty?
			# 登録内容確認（登録フォームで入力された内容を表示する）
			u_edit = GfDmMix::UserCertifier.new(cgi, sp_access?(cgi), session)
		elsif cgi['n'].size > 0
			# 再編集（登録内容確認で「いいえ」が押された場合）
			u_edit = GfDmMix::UserEditFormMaker.new(cgi, sp_access?(cgi), session)
		else
			# 編集内容確定（データベースへの書き込みを行う）
			u_edit = GfDmMix::UserRegistrar.new(cgi, sp_access?(cgi), session)
		end
	end

	print respond_to_http_request(cgi, u_edit)
rescue
	print write_backtrace_for_cgi
end
