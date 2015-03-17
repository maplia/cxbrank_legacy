#---------------------------------------------------------------
#	GFDMmix for CS - Library for Music Data View
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'util'
require 'erb'
require 'gfdmmix/util'
require 'gfdmmix/pagemaker'
require 'gfdmmix/music_database'

module GfDmMix
	class MusicListMaker < PageMaker
		def initialize(cgi, mobile=false)
			@cgi = cgi
			@mobile = mobile
			if @mobile
				@template_html = 'template/music_list.html.erb'
			else
				@template_html = 'template/music_list.html.erb'
			end
		end

		def get_last_modified
			m_db = MusicDatabase.new
			mtime = m_db.mtime
			m_db.close

			return mtime
		end

		def to_html
			m_db = MusicDatabase.new
			musics = m_db.get_all_music
			m_db.close

			music_type_hash = Hash.new
			music_type_hash[MUSIC_TYPE_NORMAL] = Array.new
			music_type_hash[MUSIC_TYPE_SPECIAL] = Array.new
			music_type_hash[MUSIC_TYPE_LIMITED] = Array.new
			musics.each do |music|
				if music.limited?
					music_type_hash[MUSIC_TYPE_LIMITED] << music
				elsif music.monthly?
					music_type_hash[MUSIC_TYPE_SPECIAL] << music
				else
					music_type_hash[MUSIC_TYPE_NORMAL] << music
				end
			end

			return ERB.new(read_template_html(false)).result(binding)
		end
	end

	class ClearRateCalcMaker < PageMaker
		def initialize(cgi, mobile=false)
			@cgi = cgi
			@mobile = mobile
			if @mobile
				@template_html = 'template/rate_calc.html.erb'
			else
				@template_html = 'template/rate_calc.html.erb'
			end
		end

		def to_html
			text_id = (@cgi.path_info || '').split('/')[1]

			m_db = MusicDatabase.new
			music = m_db.get(text_id)
			m_db.close

			return ERB.new(read_template_html(false)).result(binding)
		end
	end

	class PlayRankCalcMaker < PageMaker
		def initialize(cgi, mobile=false)
			@cgi = cgi
			@mobile = mobile
			if @mobile
				@template_html = 'template/rank_calc.html.erb'
			else
				@template_html = 'template/rank_calc.html.erb'
			end
		end

		def get_last_modified
			return Time.now
		end

		def to_html
			m_db = MusicDatabase.new
			musics = m_db.get_all_music
			m_db.close

			titles = Array.new
			std_notes = Array.new
			hrd_notes = Array.new
			mas_notes = Array.new

			musics.sort.each do |music|
				next if music.notes(MUSIC_DIFF_BSC) == 0

				titles << "'#{music.title}'"
				std_notes << music.notes(MUSIC_DIFF_BSC)
				hrd_notes << music.notes(MUSIC_DIFF_ADV)
				mas_notes << music.notes(MUSIC_DIFF_EXT)
			end

			return ERB.new(read_template_html(false)).result(binding)
		end
	end

	class MusicItem
		include DataCellUtil

		def to_html
			return ERB.new(File.read('template/music_list_item.html.erb')).result(binding)
		end
	end
end
