#---------------------------------------------------------------
#	GFDMmix for CS - Base Library to Validate Parameter
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'gfdmmix/util'
require 'gfdmmix/user_database'
require 'gfdmmix/music_database'

module GfDmMix
	module Validate
		# ユーザID指定のパラメータチェック
		def validate_uid_param(uid)
			# エラー: ユーザIDが入力されていない
			if uid.empty?
				return ERROR_USERID_IS_UNINPUTED
			end
			# エラー: 指定されたIDのユーザが登録されていない
			unless UserDatabase.register?(uid)
				return ERROR_USERID_IS_UNREGISTERED
			end

			return NO_ERROR
		end

		# 曲ID指定のパラメータチェック
		# 指定の際に省略可能な場合はomitableにtrueを渡すこと
		def validate_mid_param(mid, omitable=false)
			# 曲ID指定を省略可能で、かつ曲ID指定が与えられていない場合は無条件でOK
			if omitable and mid.empty?
				return NO_ERROR
			end

			# エラー: 曲IDが指定されていない場合
			if mid.empty?
				return ERROR_MUSIC_IS_UNDECIDED
			end
			# エラー: 指定された曲IDに相当する曲情報が存在しない
			m_db = MusicDatabase.new
			registered = m_db.exist?(mid)
			m_db.close
			unless registered
				return ERROR_MUSIC_NOT_EXIST
			end

			return NO_ERROR
		end

		# モード指定のパラメータチェック
		# 指定の際に省略可能な場合はomitableにtrueを渡すこと
		def validate_mode_param(mode, omitable=false)
			# モード指定を省略可能で、かつモード指定が与えられていない場合は無条件でOK
			if omitable and mode.empty?
				return NO_ERROR
			end

			# エラー: モードが指定されていない場合
			if mode.empty?
				return ERROR_MODE_IS_UNDECIDED
			end
			# エラー: モード指定が想定外の値である場合
			unless MODES.include?(mode)
				return ERROR_MODE_IS_WRONG
			end

			return NO_ERROR
		end

		# バージョン指定のパラメータチェック
		def validate_rule_param(rule, edit=false)
			# 曲情報編集用かどうかで、受け入れる値の範囲を変える
			rules = (edit ? VERSIONS_FOR_EDIT : VERSIONS)

			# エラー: バージョンが指定されていない場合
			if rule.empty?
				return ERROR_VERSION_IS_UNDECIDED
			end
			# エラー: バージョン指定が想定外の場合
			unless rules.include?(rule)
				return ERROR_VERSION_NOT_EXIST
			end

			return NO_ERROR
		end
	end
end
