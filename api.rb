#!/usr/local/bin/ruby -Ku
#***************************************************************
#	CxB RankPoint Simulator - Data Access API
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#***************************************************************
$LOAD_PATH << 'lib'

require 'cgi'
require 'json/pure'
require 'util'
require 'gfdmmix/const'
require 'gfdmmix/music_database'
require 'gfdmmix/user_database'
require 'gfdmmix/skill_database'

def music_item_to_hash(music)
	hash = {}

	hash['text_id'] = music.text_id
	hash['title'] = music.title
	hash['number'] = music.number
	hash['monthly'] = music.monthly?

	GfDmMix::MUSIC_DIFFS.keys.each do |diff|
		score = {}

		score['level'] = music.level(diff)
		score['notes'] = music.notes(diff)
		hash[GfDmMix::MUSIC_DIFF_CLASSES[diff]] = score
	end

	return hash
end

def skill_item_to_hash(skill)
	hash = {}
	return hash
end

begin
	cgi = CGI.new
	params = (cgi.path_info || '').split('/')
	callback = cgi['callback']
	data = {}
	mtime = Time.now

	case params[1]
	when 'music'
		m_db = GfDmMix::MusicDatabase.new
		music = m_db.get(params[2]) if params[2]
		mtime = m_db.mtime
		m_db.close

		if music
			data = music_item_to_hash(music)
		else
			data = {}
		end
	when 'musics'
		m_db = GfDmMix::MusicDatabase.new
		musics = m_db.get_all_music
		mtime = m_db.mtime
		m_db.close

		data = []
		musics.each do |music|
			data << music_item_to_hash(music)
		end
	when 'skills'
		user = GfDmMix::UserDatabase.get(params[2]) if params[2]
		if user
			s_db = GfDmMix::SkillDatabase.new(user)
			skills = s_db.get_all_skill(true)
			mtime = s_db.mtime
			s_db.close
		end

		if skills
			skills.each do |skill|
				data << skill_item_to_hash(skill)
			end
		else
			data = {}
		end
	end

	if callback.empty?
		print "Content-Type: application/json\n"
	else
		print "Content-Type: application/javascript\n"
	end
	print "Access-Control-Allow-Origin: *\n"
	print "Last-Modified: #{mtime.httpdate}\n"
	print "\n"
	if callback.empty?
		print data.to_json
	else
		print "#{callback}(#{data.to_json})"
	end
rescue
	print write_backtrace_for_cgi
end