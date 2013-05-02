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

require 'net/http'	# for Net::HTTPBadResponse

require 'githubapi'
require 'sqlite3if'

module GitHubArchive
	class Event
		def Event.schema
			{'timestamp' => Time, 'comment' => String, 'location' => String, 'url' => String, 'type' => String, 'gravatar_id' => String}
		end
		include Schemable

		def initialize(timestamp = nil, comment = nil, location = nil, url = nil, type = nil, gravatar_id = nil)
			@timestamp = timestamp
			@comment = comment
			@location = location
			@url = url
			@type = type
			@gravatar_id = gravatar_id
		end
	end

	# Errors that parser cannot continue but continue parsing other events
	class EventParseIgnorableError < StandardError; end

	# Errors that worth retrying after a short wait
	class EventParseRetryableError < StandardError; end

	# Errors that worth retrying after a long wait
	class EventParseToWaitError < StandardError; end

	# based upon http://developer.github.com/v3/activity/events/types/
	class EventParser
		attr_reader :api_queries

		def initialize(opts = {auth: nil})
			@auth = opts[:auth]
			@api_queries = Array.new
		end

		# yeilds Event
		# auth: [user, password]
		def parse(js)
			actor = js['actor_attributes']
			return unless actor

			loc = actor['location']
			return unless loc
			avatar = actor['gravatar_id']
			return unless avatar

			type = js['type']
			c = nil
			case type
			when 'CommitCommentEvent'
				c = GitHubApi::SingleCommitComment.new(js['repository']['owner'], js['repository']['name'], js['payload']['comment_id'], auth: @auth)
				c.location = loc
				c.type = type
				c.avatar = avatar
				@api_queries << c
				return
			when 'CreateEvent'
				comment = js['payload']['description']
				timestamp = Time.parse(js['created_at'])
				url = js['url']
				yield Event.new(timestamp, comment, loc, url, type, avatar)
				return
			when 'DeleteEvent'
				return	# nothing interesting
			when 'DownloadEvent'
				c = GitHubApi::Download.new(js['repository']['owner'], js['repository']['name'], js['payload']['id'], auth: @auth)
				c.location = loc
				c.type = type
				c.avatar = avatar
				@api_queries << c
				return
			when 'FollowEvent'
				return	# emotions, if there are, are not from the event
			when 'ForkEvent'
				return	# emotions, if there are, are not from the event
			when 'ForkApplyEvent'
				return	# no example found for now. I will come back later
			when 'GistEvent'
				c = GitHubApi::Gist.new(js['payload']['id'], auth: @auth)
				c.timestamp = Time.parse(js['created_at'])	# Some Gitsts don't have created_at property
				c.location = loc
				c.type = type
				c.avatar = avatar
				@api_queries << c
				return
			when 'GollumEvent'
				return	# ignore for now
			when 'IssueCommentEvent'
				return	# could not find endpoint URL
			when 'IssuesEvent'
				return	# emotions, if there are, are not from the event
			when 'MemberEvent'
				return	# emotions, if there are, are not from the event
			when 'PublicEvent'
				return	# emotions, if there are, are not from the event
			when 'PullRequestEvent'
				c = GitHubApi::SinglePullRequest.new(js['repository']['owner'], js['repository']['name'], js['payload']['number'], auth: @auth)
				c.timestamp = Time.parse(js['created_at'])	# Some PullRequests don't have created_at property
				c.location = loc
				c.type = type
				c.avatar = avatar
				@api_queries << c
				return
			when 'PullRequestReviewCommentEvent'
				comment = js['payload']['comment']['body']
				timestamp = Time.parse(js['created_at'])
				url = js['payload']['comment']['html_url']
				yield Event.new(timestamp, comment, loc, url, type, avatar)
				return
			when 'PushEvent'
				return unless js['repository']
				js['payload']['shas'].each do |sha, email, message, name, distinct|
					c = GitHubApi::Commit.new(js['repository']['owner'], js['repository']['name'], sha, auth: @auth)
					c.location = loc
					c.type = type
					c.avatar = avatar
					@api_queries << c
				end
				return
			when 'TeamAddEvent'
				return	# emotions, if there are, are not from the event
			when 'WatchEvent'
				return	# emotions, if there are, are not from the event
			end
		end

		def EventParser.parse(js, opts = {dry_run: false, auth: nil}, &block)
			EventParser.new(js, opts = {dry_run: false, auth: nil}).parse(&block)
		end

		def EventParser.query_api(api_query)
			begin
				api_query.read_and_parse
				yield Event.new(api_query.timestamp, api_query.comment, api_query.location, api_query.html_url, api_query.type, api_query.avatar)
			rescue OpenURI::HTTPError => e
				message = "#{e.message} (#{e.class}) for #{api_query.json_url} from #{api_query.type}"
				case e.message[0..2]
				when '404'	# Not Found
					raise EventParseIgnorableError.new(message)
				when '500', '502'	# Internal Server Error, Bad Gateway
					raise EventParseRetryableError.new(message)
				when '403', '401', '409', '503'	# we might have hit rate limit
					raise EventParseToWaitError.new(message)
				else
					raise e
				end
			rescue Net::HTTPBadResponse, Errno::ETIMEDOUT => e
				message = "#{e.message} (#{e.class}) for #{api_query.json_url} from #{api_query.type}"
				raise EventParseRetryableError.new(message)
			rescue SocketError, Errno::ENETUNREACH, Errno::ECONNREFUSED => e
				message = "#{e.message} (#{e.class}) for #{api_query.json_url} from #{api_query.type}"
				raise EventParseToWaitError.new(message)
			end
		end
	end
end
