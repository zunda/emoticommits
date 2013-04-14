require 'githubapi/endpoints'

module GitHubArchive
	class Event
		attr_reader :timestamp	# Time
		attr_reader :comment	# String
		attr_reader :location	# String
		attr_reader :url	# String
		attr_reader :type	# String
		attr_reader :gravatar_id	# String

		def initialize(timestamp, comment, location, url, type, gravatar_id)
			@timestamp = timestamp
			@comment = comment
			@location = location
			@url = url
			@type = type
			@gravatar_id = gravatar_id
		end
	end

	class EventParser
		# yeilds Event
		def EventParser.parse(js)
			actor = js['actor_attributes']
			return unless actor

			loc = actor['location']
			return unless loc
			avatar = actor['gravatar_id']
			return unless avatar

			type = js['type']
			case type
			when 'CommitCommentEvent'
				c = GitHub::SingleCommitComment.new(js['repository']['owner'], js['repository']['name'], js['payload']['comment_id'])
				c.read_and_parse
				comment = c.js['body']
				timestamp = c.timestamp
				url = c.js['html_url']
				yield Event.new(timestamp, comment, loc, url, type, avatar)
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
				c = GitHub::Download.new(js['repository']['owner'], js['repository']['name'], js['payload']['id'])
				c.read_and_parse
				comment = c.js['description']
				timestamp = c.timestamp
				url = c.js['html_url']
				yield Event.new(timestamp, comment, loc, url, type, avatar)
				return
			when 'FollowEvent'
				return	# emotions, if there are, are not from the event
			when 'ForkEvent'
				return	# emotions, if there are, are not from the event
			when 'ForkApplyEvent'
				return	# no example found for now. I will come back later
			when 'GistEvent'
				c = GitHub::Gist.new(js['payload']['id'])
				c.read_and_parse
				comment = c.js['description']
				timestamp = c.timestamp
				url = c.js['html_url']
				yield Event.new(timestamp, comment, loc, url, type, avatar)
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
				c = GitHub::SinglePullRequest.new(js['repository']['owner'], js['repository']['name'], js['payload']['number'])
				c.read_and_parse
				comment = c.js['body']
				timestamp = c.timestamp
				url = c.js['html_url']
				yield Event.new(timestamp, comment, loc, url, type, avatar)
				return
			when 'PullRequestReviewCommentEvent'
				comment = js['payload']['comment']['body']
				timestamp = Time.parse(js['created_at'])
				url = js['payload']['comment']['html_url']
				yield Event.new(timestamp, comment, loc, url, type, avatar)
				return
			when 'PushEvent'
				js['payload']['shas'].each do |sha, email, message, name, distinct|
					c = GitHub::Commit.new(js['repository']['owner'], js['repository']['name'], sha)
					c.read_and_parse
					comment = c.js['commit']['message']
					timestamp = c.timestamp
					url = c.js['html_url']
					yield Event.new(timestamp, comment, loc, url, type, avatar)
				end
				return
			when 'TeamAddEvent'
				return	# emotions, if there are, are not from the event
			when 'WatchEvent'
				return	# emotions, if there are, are not from the event
			end
		end
	end
end
