#---------------------------------------------------------------
#	GFDMmix for CS - Library for Skill Data
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#		Inspired by XV / GuitarFreaks & DrumMania Skill Simulator
#---------------------------------------------------------------
require 'bigdecimal'
require 'uconv'
require 'sdbm'
require 'mysql'
require 'util'
require 'gfdmmix/util'
require 'gfdmmix/database'
require 'gfdmmix/user_database'
require 'gfdmmix/music_database'

module GfDmMix
	class SkillDatabase < Database
		def initialize(user)
			@db = connect_db
			@user = user
		end

		def mtime
			return Time.now unless @user

			query = "select max(updated_at) from skills where user_id = #{@user.uid};"

			return Time.parse(get_datetime_string_by_query(@db, query))
		end
		alias get_last_modified mtime

		def exist?(music)
			query = ''
			query << 'select count(*) from skills '
			query << 'inner join musics on skills.music_id = musics.id '
			query << "where skills.user_id = #{@user.uid} "
			query << "and musics.text_id = '#{music.text_id}';"

			return get_count_by_query(@db, query) > 0
		end
		alias include? exist?

		def get(music, ignore_lock=false)
			return nil unless exist?(music)

			query = ''
			query << 'select * from skills '
			query << 'inner join musics on skills.music_id = musics.id '
			query << "where skills.user_id = #{@user.uid.to_i} "
			query << "and musics.text_id = '#{music.text_id}';"
			result = @db.query(query)
			hash = result.fetch_hash(true)
			skill = make_skill_item_from_result_hash(hash, ignore_lock)

			return skill
		end

		def get_all_skill(ignore_lock=false)
			skills = Array.new

			m_db = MusicDatabase.new
			musics = m_db.get_all_music
			m_db.close

			musics.each do |music|
				skill = get(music, ignore_lock)
				if skill
					skills << skill
				else
					skills << SkillItem.make_empty_item(music)
				end
			end

			return SkillItemSet.new(@user, skills, ignore_lock)
		end

		def edit(music, skill)
			unless exist?(music)
				query = ''
				query << 'insert into skills (user_id, music_id,'
				query << ' std_stat, std_locked, std_point, std_score, std_rate, std_rank, std_fc, std_ultimate,'
				query << ' hrd_stat, hrd_locked, hrd_point, hrd_score, hrd_rate, hrd_rank, hrd_fc, hrd_ultimate,'
				query << ' mas_stat, mas_locked, mas_point, mas_score, mas_rate, mas_rank, mas_fc, mas_ultimate, comment,'
				query << ' created_at, updated_at) '
				query << "values (#{@user.uid.to_i}, #{music.mid.to_i},"
				query << " #{skill.diff_skills[MUSIC_DIFF_BSC].stat.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_BSC].locked.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_BSC].point.to_f}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_BSC].score.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_BSC].rate.to_f}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_BSC].rank.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_BSC].fcs.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_BSC].ultimate.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_ADV].stat.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_ADV].locked.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_ADV].point.to_f}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_ADV].score.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_ADV].rate.to_f}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_ADV].rank.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_ADV].fcs.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_ADV].ultimate.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_EXT].stat.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_EXT].locked.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_EXT].point.to_f}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_EXT].score.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_EXT].rate.to_f}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_EXT].rank.to_i}, "
				query << " #{skill.diff_skills[MUSIC_DIFF_EXT].fcs.to_i},"
				query << " #{skill.diff_skills[MUSIC_DIFF_EXT].ultimate.to_i}, '#{skill.comment}',"
				query << ' current_timestamp, current_timestamp); '
			else
				query = ''
				query << 'update skills set '
				query << " std_stat = #{skill.diff_skills[MUSIC_DIFF_BSC].stat.to_i}, "
				query << " std_locked = #{skill.diff_skills[MUSIC_DIFF_BSC].locked.to_i}, "
				query << " std_score = #{skill.diff_skills[MUSIC_DIFF_BSC].score.to_i}, "
				query << " std_point = #{skill.diff_skills[MUSIC_DIFF_BSC].point.to_f}, "
				query << " std_rate = #{skill.diff_skills[MUSIC_DIFF_BSC].rate.to_f}, "
				query << " std_rank = #{skill.diff_skills[MUSIC_DIFF_BSC].rank.to_i}, "
				query << " std_fc = #{skill.diff_skills[MUSIC_DIFF_BSC].fcs.to_i}, "
				query << " std_ultimate = #{skill.diff_skills[MUSIC_DIFF_BSC].ultimate.to_i}, "
				query << " hrd_stat = #{skill.diff_skills[MUSIC_DIFF_ADV].stat.to_i}, "
				query << " hrd_locked = #{skill.diff_skills[MUSIC_DIFF_ADV].locked.to_i}, "
				query << " hrd_point = #{skill.diff_skills[MUSIC_DIFF_ADV].point.to_f}, "
				query << " hrd_score = #{skill.diff_skills[MUSIC_DIFF_ADV].score.to_i}, "
				query << " hrd_rate = #{skill.diff_skills[MUSIC_DIFF_ADV].rate.to_f}, "
				query << " hrd_rank = #{skill.diff_skills[MUSIC_DIFF_ADV].rank.to_i}, "
				query << " hrd_fc = #{skill.diff_skills[MUSIC_DIFF_ADV].fcs.to_i}, "
				query << " hrd_ultimate = #{skill.diff_skills[MUSIC_DIFF_ADV].ultimate.to_i}, "
				query << " mas_stat = #{skill.diff_skills[MUSIC_DIFF_EXT].stat.to_i}, "
				query << " mas_locked = #{skill.diff_skills[MUSIC_DIFF_EXT].locked.to_i}, "
				query << " mas_point = #{skill.diff_skills[MUSIC_DIFF_EXT].point.to_f}, "
				query << " mas_score = #{skill.diff_skills[MUSIC_DIFF_EXT].score.to_i}, "
				query << " mas_rate = #{skill.diff_skills[MUSIC_DIFF_EXT].rate.to_f}, "
				query << " mas_rank = #{skill.diff_skills[MUSIC_DIFF_EXT].rank.to_i}, "
				query << " mas_fc = #{skill.diff_skills[MUSIC_DIFF_EXT].fcs.to_i}, "
				query << " mas_ultimate = #{skill.diff_skills[MUSIC_DIFF_EXT].ultimate.to_i}, "
				query << " comment = '#{skill.comment}', "
				query << " updated_at = current_timestamp "
				query << "where user_id = #{@user.uid} and music_id = #{music.mid};"
			end
			@db.query(query)

			skill_set = get_all_skill
			skill_mtime = mtime

			u_db = GfDmMix::UserDatabase.new
			u_db.save_skill_point(@user, skill_set.skill_point, skill_mtime)
			u_db.close
		end

		def delete(music)
			query = ''
			query << 'delete from skills '
			query << "where skills.user_id = #{@user.uid.to_i} "
			query << "and skills.music_id = (select id from musics where text_id = '#{music.text_id}');"
			@db.query(query)

			skill_set = get_all_skill
			skill_mtime = mtime

			u_db = GfDmMix::UserDatabase.new
			u_db.save_skill_point(@user, skill_set.skill_point, skill_mtime)
			u_db.close
		end

		private
		def make_skill_item_from_result_hash(hash, ignore_lock=false)
			music = MusicItem.make_from_result_hash(hash)
			std_skill = SkillScoreItem.new(music, MUSIC_DIFF_BSC,
				hash['skills.std_stat'], (ignore_lock ? 0 : hash['skills.std_locked'].to_i),
				(hash['skills.std_point'].nil? ? nil : hash['skills.std_point'].to_f),
				(hash['skills.std_rate'].nil? ? nil : hash['skills.std_rate'].to_f),
				hash['skills.std_rank'], hash['skills.std_fc'], hash['skills.std_ultimate'].to_i)
			hrd_skill = SkillScoreItem.new(music, MUSIC_DIFF_ADV,
				hash['skills.hrd_stat'], (ignore_lock ? 0 : hash['skills.hrd_locked'].to_i),
				(hash['skills.hrd_point'].nil? ? nil : hash['skills.hrd_point'].to_f),
				(hash['skills.hrd_rate'].nil? ? nil : hash['skills.hrd_rate'].to_f),
				hash['skills.hrd_rank'], hash['skills.hrd_fc'], hash['skills.hrd_ultimate'].to_i)
			mas_skill = SkillScoreItem.new(music, MUSIC_DIFF_EXT,
				hash['skills.mas_stat'], (ignore_lock ? 0 : hash['skills.mas_locked'].to_i),
				(hash['skills.mas_point'].nil? ? nil : hash['skills.mas_point'].to_f),
				(hash['skills.mas_rate'].nil? ? nil : hash['skills.mas_rate'].to_f),
				hash['skills.mas_rank'], hash['skills.mas_fc'], hash['skills.mas_ultimate'].to_i)

			return SkillItem.new(hash['skills.id'].to_i, music,
				std_skill, hrd_skill, mas_skill, hash['skills.comment'])
		end
	end

	class SkillItemSet
		attr_reader :user
		attr_reader :skills
		attr_reader :skill_hash
		attr_reader :skill_point_hash
		attr_reader :skill_point

		def initialize(user, skills, ignore_lock)
			@user = user
			@skills = skills

			@skill_music_hash = Hash.new
			skills.each do |skill|
				@skill_music_hash[skill.music.mid] = skill
			end

			@skill_hash = {
				MUSIC_TYPE_NORMAL => Array.new, MUSIC_TYPE_SPECIAL => Array.new,
				MUSIC_TYPE_LIMITED => Array.new
			}
			@skill_point_hash = {
				MUSIC_TYPE_NORMAL => 0.0, MUSIC_TYPE_SPECIAL => 0.0
			}
			@skill_point = 0.0

			skills.each do |skill|
				if skill.music.limited?
					@skill_hash[MUSIC_TYPE_LIMITED] << skill
				elsif skill.music.monthly?
					@skill_hash[MUSIC_TYPE_SPECIAL] << skill
				else
					@skill_hash[MUSIC_TYPE_NORMAL] << skill
				end
			end

			@skill_hash[MUSIC_TYPE_LIMITED].sort!
			@skill_hash[MUSIC_TYPE_LIMITED].reverse!
			@skill_hash[MUSIC_TYPE_SPECIAL].sort!
			@skill_hash[MUSIC_TYPE_SPECIAL].reverse!
			@skill_hash[MUSIC_TYPE_NORMAL].sort!
			@skill_hash[MUSIC_TYPE_NORMAL].reverse!

			@skill_hash[MUSIC_TYPE_SPECIAL].each do |skill|
				next if skill.max_skill.locked? and ignore_lock == false
				next unless skill.max_skill.point
				@skill_point_hash[MUSIC_TYPE_SPECIAL] += skill.max_skill.point
				@skill_point += skill.max_skill.point
			end
			@skill_hash[MUSIC_TYPE_NORMAL][0, 20].each do |skill|
				next if skill.max_skill.locked? and ignore_lock == false
				next unless skill.max_skill.point
				@skill_point_hash[MUSIC_TYPE_NORMAL] += skill.max_skill.point
				@skill_point += skill.max_skill.point
			end
		end

		def [](mid)
			return @skill_music_hash[mid]
		end
	end

	class SkillItem
		include Comparable
		attr_reader :sid
		attr_reader :music
		attr_reader :diff_skills
		attr_reader :max_skill
		attr_reader :comment

		def initialize(sid, music, bsc_skill, adv_skill, ext_skill, comment)
			@sid = sid
			@music = music
			@diff_skills = Hash.new
			@diff_skills[MUSIC_DIFF_BSC] = bsc_skill
			@diff_skills[MUSIC_DIFF_ADV] = adv_skill
			@diff_skills[MUSIC_DIFF_EXT] = ext_skill
			@max_skill = @diff_skills.values.max
			@comment = comment
		end

		def self.make_empty_item(music)
			bsc_skill = SkillScoreItem.new(
				music, MUSIC_DIFF_BSC, SP_STATUS_NO_PLAY, 0, nil, nil, nil, nil, nil)
			adv_skill = SkillScoreItem.new(
				music, MUSIC_DIFF_ADV, SP_STATUS_NO_PLAY, 0, nil, nil, nil, nil, nil)
			ext_skill = SkillScoreItem.new(
				music, MUSIC_DIFF_EXT, SP_STATUS_NO_PLAY, 0, nil, nil, nil, nil, nil)

			return SkillItem.new(nil, music, bsc_skill, adv_skill, ext_skill, '')
		end

		def <=>(other)
			if @max_skill.locked != other.max_skill.locked
				return -(@max_skill.locked <=> other.max_skill.locked)
			elsif @max_skill.point != other.max_skill.point
				return (@max_skill.point || 0.0) <=> (other.max_skill.point || 0.0)
			else
				return -(@music.sortkey <=> other.music.sortkey)
			end
		end

		def to_html_for_list(row, st_bool, mobile, edit)
			# ここでの出力結果は、スキル表の中の1行分のHTMLテキストになる
			if edit == false and @point == 0.0
				# 編集モードでないとき、最高ポイントが0であるものは表示対象としない
				return ''
			else
				return @max_skill.to_html_for_list(row, st_bool, mobile, @comment, edit)
			end
		end
	end

	# 譜面ごとのスキルポイントアイテム
	class SkillScoreItem
		include Comparable
		attr_reader :music
		attr_reader :diff, :stat, :locked, :point, :score, :rate, :u_rate, :rank, :fcs, :ultimate

		def initialize(music, diff, stat, locked, point, rate, rank, fcs, ultimate)
			@music = music
			@diff = diff
			@locked = locked
			@stat = stat
			@point = point
			@score = 0
			@rate = rate
			@rank = rank
			@fcs = fcs
			@ultimate = ultimate

			if (point || 0.0) == 0.0
				@point = music.level(diff) * ((rate || 0) / 100.0)
				if ultimate == 1
					@point = @point * 1.2
				end
				@point = BigDecimal.new((@point * 100).to_s).truncate.to_f / 100.0
			end

			ultimate_max = 1.2 * music.level(diff)
			ultimate_rate = (point || 0.0) / ultimate_max * 100
			@u_rate = (ultimate == 1 ? (ultimate_rate == ultimate_rate.to_i ? ultimate_rate : ultimate_rate.to_i + 1) : 0)
			@u_rate = @rate if @u_rate > (@rate || 0)
		end

		def SkillScoreItem.make_from_result_hash(hash, music, diff, ignore_lock=false)
			column_prefix = get_diff_prefix(diff)

			return SkillScoreItem.new(music, diff,
				hash["skills.#{column_prefix}_stat"].to_i,
				(ignore_lock ? 0 : hash["skills.#{column_prefix}_locked"].to_i),
				(hash['skills.std_point'].nil? ? nil : hash['skills.std_point'].to_f),
				(hash['skills.std_rate'].nil? ? nil : hash['skills.std_rate'].to_f),
				hash['skills.std_rank'], hash['skills.std_fc'], hash['skills.std_ultimate'].to_i)
		end

		def <=>(other)
			if @locked != other.locked
				if @point == 0
					return -1
				elsif other.point == 0
					return 1
				else
					return -(@locked <=> other.locked)
				end
			elsif @point != other.point
				return @point <=> other.point
			else
				return -(@diff <=> other.diff)
			end
		end

		def cleared?
			return @stat == SP_STATUS_CLEAR
		end

		def fullcombo?
			return cleared? && (@fcs != SP_COMBO_STATUS_NO)
		end

		def failed?
			return @stat == SP_STATUS_FAILED
		end

		def locked?
			return @locked == 1
		end

		def ultimate?
			return @ultimate == 1
		end

		def untargeted?
			return locked? || @music.limited?
		end

		def to_html_for_list(row, st_bool, mobile, comment, edit)
			if mobile
				template = 'template/mobile/skill_list_item.html.erb'
			else
				template = 'template/skill_list_item.html.erb'
			end

			return ERB.new(File.read(template)).result(binding)
		end

		private
		def get_diff_prefix(diff)
			case diff
			when MUSIC_DIFF_BSC
				return 'std'
			when MUSIC_DIFF_ADV
				return 'hrd'
			when MUSIC_DIFF_EXT
				return 'mas'
			end
		end
	end
end
