require 'rubygems'
require 'mongo'
include Mongo

def mongo_ini(id, pass)
	@client = MongoClient.new('localhost', 27017)
	@db     = @client['']
	@coll   = @db['']
	auth = @db.authenticate(id, pass)
end

def this_year()
	time = Time.new
	return time.strftime("%Y")
end

def remove_coll()
	@coll.remove
end

def check_if_data_exists(author, title, date)
	return @coll.find({"author"=>author, "title"=>title, "date"=>date}).count()
end

def insert_data(author, title, date, head, full_article, createTime)
	@coll.insert({
		"date"=> date,
		"createTime"=>	createTime,
		"head"=>	head,
		"author"=>	author,
		"title"=>	title,
		"full_article"=> full_article
	})
end

def update_data(author, title, date, full_article, createTime)
	@coll.update({
		"author" => author,
		"title" => title,
		"date" => date,
		"full_article" => full_article,
		"createTime" => createTime
	}, {$set => {"full_article" => full_article}, $set => {"createTime" => createTime} })
end

def db_insert_data(arr)
	begin
		arr.each{  |m|
			repeat_data_count = check_if_data_exists(m['author'], m['title'], m['date'])
			puts repeat_data_count
			if repeat_data_count == 0
				insert_data(m['author'], m['title'], ['date'], m['head'], m['full_article'], m['createTime'])
			else
				update_data(m['author'], m['title'], ['date'], m['full_article'], m['createTime'])
				puts "\nshould update this row\n"
			end
		}
	rescue Exception => e
		puts e.message
		puts e.backtrace.inspect
		puts "\n nothing to db! \n"
	end
end
