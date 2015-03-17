#---------------------------------------------------------------
#	GFDMmix for CS - Library for Event Data
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'time'
require 'parsedate'
require 'gfdmmix/util'
require 'gfdmmix/database'
require 'gfdmmix/music_database'
require 'gfdmmix/user_database'

module GfDmMix
	class EventDatabase < Database
		def initialize
			@db = connect_db
		end

		def exist?(id)
			query = "select count(*) from events where id = #{id};"

			return get_count_by_query(@db, query) > 0
		end
		alias include? exist?

		def get(id)
			return nil unless exist?(id)

			query = ''
			query << 'select events.* from events '
			query << "where events.id = #{id};"
			result = @db.query(query)
			hash = result.fetch_hash(true)
			event = make_event_item_from_result_hash(hash)

			return event
		end

=begin
		def get_all_music
			musics = Array.new

			query = ''
			query << 'select * from musics;'
			result = @db.query(query)
			result.each_hash(true) do |hash|
				musics << make_music_item_from_result_hash(hash)
			end

			return musics
		end
=end

		private
		# データベースから返ってきた1行の結果セットから、EventItemのインスタンスを生成する
		def make_event_item_from_result_hash(hash)
			musics = Array.new
			m_db = MusicDatabase.new
			(1..4).each do |i|
				if hash["events.music_id_#{i}"]
					musics << m_db.get_by_mid(hash["events.music_id_#{i}"].to_i)
				end
			end
			m_db.close

			return EventItem.new(hash['events.id'].to_i, hash['events.title'], musics)
		end
	end

	class EventItem
		include Comparable
		include DatabaseUtil
		attr_reader :eid, :title, :musics

		def initialize(eid, title, musics)
			@eid = eid
			@title = title
			@musics = musics
		end

		def <=>(other)
			return @eid <=> other.eid
		end
	end

	class EscoreDatabase < Database
		def initialize(user)
			@db = connect_db
			@user = user
		end

		def exist?(event_id)
			query = ''
			query << 'select count(*) from escores '
			query << "where escores.user_id = #{@user.uid} and escores.id = #{event_id};"

			return get_count_by_query(@db, query) > 0
		end
		alias include? exist?

		def get(event_id)
			return nil unless exist?(event_id)

			query = ''
			query << 'select escores.* from escores '
			query << "where escores.user_id = #{@user.uid} and escores.id = #{event_id};"
			result = @db.query(query)
			hash = result.fetch_hash(true)
			escore = make_escore_item_from_result_hash(hash)

			return escore
		end

		private
		# データベースから返ってきた1行の結果セットから、EscoreItemのインスタンスを生成する
		def make_escore_item_from_result_hash(hash)
			user = (@user || UserDatabase.get(hash['escores.user_id'].to_i))

			e_db = EventDatabase.new
			event = e_db.get(hash['escores.event_id'].to_i)
			e_db.close

			mscores = Array.new
			(1..4).each do |i|
				break unless hash["escores.score#{i}"]
				mscores << hash["escores.score#{i}"].to_i
			end

			return EscoreItem.new(user, event, mscores,
				hash['escores.comment'], Time.parse(hash['escores.updated_at']))
		end
	end

	class EscoreItem
		include Comparable
		attr_reader :event, :scores, :sum_score

		def initialize(user, event, scores, comment, updated_at)
			@user = user
			@event = event
			@comment = comment
			@scores = scores
			@updated_at = updated_at

			@sum_score = 0
			scores.each do |score|
				@sum_score += score
			end
		end

		def <=>(other)
			return @sum_score <=> other.sum_score
		end
	end
end
