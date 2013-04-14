# ruby scratch/read_activity.rb ~/Dropbox/GitHub-Data-Challenge-II/*.json.gz

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
		url = nil
		case ev['type']
		when 'CommitCommentEvent'
next
			c = GitHubArchive::SingleCommitComment.new(ev['repository']['owner'], ev['repository']['name'], ev['payload']['comment_id'])
			c.read_and_parse
			comment = c.js['body']
			timestamp = c.timestamp
			url = c.js['html_url']
			puts "Comment:   #{comment}\nURL:       #{url}\nTimestamp: #{timestamp}"
		when 'CreateEvent'
next
			comment = ev['payload']['description']
			timestamp = Time.parse(ev['created_at'])
			url = ev['url']
		when 'DeleteEvent'
			next	# nothing interesting
		when 'DownloadEvent'
next
			c = GitHubArchive::Download.new(ev['repository']['owner'], ev['repository']['name'], ev['payload']['id'])
			c.read_and_parse
			comment = c.js['description']
			timestamp = c.timestamp
			url = c.js['html_url']
		when 'FollowEvent'
			next	# emotions, if there are, are not from the event
		when 'FolkEvent'
			next	# emotions, if there are, are not from the event
		end

		next unless comment
		puts "Comment:   #{comment}\nURL:       #{url}\nTimestamp: #{timestamp}"
	end
end
