# ruby scratch/read_activity.rb scratch/2013-04-12-11.json.gz 
require 'open-uri'
require 'zlib'
require 'yajl'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'githubarchive/endpoints'
 
ARGV.each do |src|
	js = open(src)
	if src =~ /\.gz\Z/
		js = Zlib::GzipReader.new(open(src)).read
	end

	Yajl::Parser.parse(js) do |ev|
		actor = ev['actor_attributes']
		next unless actor

		loc = actor['location']
		next unless loc
		avator = actor['gravatar_id']
		next unless avator

		comment = nil
		timestamp = nil
		case ev['type']
		when 'CommitCommentEvent'
#			c = GitHubArchive::SingleCommitComment.new(ev['repository']['owner'], ev['repository']['name'], ev['payload']['comment_id'])
#			c.read_and_parse
#			comment = c.js['body']
#			timestamp = c.timestamp
		when 'CreateEvent'
			comment = ev['payload']['description']
			timestamp = ev['payload']['created_at']
		when 'DeleteEvent'
		when 'DownloadEvent'
		end

		next unless comment
		puts comment
		exit	# safe guard
	end
end
