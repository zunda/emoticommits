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

ARGV.each do |src|
	js = open(src)
	if src =~ /\.gz\Z/
		js = Zlib::GzipReader.new(open(src)).read
	end

	Yajl::Parser.parse(js) do |ev|
		GitHubArchive::EventParser.parse(ev, dry_run: true) do |event|
			puts event.type
		end
	end
end
