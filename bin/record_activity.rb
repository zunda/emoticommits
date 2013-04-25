#
# usage: ruby bin/record_activity.rb \
#        ~/var/events.sqlite ~/var/locations.sqlite 90
#
# Parses github-archive-json and record events and locations
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
require 'syslog/logger'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'githubarchive'
require 'geocoding'
require 'conf'
require 'sqlite3if'

def githubarchive_url(time)
	tzorig = ENV['TZ']
	ENV['TZ'] = 'America/Los_Angeles'
	r = time.localtime.strftime("http://data.githubarchive.org/%Y-%m-%d-%%d.json.gz") % time.localtime.hour
	ENV['TZ'] = tzorig
	return r
end

def print_error(log, error, message)
	print_message(log, "#{error.message.chomp} - #{message}")
end

def print_message(log, message)
	log.info(message)
end

def random_wait(seconds)
	sleep((rand + 0.5) * seconds)
end

class GiveUp < StandardError; end

class Configuration < ConfigurationBase
	attr_reader :github_auth
end
conf = Configuration.load('~/.githubarchiverc')
if conf._error_
	$stderr.puts "Warning: #{conf._error_.message}"
end

# Command line arguments
eventdbpath = ARGV.shift
locationdbpath = ARGV.shift
offsetmins = Integer(ARGV.shift)

# Databases
eventdb = SQLite3Database.open(eventdbpath)
eventdb.create_table('events', GitHubArchive::Event.schema)
processed_events = 0
locationdb = SQLite3Database.open(locationdbpath)
locationdb.create_table('locations', GoogleApi::Geocoding.schema)
processed_addresses = 0

# Read githubarchive JSON
json_url = githubarchive_url(Time.now - offsetmins * 60)
json_id = File.basename(json_url, '.json.gz')
$log = Syslog::Logger.new("#{File.basename($0, '.rb')}-#{json_id}")
print_message($log, "Starting to parse #{json_url}")
at_exit{print_message($log, "exiting after processing #{processed_events} events and #{processed_addresses} addresses")}

max_retry = 2
current_retry = 0
js = nil
begin
	js = Zlib::GzipReader.new(open(json_url)).read
rescue OpenURI::HTTPError => e
	print_error($log, e, json_url)
	if current_retry < max_retry
		case e.message[0..2]
		when '404'
			current_retry += 1
			print_message($log, "retrying in about 600 seconds (#{current_retry})")
			random_wait(600)
			print_message($log, "resuming ...")
			retry
		end
	end
	print_message($log, "Giving up")
rescue SocketError, Errno::ENETUNREACH => e	# Temporary failure in name resolution
	print_error($log, e, json_url)
	if current_retry < max_retry
		current_retry += 1
		print_message($log, "retrying in about 600 seconds (#{current_retry})")
		random_wait(600)
		print_message($log, "resuming ...")
		retry
	end
	print_message($log, "Giving up")
end

# Parse githubarchive JSON
locations = Array.new
begin
	js and Yajl::Parser.parse(js) do |ev|
		current_retry = 0
		begin
			GitHubArchive::EventParser.parse(ev, dry_run: false, auth: conf.github_auth) do |event|
				eventdb.insert('events', event)
				locations << event.location
			end
		rescue GitHubArchive::EventParseIgnorableError => e
			#print_error($log, e, "moving onto next entry")
		rescue GitHubArchive::EventParseRetryableError => e
			if current_retry < max_retry
				current_retry += 1
				print_error($log, e, "retrying after about 1 sec (#{current_retry})")
				random_wait(1)
				retry
			else
				print_error($log, e, "moving onto next entry")
			end
		rescue GitHubArchive::EventParseToWaitError => e
			current_retry += 1
			if current_retry < max_retry
				print_error($log, e, "retrying in about 600 sec (#{current_retry})")
				random_wait(600)
				$log.info("resuming ...")
				retry
			else
				print_error($log, e, "Giving up")
				raise GiveUp
			end
		end
		processed_events += 1
	end
rescue GiveUp
end
eventdb.close

# Query some locations
print_message($log, "querying locations")

maxquery = 100
queries = 0
locations.shuffle.each do |address|
	if locationdb.select('COUNT(*) FROM locations WHERE (status = "OK" or status = "ZERO_RESULTS") and address = ?', address)[0][0] < 1
		location = GoogleApi::Geocoding.query(address)
		locationdb.insert('locations', location)
		queries += 1
	end
	processed_addresses += 1
	break if queries >= maxquery
end
locationdb.close

print_message($log, "finished")
