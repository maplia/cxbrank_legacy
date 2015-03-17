#---------------------------------------------------------------
#	GFDMmix for CS - Library for Skill Data (Sub)
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'mysql'
require 'util'
require 'gfdmmix/util'
require 'gfdmmix/database'
require 'gfdmmix/user_database'
require 'gfdmmix/music_database'

module GfDmMix
	class SkillPointMapDatabase < Database
		def get(user)
			return SkillPointMapItem.new(user)
		end
	end

	class SkillSheetDatabase < Database
		def SkillSheetDatabase.register?(user, mode, rule)
			ss_db = SkillSheetDatabase.new
			registered = ss_db.register?(user, mode, rule)
			ss_db.close

			return registered
		end

		def SkillSheetDatabase.get(user, mode, rule)
			ss_db = SkillSheetDatabase.new
			ssi = ss_db.get(user, mode, rule)
			ss_db.close

			return ssi
		end

		def register?(user, mode, rule)
			query = ''
			query << 'select count(*) from sheets '
			query << "where user_id = #{user.uid.to_i} "
			query << " and mode = '#{mode}' and rule = '#{rule}';"

			return get_count_by_query(@db, query) > 0
		end

		def get(user, mode, rule)
			if register?(user, mode, rule)
				query = ''
				query << 'select comment from sheets '
				query << "where user_id = #{user.uid.to_i} "
				query << " and mode = '#{mode}' and rule = '#{rule}';"
				result = @db.query(query)
				hash = result.fetch_hash(true)

				return SkillSheetItem.make_item_from_result_hash(user, mode, rule, hash)
			else
				return SkillSheetItem.make_empty_item(user, mode, rule)
			end
		end

		def edit(user, mode, rule, ssi)
			datetime_string = get_now_datetime_string(@db)			# ctime/mtimeの値とする

			# 編集しようとするデータのレコードがデータベースに未登録の場合、ダミーを新規作成
			unless register?(user, mode, rule)
				@db.query(ssi.make_insert_dummy_query(datetime_string))
			end

			# sheetsレコードの本登録
			@db.query(ssi.make_update_query(datetime_string))
		end
	end

	class SkillPointMapItem
		def initialize(user)
			@user = user
		end
	end

	class SkillSheetItem
		include DatabaseUtil

		def initialize(user, mode, rule, real_point, calc_point, comment)
			@user = user
			@mode = mode
			@rule = rule
			@real_point = real_point
			@calc_point = calc_point
			@comment = comment
		end

		def SkillSheetItem.make_empty_item(user, mode, rule)
			return SkillSheetItem.new(user, mode, rule, 0.0, 0.0, '')
		end

		def SkillSheetItem.make_item_from_result_hash(user, mode, rule, hash)
			return SkillSheetItem.new(user, mode, rule,
				hash['sheets.real_point'], hash['sheets.calc_point'], hash['sheets.comment'])
		end

		def make_insert_dummy_query(datetime_string)
			query = ''

			query << 'insert into sheets (user_id, mode, rule, ctime) '
			query << "values (#{@user.uid.to_i}, '#{@mode}', '#{@rule}', '#{datetime_string}');"

			return query
		end

		def make_update_query(datetime_string)
			query = ''

			query << 'update sheets '
			query << "set "
			query << " real_point = '#{sprintf("%.2f", @real_point)}', "
			query << " calc_point = '#{sprintf("%.2f", @calc_point)}', "
			query << " comment = '#{quote(@comment)}', mtime = '#{datetime_string}' "
			query << "where user_id = #{@user.uid.to_i} "
			query << " and mode = '#{@mode}' and rule = '#{@rule}';"

			return query
		end
	end
end
