#-----------------------------------------------------
#	Global Method Definition
#		Written by Tsuyoshi Shimabukuro / sie@maplia.jp
#-----------------------------------------------------
require 'cgi'
require 'time'
require 'uri'
require 'English'

# return the first non-nil value (like the SQL function which has a same name).
def coalesce(*args)
  args.each do |arg|
    return arg unless arg.nil?
  end

	return nil
end

# return the first non-zero size string.
def coalesce_string(*args)
  args.each do |arg|
    return arg unless arg.empty?
  end

	return ''
end

# String extension
class String
	# is integer?
	def is_i?
		begin
			Integer(self)
			return true
		rescue ArgumentError
			return false
		end
	end

	# is float?
	def is_f?
		begin
			Float(self)
			return true
		rescue ArgumentError
			return false
		end
	end
end

def hash_to_radio_button_html(hash, name, start_tabindex, default=nil)
	html = ''
	default = hash.keys.min unless default

	html << '<ul class="setting">'
	hash.keys.sort.each_with_index do |key, i|
		html << '<li><label>'
		html << "<input type=\"radio\" name=\"#{name}\""
		html << " value=\"#{key}\" tabindex=\"#{start_tabindex+i}\""
		html << ' checked' if default == key
		html << "> #{hash[key]}</label></li>"
	end
	html << '</ul>'

	return html
end

def hash_to_option_html(hash, default=nil)
	html = ''
	default = hash.keys.min unless default

	hash.keys.sort.each do |key|
		html << "<option value=\"#{key}\""
		html << " selected" if default == key
		html << ">#{hash[key]}</option>"
	end

	return html
end

def normalize_textarea_data(data)
	return data.gsub(/\r\n/, "\n")
end

def textarea_data_to_html(data, autolink=false)
	html = data.dup

	html.gsub!(/\n/, '<br>')
	if autolink
		html.gsub!(URI.regexp(['http', 'https'])) do |uri|
			"<a href=\"#{uri}\">#{uri}</a>"
		end
	end

	return html
end

def valid_mail_address?(address)
	part = /[\w\d_\-\.]+/
	valid_pattern = /^#{part}@#{part}$/

	return address =~ valid_pattern
end

def server_host?
	# because sunrise.maplia.jp is a test server.
	return ENV['HTTP_HOST'] != 'sunrise.maplia.jp'
end

def get_request_params(cgi)
	return (cgi.path_info || '').split('/')
end

def get_request_path(cgi)
	return "http://#{cgi.host}#{cgi.script_name.gsub(/\/[^\/]*\z/, '/')}"
end

def sp_access?(cgi)
	if cgi.user_agent =~ /(iPhone|iPod)/
		return true
	elsif cgi.user_agent =~ /Android.*Mobile/
		return true
	else
		return false
	end
end

def respond_to_http_request(cgi, pagemaker, charset='UTF-8')
	output = ''
	http_header_hash = {'type' => 'text/html', 'charset' => charset}

	if pagemaker.respond_to?(:get_last_modified)
		# if can get mtime from pagemaker object, it will be added to HTTP header.
		mtime = pagemaker.get_last_modified

		if mtime > Time.at(0)
			http_header_hash['Last-Modified'] = mtime.httpdate
		end
	end

	case cgi.request_method.downcase
	when 'head'
		# write only HTTP headers.
		output << cgi.header(http_header_hash)
	else
		html = pagemaker.to_html

		unless html =~ /.*html/
			# if html does not HTML text, it will be regarded as the URI of next page.
			output << cgi.header({'Location' => html})
		else
			# write body with HTTP headers.
			output << cgi.header(http_header_hash)
			output << html
		end
	end

	return output
end

def get_request_path(cgi)
	return "http://#{cgi.host}#{cgi.script_name.gsub(/\/[^\/]*\z/, '/')}"
end

def write_backtrace_for_cgi
	output = ''
	http_header_hash = {'type' => 'text/plain'}

	cgi = CGI.new
	output << cgi.header(http_header_hash)
	output << "#{$ERROR_INFO.inspect}\n"
	output << $ERROR_INFO.backtrace.join("\n")		# because backtrace is array.

	return output
end

def puts_log(value)
	File.open('hoge.txt', 'a') do |file|
		file.printf("%s: %s\n", value.to_s, value.class.name)
	end
end
