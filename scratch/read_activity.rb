#
# usage: ruby scrach/read_activity.rb github-archive-json
# Prints content of the data while querying some from GitHub
#
#
# An example of number of events:
# $ ruby scratch/read_activity.rb 2013-04-12-18.json.gz | sort |\
#  uniq -c | sort -nr
#   1315 PushEvent
#    251 CreateEvent
#    109 PullRequestEvent
#     22 CommitCommentEvent
#     11 GistEvent
#     10 PullRequestReviewCommentEvent
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
require 'zlib'
require 'yajl'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'githubarchive'
require 'conf'

# e.g.
# @github_auth = ['username', 'password']
class Configuration < ConfigurationBase
	attr_reader :github_auth
end
conf = Configuration.load('~/.githubarchiverc')
if conf._error_
	$stderr.puts "Warning: #{conf._error_.message}"
end

ARGV.each do |src|
	js = open(src)
	if src =~ /\.gz\Z/
		js = Zlib::GzipReader.new(open(src)).read
	end

	Yajl::Parser.parse(js) do |ev|
		begin
			GitHubArchive::EventParser.parse(ev, dry_run: false, auth: conf.github_auth) do |event|
				%w(type timestamp location url gravatar_id).each do |el|
					puts "#{el}: #{event.send(el)}"
				end
				puts '-----'
				puts event.comment
				puts '-----'
				puts
			end
		rescue GitHubArchive::EventParseError => e
			$stderr.puts e.message
		end
	end
end
