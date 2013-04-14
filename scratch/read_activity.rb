# ruby scratch/read_activity.rb ~/Dropbox/GitHub-Data-Challenge-II/*.json.gz 
require 'open-uri'
require 'zlib'
require 'yajl'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'githubarchive'

ARGV.each do |src|
	js = open(src)
	if src =~ /\.gz\Z/
		js = Zlib::GzipReader.new(open(src)).read
	end

	Yajl::Parser.parse(js) do |ev|
		GitHubArchive::EventParser.parse(ev) do |event|
			puts "#{event.timestamp.strftime("%H:%M")} #{event.location} #{event.comment} #{event.url}"
		end
	end
end
