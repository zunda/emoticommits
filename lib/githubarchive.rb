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

module GitHubArchive
	class Event
		attr_reader :timestamp	# Time
		attr_reader :comment	# String
		attr_reader :location	# String
		attr_reader :url	# String
		attr_reader :type	# String
		attr_reader :gravatar_id	# String

		def Event.schema
			{'timestamp' => Time, 'comment' => String, 'location' => String, 'url' => String, 'type' => String, 'gravatar_id' => String}
		end

		def initialize(timestamp, comment, location, url, type, gravatar_id)
			@timestamp = timestamp
			@comment = comment
			@location = location
			@url = url
			@type = type
			@gravatar_id = gravatar_id
		end
		
		def to_h
			result = {}
			Event.schema.keys.each do |key|
				result[key] = self.send(key)
			end
			return result
		end
	end

	# Errors that parser cannot continue but continue parsing other events
	class EventParseError < StandardError; end

	# based upon http://developer.github.com/v3/activity/events/types/
	class EventParser
		# yeilds Event
		# auth: [user, password]
		def EventParser.parse(js, opts = {dry_run: false, auth: nil})
			begin
				dry_run = opts[:dry_run]
				auth = opts[:auth]

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
					unless dry_run
						c = GitHubApi::SingleCommitComment.new(js['repository']['owner'], js['repository']['name'], js['payload']['comment_id'], auth: auth)
						c.read_and_parse
						comment = c.js['body']
						timestamp = c.timestamp
						url = c.js['html_url']
					end
					yield Event.new(timestamp || Time.parse(js['created_at']), comment, loc, url, type, avatar)
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
					unless dry_run
						c = GitHubApi::Download.new(js['repository']['owner'], js['repository']['name'], js['payload']['id'], auth: auth)
						c.read_and_parse
						comment = c.js['description']
						timestamp = c.timestamp
						url = c.js['html_url']
					end
					yield Event.new(timestamp, comment, loc, url, type, avatar)
					return
				when 'FollowEvent'
					return	# emotions, if there are, are not from the event
				when 'ForkEvent'
					return	# emotions, if there are, are not from the event
				when 'ForkApplyEvent'
					return	# no example found for now. I will come back later
				when 'GistEvent'
					unless dry_run
						c = GitHubApi::Gist.new(js['payload']['id'], auth: auth)
						c.read_and_parse
						comment = c.js['description']
						timestamp = c.timestamp
						url = c.js['html_url']
					end
					yield Event.new(timestamp || Time.parse(js['created_at']), comment, loc, url, type, avatar)
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
					unless dry_run
						c = GitHubApi::SinglePullRequest.new(js['repository']['owner'], js['repository']['name'], js['payload']['number'], auth: auth)
						c.read_and_parse
						comment = c.js['body']
						timestamp = c.timestamp
						url = c.js['html_url']
					end
					yield Event.new(timestamp || Time.parse(js['created_at']), comment, loc, url, type, avatar)
					return
				when 'PullRequestReviewCommentEvent'
					comment = js['payload']['comment']['body']
					timestamp = Time.parse(js['created_at'])
					url = js['payload']['comment']['html_url']
					yield Event.new(timestamp, comment, loc, url, type, avatar)
					return
				when 'PushEvent'
					unless dry_run
						js['payload']['shas'].each do |sha, email, message, name, distinct|
							c = GitHubApi::Commit.new(js['repository']['owner'], js['repository']['name'], sha, auth: auth)
							c.read_and_parse
							comment = c.js['commit']['message']
							timestamp = c.timestamp
							url = c.js['html_url']
							yield Event.new(timestamp, comment, loc, url, type, avatar)
						end
					else
						yield Event.new(Time.parse(js['created_at']), nil, loc, nil, type, avatar)
					end
					return
				when 'TeamAddEvent'
					return	# emotions, if there are, are not from the event
				when 'WatchEvent'
					return	# emotions, if there are, are not from the event
				end
			rescue OpenURI::HTTPError => e
				case e.message[0..2]
				when '404'	# Not Found
					raise EventParseError.new("#{e.message} (#{e.class}) for #{c.url} from #{type} created_at #{js['created_at']}")
				else
					raise e
				end
			rescue Net::HTTPBadResponse => e
				raise EventParseError.new("#{e.message} (#{e.class}) for #{c.url} from #{type} created_at #{js['created_at']}")
			end
		end
	end
end
