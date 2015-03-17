#---------------------------------------------------------------
#	GFDMmix for CS - Database Accessor Base Class
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'mysql'
require 'inifile'
require 'util'
require 'gfdmmix/util'

module GfDmMix
	class Database
		def initialize
			@db = connect_db
		end

		def close
			@db.close
		end

		private
		def connect_db
			ini = IniFile.new(CONFIGURATION_FILE)

			if server_host?
				host = ini['mysql']['host_gfdmmix'].untaint
			else
				host = ini['mysql']['host_sunrise'].untaint
			end
			user = ini['mysql']['user']
			password = ini['mysql']['password']
			database = ini['mysql']['database']

			# サーバマシンかテストマシンかで、接続の際のメソッド呼び出し方法を変える
			# （さくらのレンタルサーバのMySQLのバージョンが古いため）
#			if server_host?
#				db = Mysql.new(host, user, password, database)
#			else
				db = Mysql.new(host, user, password)
				db.query('set character set utf8;')
				db.query("use #{database};")
#			end

			return db
		end

		def server_host?
			# gfdmmix/utilにあるべきかもしんない
			return ENV['HTTP_HOST'] != 'sunrise.maplia.jp'
		end

		# SQL文に使えない文字をエスケープする
		def escape_string(string)
			# MySQL/Rubyで用意されているメソッドを適用できないので、メソッドを自前で実装
			return string.gsub(/'/, "''")
		end
		alias quote escape_string

		# SQL発行によりサーバの現在時刻を取得する
		# insert/updateのSQL文での使用が目的である都合上、TimeではなくStringで取得する
		def get_now_datetime_string(db)
			return get_datetime_string_by_query(db, 'select now();')
		end

		# SQL発行により時刻を表す文字列を取得する
		# Time型の値が欲しい場合は、呼び出し元でパースすること
		def get_datetime_string_by_query(db, query)
			# もしクエリで値が得られなかった場合は、時刻0の値を返しておく
			result = db.query(query)
			time_string = coalesce(result.fetch_row[0], '1970-01-01')

			return time_string
		end

		# count(*)を含むSQL発行によりその結果の値を取得する
		def get_count_by_query(db, query)
			result = db.query(query)
			count = result.fetch_row[0].to_i

			return count
		end
	end

	module DatabaseUtil
		# SQL文に使えない文字をエスケープする
		def escape_string(string)
			# MySQL/Rubyで用意されているメソッドを適用できないので、メソッドを自前で実装
			return string.gsub(/'/, "''")
		end
		alias quote escape_string
		alias escape escape_string
	end
end
