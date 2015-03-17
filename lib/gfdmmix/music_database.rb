#---------------------------------------------------------------
#	GFDMmix for CS - Library for Music Data
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'time'
require 'gfdmmix/util'
require 'gfdmmix/database'

module GfDmMix
	class MusicDatabase < Database
		def initialize
			@db = connect_db
		end

		def mtime
			query = "select max(updated_at) from musics;"

			return Time.parse(get_datetime_string_by_query(@db, query))
		end
		alias get_last_modified mtime

		def exist?(text_id)
			query = "select count(*) from musics where text_id = '#{text_id}';"

			return get_count_by_query(@db, query) > 0
		end
		alias include? exist?

		def get(text_id)
			return nil unless exist?(text_id)

			query = ''
			query << 'select musics.* from musics '
			query << "where musics.text_id = '#{text_id}';"
			result = @db.query(query)
			hash = result.fetch_hash(true)
			music = MusicItem.make_from_result_hash(hash)

			return music
		end

		def get_by_mid(mid)
			query = ''
			query << 'select musics.* from musics '
			query << "where musics.id = #{mid};"
			result = @db.query(query)
			hash = result.fetch_hash(true)
			music = MusicItem.make_from_result_hash(hash)

			return music
		end

		def get_all_music
			musics = Array.new

			query = ''
			query << 'select * from musics;'
			result = @db.query(query)
			result.each_hash(true) do |hash|
				musics << MusicItem.make_from_result_hash(hash)
			end

			return musics
		end
	end

	class MusicItem
		include Comparable
		include Util
		include DatabaseUtil
		attr_reader :mid, :number, :title, :text_id, :sortkey

		def initialize(mid, text_id, number,
			title, sortkey, level_hash, notes_hash, monthly, limited)
			@mid = mid
			@text_id = text_id
			@number = number
			@title = title
			@sortkey = sortkey
			@level_hash = level_hash
			@notes_hash = notes_hash
			@monthly = monthly
			@limited = limited
		end

		def MusicItem.make_from_result_hash(hash)
			level_hash = {
				MUSIC_DIFF_BSC => hash['musics.std_lv'].to_f,
				MUSIC_DIFF_ADV => hash['musics.hrd_lv'].to_f,
				MUSIC_DIFF_EXT => hash['musics.mas_lv'].to_f,
			}
			notes_hash = {
				MUSIC_DIFF_BSC => hash['musics.std_notes'].to_i,
				MUSIC_DIFF_ADV => hash['musics.hrd_notes'].to_i,
				MUSIC_DIFF_EXT => hash['musics.mas_notes'].to_i,
			}

			return MusicItem.new(
				hash['musics.id'].to_i, hash['musics.text_id'], hash['musics.number'].to_i,
				hash['musics.title'], hash['musics.sortkey'], level_hash, notes_hash,
				hash['musics.monthly'].to_i, hash['musics.limited'].to_i)
		end

		def level(diff)
			return @level_hash[diff]
		end

		def notes(diff)
			return @notes_hash[diff]
		end

		# 今月の曲
		def monthly?
			return @monthly == 1
		end

		# 期間限定曲
		def limited?
			return @limited == 1
		end

		def <=>(other)
			return @sortkey <=> other.sortkey
		end
	end
end
