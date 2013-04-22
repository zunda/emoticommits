#
# usage: ruby scratch/record_activity.rb event-db-path github-archive-json ...
# Parses github-archive-json and record events to event-db-path
#
# Have ~/.githubarchiverc hold GitHub auth information, e.g.:
# @github_auth = ['username', 'password']
#
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
require 'sqlite3if'

class Configuration < ConfigurationBase
	attr_reader :github_auth
end
conf = Configuration.load('~/.githubarchiverc')
if conf._error_
	$stderr.puts "Warning: #{conf._error_.message}"
end

dbpath = ARGV.shift

db = SQLite3Database.open(dbpath)
db.create_table('events', GitHubArchive::Event.schema)

def print_progress(message)
	$stderr.print "\r#{message}"
end

def print_error(error, message)
	$stderr.puts "\r#{error.message.chomp} - #{message}"
end

max_retry =3
ARGV.each do |src|
	js = open(src)
	if src =~ /\.gz\Z/
		js = Zlib::GzipReader.new(open(src)).read
	end

	Yajl::Parser.parse(js) do |ev|
		current_retry = 0
		begin
			GitHubArchive::EventParser.parse(ev, dry_run: false, auth: conf.github_auth) do |event|
				db.insert('events', event)
				print_progress(event.timestamp.gmtime)
			end
		rescue GitHubArchive::EventParseIgnorableError => e
			print_error(e, "moving onto next entry")
		rescue GitHubArchive::EventParseRetryableError => e
			if current_retry < max_retry
				current_retry += 1
				print_error(e, "retrying after 1 sec(#{current_retry})")
				sleep(1)
				retry
			else
				print_error(e, "moving onto next entry")
			end
		rescue GitHubArchive::EventParseToWaitError => e
			current_retry += 1
			if current_retry < max_retry
				print_error(e, "retrying after 600 sec(#{current_retry})")
				sleep(600)
				retry
			else
				print_error(e, "retrying after 3600 sec(#{current_retry})")
				sleep(3600)
				retry
			end
		end
	end
end

db.close
