# 18 event types are implemented
# http://developer.github.com/v3/activity/events/types/
require 'open-uri'
require 'yajl'

module GitHub
	class Api
		HOST = 'https://api.github.com'
		VERSION = '0.0.0'
		AGENT = "zunda@gmail.com - GitHubApi - #{VERSION}"

		attr_reader :url
		attr_reader :js
		attr_reader :timestamp

		def initialize(url)
			@url = url
		end

		def read_and_parse
			@js = Yajl::Parser.parse(open(@url, 'User-Agent' => AGENT).read)
			@timestamp = Time.parse(@js['created_at']) if @js['created_at']
		end
	end

	class SingleCommitComment < Api
		def initialize(owner, repo, comment_id)
			super("#{HOST}/repos/#{owner}/#{repo}/comments/#{comment_id}")
		end
	end

	class Download < Api
		def initialize(owner, repo, id)
			super("#{HOST}/repos/#{owner}/#{repo}/downloads/#{id}")
		end
	end

	class  Gist < Api
		def initialize(id)
			super("#{HOST}/gists/#{id}")
		end
	end

	class SinglePullRequest < Api
		def initialize(owner, repo, number)
			super("#{HOST}/repos/#{owner}/#{repo}/pulls/#{number}")
		end
	end

	class Commit < Api
		def initialize(owner, repo, sha)
			super("#{HOST}/repos/#{owner}/#{repo}/commits/#{sha}")
		end

		def read_and_parse
			super
			@timestamp = Time.parse(@js['commit']['author']['date'])
		end
	end
end
