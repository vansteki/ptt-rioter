class PttRiotN
	require 'rubygems'
	require 'json'
	require 'net/telnet'
	require 'pp'

	AnsiSetDisplayAttr = '\x1B\[(?>(?>(?>\d+;)*\d+)?)m'
	WaitForInput =  '(?>\s+)(?>\x08+)'
	AnsiEraseEOL = '\x1B\[K'
	AnsiCursorHome = '\x1B\[(?>(?>\d+;\d+)?)H'
	PressAnyKey = '\xAB\xF6\xA5\xF4\xB7\x4E\xC1\xE4\xC4\x7E\xC4\xF2'
	Big5Code = '[\xA1-\xF9][\x40-\xF0]'
	PressAnyKeyToContinue = "#{PressAnyKey}(?>\\s*)#{AnsiSetDisplayAttr}(?>(?:\\xA2\\x65)+)\s*#{AnsiSetDisplayAttr}"
	PressAnyKeyToContinue2 = "\\[#{PressAnyKey}\\](?>\\s*)#{AnsiSetDisplayAttr}"
	ArticleList = '\(b\)' + "#{AnsiSetDisplayAttr}" + '\xB6\x69\xAA\x4F\xB5\x65\xAD\xB1\s*' + "#{AnsiSetDisplayAttr}#{AnsiCursorHome}" # (b)進板畫面
	Signature = '\xC3\xB1\xA6\x57\xC0\xC9\.(?>\d+).+' + "#{AnsiCursorHome}"
	EmailBox = '[a-zA-Z0-9._%+-]+@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,4}'

	def connect(port, time_out, wait_time, host)
		tn = Net::Telnet.new(
		'Host'       => host,
		'Port'       => port,
		'Timeout'    => time_out,
		'Waittime'   => wait_time
		)
		return tn
	end

	def login(tn, id, password)
		tn.waitfor(/guest.+new(?>[^:]+):(?>\s*)#{AnsiSetDisplayAttr}#{WaitForInput}\Z/){ |s| print(s)}
		tn.cmd("String" => id, "Match" => /\xB1\x4B\xBD\x58:(?>\s*)\Z/){ |s| }
		tn.cmd("String" => password,
		"Match" => /#{PressAnyKeyToContinue}\Z/){ |s| print(s)}
		tn.print("\n")
	end

	#進入某板(等於從主畫面按's')
	def jump_board(tn, board_name)
		# [呼叫器]
		tn.waitfor(/\[\xA9\x49\xA5\x73\xBE\xB9\]#{AnsiSetDisplayAttr}.+#{AnsiCursorHome}\Z/){ |s| }
		tn.print('s')
		tn.waitfor(/\):(?>\s*)#{AnsiSetDisplayAttr}(?>\s*)#{AnsiSetDisplayAttr}#{AnsiEraseEOL}#{AnsiCursorHome}\Z/){ |s| }
		lines = tn.cmd( "String" => board_name, "Match" => /(?>#{PressAnyKeyToContinue}|#{ArticleList})\Z/ ) do |s|
			print(s)
		end

		if not (/#{PressAnyKeyToContinue}\Z/ =~ lines)
			return lines
		end

		lines = tn.cmd("String" => "", "Match" => /#{ArticleList}\Z/) do |s|
			print(s)
		end
		return lines
	end

	def down(tn)
		tn.print("j")
	end

	def up(tn)
		tn.print("k")
	end

	def top(tn)
		tn.print("\e[1~")
	end

	def bottom(tn)
		tn.print("\e[4~")
	end

	def page_up(tn)
		tn.print("\e[5~")
	end

	def page_down(tn)
		tn.print("\e[6~")
	end

	def enter(tn)
		tn.print("\n")
	end

	def back_to_start_point(tn)
		bottom(tn)
		up(tn)
		up(tn)
		up(tn)
	end

	def convert_month(month)
		$m =  month
		case $m
		when 'Jan'
			return '1'
		when 'Feb'
			return '2'
		when 'Mar'
			return '3'
		when 'Apr'
			return '4'
		when 'May'
			return '5'
		when 'Jun'
			return '6'
		when 'Jul'
			return '7'
		when 'Aug'
			return '8'
		when 'Sep'
			return '9'
		when 'Oct'
			return '10'
		when 'Nov'
			return '11'
		when 'Dec'
			return '12'
		else
			return 0
		end
	end

	def gsub_ansi_by_space(s)
		raise ArgumentError, "search_by_title() invalid title:" unless s.kind_of? String

		s.gsub!(/\x1B\[(?:(?>(?>(?>\d+;)*\d+)?)m|(?>(?>\d+;\d+)?)H|K)/) do |m|
			if m[m.size-1].chr == 'K'
				"\n"
			else
				" "
			end
		end
	end

	def big5_2_utf8(data) #@!!! Iconv::InvalidCharacter
		begin
			ic = Iconv.new("utf-8//IGNORE","big5")
			data = ic.iconv(data.to_s)
			$iconv_fail = 0
		rescue
			puts "\n iconv error #{data}\n"
			return "iconv error"
			$iconv_fail = 1
		ensure
			return  data
		end
	end

	def search_by_hot(tn, number)
		tn.print('Z')
		tn.print("#{number}")
		tn.print("\n")
		bottom(tn)
	end

	def email_article(tn, email_box=nil)
		raise ArgumentError, "email_article() invalid telnet reference:" unless tn.kind_of? Net::Telnet
		if email_box != nil && ( !(email_box.kind_of? String) || !(/^#{EmailBox}$/ =~ email_box) )
			raise ArgumentError, "email_article() invalid email_box:"
		end

		begin
			tn.print("F")
			tn.print('n')
			tn.print("\n")
			result = tn.cmd("String" => email_box,
			"Match" => /(?>#{PressAnyKeyToContinue2}|#{ArticleList})\Z/
			){ |s| print(s) }

			if not (/#{PressAnyKeyToContinue2}\Z/ =~ result)
				puts "mail send!"
				return true # 轉寄成功!
			end

			tn.cmd("String" => "", "Match" => /#{ArticleList}\Z/) do |s|
				print(s)
			end
			return false # 轉寄失敗!
		rescue SystemCallError => e
			raise e, "email_article() system call:" + e.to_s()
		rescue TimeoutError => e
			raise e, "email_article() timeout:" + e.to_s()
		rescue SocketError => e
			raise e, "email_article() socket:" + e.to_s()
		rescue Exception => e
			raise e, "email_article() unknown:" + e.to_s()
		end
	end

	def now_time()
		time = Time.new
		return time.strftime("%Y-%m-%d %H:%M:%S")
	end

	def now_date()
		time = Time.new
		return time.strftime("%m/%d")
	end

	def log(log, file_name="index.html")
		File.open("#{file_name}","w+") do |f| f.puts log end
	end

	def check_if_match_date(tn)
		view = tn.waitfor(/(?>#{ArticleList})/){ |s| }
	end

	def get_date(tn)
		date = nil
		tn.waitfor(/.*/){ |s|
			s = gsub_ansi_by_space(s)
			#print s
			s.scan(/\s+\xA7\x40\xAA\xCC\s+(.*)\s+\(.*\).*\s*\xBC\xD0\xC3\x44\s+(.+\S)\s+\xAE\xC9\xB6\xA1\s+\w+\s+(\w+)\s+(\d+).*(\d\d\d\d)/){
				|author, title, month, day, year|
				month = convert_month(month)
				puts "\n------------#{title}------------------\n"
				date = "0#{month}/#{day}"
				puts "\narticle_info parse done, date is #{date}\n"
				return date
			}
		}
	end

	def loop_check(tn)
		date_item = []
		date_today = now_date()
		enter(tn)
		article_date = get_date(tn)
		p article_date
		p "vs"
		p date_today

		if article_date != date_today
			puts "not match"
		else
			tn.print('q')
			#date_item.push(article_date)
			email_article(tn, "firecat977@gmail.com")
			sleep(9)
		end
		up(tn)
	end

	def hasInput()
		if !ARGV[0] || !ARGV[1] then
			print("need ID PASSWORD!\n")
			exit
		end
	end

	def crawler_ini()
		loop_limit = 20
		tn = connect(23, 10, 1, 'ptt.cc')
		start_time = now_time()
		login(tn, ARGV[0], ARGV[1])
		jump_board(tn, "Gossiping")
		search_by_hot(tn, 50)

		while(1)
			for i in 1...loop_limit
				sleep(1)
				loop_check(tn)
				pp i
				if i >= loop_limit -1
					tn.print("q")
					tn.print("q")
					tn.print("q")
					jump_board(tn, "Gossiping")
					search_by_hot(tn, 50)
				end
			end
			sleep(900)
		end
	end

end #end of class