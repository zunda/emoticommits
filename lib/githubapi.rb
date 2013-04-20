#
# Copyright (c) 2013 zunda <zunda at freeshell.org>
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

require 'open-uri'
require 'yajl'

require 'throttle'

# APIs referred from
# http://developer.github.com/v3/activity/events/types/
module GitHubApi
	class Base
		HOST = 'https://api.github.com'
		VERSION = '0.0.0'
		AGENT = "zunda@gmail.com - GitHubApi - #{VERSION}"

		attr_reader :url
		attr_reader :js
		attr_reader :timestamp

		def initialize(url, opts = {auth: [], throttle: nil})
			@url = url
			@auth = opts[:auth]
			@throttle = opts[:throttle] || DummyThrottle.new
		end

		def read_and_parse
			@js = Yajl::Parser.parse(@throttle.exec{open(@url, 'User-Agent' => AGENT, :http_basic_authentication => @auth).read})
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
