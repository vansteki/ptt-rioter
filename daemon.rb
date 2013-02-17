$DIR = File.expand_path(File.dirname(__FILE__)) + '/'
require $DIR + 'pttriotn.rb'
d = PttRiotN.new
d.hasInput()
d.crawler_ini()