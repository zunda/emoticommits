# 18 event types are implemented
# http://developer.github.com/v3/activity/events/types/
require 'open-uri'
require 'yajl'

module GitHubApi
	class Base
		HOST = 'https://api.github.com'
		VERSION = '0.0.0'
		AGENT = "zunda@gmail.com - GitHubApi - #{VERSION}"

		attr_reader :url
		attr_reader :js
		attr_reader :timestamp

		def initialize(url, opts = {auth: []})
			@url = url
			@auth = opts[:auth]
		end

		def read_and_parse
			@js = Yajl::Parser.parse(open(@url, 'User-Agent' => AGENT, :http_basic_authentication => @auth).read)
			@timestamp = Time.parse(@js['created_at']) if @js['created_at']
		end
	end

	class SingleCommitComment < Base
		def initialize(owner, repo, comment_id, opts = {auth: []})
			super("#{HOST}/repos/#{owner}/#{repo}/comments/#{comment_id}", auth: opts[:auth])
		end
	end

	class Download < Base
		def initialize(owner, repo, id, opts = {auth: []})
			super("#{HOST}/repos/#{owner}/#{repo}/downloads/#{id}", auth: opts[:auth])
		end
	end

	class  Gist < Base
		def initialize(id, opts = {auth: []})
			super("#{HOST}/gists/#{id}", auth: opts[:auth])
		end
	end

	class SinglePullRequest < Base
		def initialize(owner, repo, number, opts = {auth: []})
			super("#{HOST}/repos/#{owner}/#{repo}/pulls/#{number}", auth: opts[:auth])
		end
	end

	class Commit < Base
		def initialize(owner, repo, sha, opts = {auth: []})
			super("#{HOST}/repos/#{owner}/#{repo}/commits/#{sha}", auth: opts[:auth])
		end

		def read_and_parse
			super
			@timestamp = Time.parse(@js['commit']['author']['date'])
		end
	end
end
