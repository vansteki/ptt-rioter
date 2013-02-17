require 'rubygems'
require 'mysql'

db = Mysql.init
db.options(Mysql::SET_CHARSET_NAME,"utf8")
$con = db.real_connect('localhost', '', '', 'ptt_demo')


def check_if_data_exist(author, title, date)
	begin
		ready = $con.prepare('SELECT id FROM notifier WHERE (author,title,date) = (?,?,?)')
		rs = ready.execute author,title,date
	rescue Mysql::Error => e
		puts e
	ensure
		return rs
	end
end

def insert_rows(author, title, date, head , full_article ,createTime, push_stat)
	#	pp arr
	begin
		ready = $con.prepare('INSERT INTO notifier(author,title,date,head,full_article ,createTime, push_stat) VALUES (?,?,?,?,?,?,?)')
		ready.execute author, title, date, head , full_article ,createTime, push_stat
		#puts $con.character_set_name
	rescue Exception => e
		puts "error: #{e} notthing to insert?"
	ensure
		return
	end
end

def update_rows(full_article,createTime, push_stat,id)
        begin
            ready = $con.prepare("UPDATE notifier SET full_article=?,push_stat=?,createTime=? WHERE id =#{id}")
            rs = ready.execute full_article, push_stat, createTime
        rescue Mysql::Error => e
                puts e
        ensure
                return
        end
end

def count_push_stat(full_article)
	push_content = full_article.scan(/.*From\:\s*\d*\.\d*\.\d*\.\d*((.|\n)*)/)
	return push_content.to_s.scan(/\/n(推)/).count()
end

def db_commit_data(arr)
	id = nil
	arr.each{  |m|
		rs = check_if_data_exist(m['author'], m['title'], m['date'])
		rs.each{|s| id = s}
		if rs.num_rows > 0
			push_stat = count_push_stat(m['full_article'])
			update_rows(m['full_article'] ,m['createTime'], push_stat, id.to_s)
		else
			push_stat = count_push_stat(m['full_article'])
			insert_rows(m['author'], m['title'], m['date'], m['head'] , m['full_article'] , m['createTime'], push_stat )
		end
	}
		puts "\ncommit done!\n"
end
