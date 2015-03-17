#---------------------------------------------------------------
#	GFDMmix for CS - Library for User Data
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'mysql'
require 'util'
require 'gfdmmix/util'
require 'gfdmmix/database'

module GfDmMix
	class UserDatabase < Database
		def UserDatabase.mtime(uid)
			u_db = UserDatabase.new
			mtime = u_db.mtime(uid)
			u_db.close

			return mtime
		end

		def UserDatabase.register?(uid)
			u_db = UserDatabase.new
			registered = u_db.register?(uid)
			u_db.close

			return registered
		end

		def UserDatabase.get(uid)
			u_db = UserDatabase.new
			user = u_db.get(uid)
			u_db.close

			return user
		end

		def mtime(uid)
			query = "select mtime from users where id = #{uid.to_i};"

			return get_time_by_query(@db, query)
		end
		alias get_last_modified mtime

		def register?(uid)
			query = "select count(*) from users where id = #{uid.to_i};"

			return get_count_by_query(@db, query) > 0
		end
		alias exist? register?

		def get(uid)
			return nil unless register?(uid)

			result = @db.query("select * from users where id = #{uid.to_i};")
			hash = result.fetch_hash(true)

			return make_user_item_from_result_hash(hash)
		end

		def get_all_user
			users = Array.new

			result = @db.query("select * from users;")
			result.each_hash(true) do |hash|
				users << make_user_item_from_result_hash(hash)
			end

			return users
		end

		def edit(user)
			datetime_string = get_now_datetime_string(@db)			# ctime/mtimeの値とする

			# 新規レコード登録時の前処理
			unless register?(user.uid)
				query = user.make_insert_dummy_query(datetime_string)
				@db.query(query)
				uid = make_uid_from_id(@db.insert_id)
			else
				uid = user.uid
			end

			# usersレコードの本登録
			query = user.make_update_query(uid, datetime_string)
			@db.query(query)

			return uid
		end

		def save_skill_point(user, skill_point, mtime)
			datetime_string = get_now_datetime_string(@db)

			query = ''
			query << 'update users '
			query << "set rp = #{skill_point}, "
			if mtime.nil? or mtime.year == 1970
				query << "  rp_mtime = NULL, "
			else
				query << "  rp_mtime = '#{mtime.strftime("%Y-%m-%d %T")}', "
			end
			query << "  mtime = '#{datetime_string}' "
			query << "where id = #{user.uid.to_i};"
			@db.query(query)
		end

		private
		# データベースから返ってきた1行の結果セットから、UserItemのインスタンスを生成する
		def make_user_item_from_result_hash(hash)
			uid = make_uid_from_id(hash['users.id'].to_i)

			return UserItem.new(uid, hash['users.name'],
				hash['users.password'], hash['users.password'],
				hash['users.cxbid'], hash['users.comment'],
				hash['users.rp'].to_f,
				(hash['users.rp_mtime'] ? Time.parse(hash['users.rp_mtime']) : nil))
		end

		def make_uid_from_id(id)
			return sprintf("%0*d", USER_ID_FIGURE, id)
		end
	end

	class UserItem
		include DatabaseUtil
		include Comparable
		attr_reader :uid, :name, :password, :address, :input_type, :comment, :rp, :rp_mtime, :cxbid

		def initialize(uid, name, password1, password2, cxbid, comment, rp, rp_mtime)
			@uid = uid
			@name = name
			@password1 = password1
			@password2 = password2
			@password = password1
			@cxbid = cxbid
			@comment = comment
			@rp = rp
			@rp_mtime = rp_mtime
		end

		# 新規登録用に空のユーザデータを作成する
		def UserItem.make_empty_item
			return UserItem.new('', '', '', '', '', '', 0.0, nil)
		end

		def validate
			# エラー: ユーザ名の値がない場合
			if @name.empty?
				return ERROR_USERNAME_IS_UNINPUTED
			end
			# エラー: パスワードの値がない場合
			if @password1.empty?
				return ERROR_PASSWORD1_IS_UNINPUTED
			end
			# エラー: 確認用パスワードの値がない場合
			if @password2.empty?
				return ERROR_PASSWORD2_IS_UNINPUTED
			end
			# エラー: パスワードの値が確認用のものと一致しない場合
			if @password1 != @password2
				return ERROR_PASSWORDS_ARE_NOT_EQUAL
			end

			return NO_ERROR
		end

		def score_enable?
			return @uid == '00002'
		end
		
		def make_insert_dummy_query(datetime_string)
			query = "insert into users (ctime) values ('#{datetime_string}');"

			return query
		end

		def make_update_query(uid, datetime_string)
			query = ''

			query << 'update users '
			query << 'set '
			query << " name = '#{quote(@name)}', password = '#{quote(@password)}', "
			query << " cxbid = '#{quote(@cxbid)}', comment = '#{quote(@comment)}',"
			query << " mtime = '#{datetime_string}' "
			query << "where id = #{uid.to_i};"

			return query
		end

		def <=>(other)
			return (@rp_mtime || Time.parse('1970-01-01')) <=> (other.rp_mtime || Time.parse('1970-01-01'))
		end
	end
end
