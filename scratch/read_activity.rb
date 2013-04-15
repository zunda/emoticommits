#$ ruby scratch/read_activity.rb \
# ~/Dropbox/GitHub-Data-Challenge-II/2013-04-12-18.json.gz  | sort |\
# uniq -c | sort -nr
#   1315 PushEvent
#    251 CreateEvent
#    109 PullRequestEvent
#     22 CommitCommentEvent
#     11 GistEvent
#     10 PullRequestReviewCommentEvent

require 'open-uri'
require 'zlib'
require 'yajl'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'githubarchive'

# e.g.
# @github_auth = ['username', 'password']
class Configuration
	def Configuration.load(path)
		c = Configuration.new()
		begin
			c.instance_eval(File.read(path))
		rescue SystemCallError
		end
		return c
	end
	
	attr_reader :github_auth
end

conf = Configuration.load(File.join(ENV['HOME'], '.githubarchiverc'))

ARGV.each do |src|
	js = open(src)
	if src =~ /\.gz\Z/
		js = Zlib::GzipReader.new(open(src)).read
	end

	Yajl::Parser.parse(js) do |ev|
		GitHubArchive::EventParser.parse(ev, dry_run: false, auth: conf.github_auth) do |event|
			%w(type timestamp location url gravatar_id).each do |el|
				puts "#{el}: #{event.send(el)}"
			end
			puts '-----'
			puts event.comment
			puts '-----'
			puts
		end
	end
end
