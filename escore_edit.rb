#!/usr/local/bin/ruby -Ku
#***************************************************************
#	GFDMmix for CS - Event Data Edit
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#***************************************************************
$LOAD_PATH << 'lib'

require 'cgi'
require 'util'
require 'gfdmmix/util'
require 'gfdmmix/session'
require 'gfdmmix/escore_form'

begin
	cgi = CGI.new
	session = GfDmMix::UserSession.new(cgi)

	# セッションが生きていなければ、エラーを出して終了
	unless session.alive?
		print respond_to_http_request(cgi, GfDmMix::UserSessionExecutor.new(cgi, session))
		exit
	end

	html = ''

	case cgi.request_method.downcase
	when 'get'				# 編集フォーム立ち上げ
		session.clear_work_area
		s_edit = GfDmMix::EscoreEditFormMaker.new(cgi, sp_access?(cgi), session)
		html << s_edit.to_html

	when 'post'				# 編集内容登録確認/実行
		s_reg = GfDmMix::EscoreRegister.new(cgi, sp_access?(cgi), session)
		s_reg.execute
		html << s_reg.to_html
	end

	print cgi.header(GfDmMix::DEFAULT_HTTP_HEADER_HASH)
	print html
rescue
	print write_backtrace_for_cgi
end
