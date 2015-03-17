#---------------------------------------------------------------
#	GFDMmix for CS - Library to Validate Skill Parameters
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'gfdmmix/util'
require 'gfdmmix/validate'

module GfDmMix
	module SkillValidate
		include Validate

		# スキル表用のパラメータチェック
		def validate_params_for_skill_list(user, mode, rule)
			# 総合スキル表のチェックと重なる部分は、その関数を呼び出すことで済ませる
			error_no = validate_params_for_skill_mix_list(user, mode)
			if error_no != NO_ERROR
				return error_no
			end
			# バージョン指定のパラメータチェック
			error_no = validate_rule_param(rule)
			if error_no != NO_ERROR
				return error_no
			end
			# エラー: 指定されたバージョンがユーザに非表示とされている場合
			unless user.active_version?(rule)
				return ERROR_VERSION_IS_INACTIVE
			end

			return NO_ERROR
		end

		# スキル編集用のパラメータチェック
		def validate_params_for_skill_form(mid)
			# 曲ID指定のパラメータチェック
			error_no = validate_mid_param(mid)
			if error_no != NO_ERROR
				return error_no
			end

			return NO_ERROR
		end
	end
end
