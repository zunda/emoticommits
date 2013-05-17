#
# usage: ruby bin/create_markers.rb location-db-path event-db-path dstdir offset-hour
# Creates JSON list of markers from known events and locations
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
require 'syslog/logger'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'githubarchive'
require 'geocoding'
require 'sqlite3if'
require 'marker'

locationdb = SQLite3Database.open(ARGV.shift)
eventdb = SQLite3Database.open(ARGV.shift)
dstdir = ARGV.shift
hour_offset = Integer(ARGV.shift)
t0 = Time.now

$log = Syslog::Logger.new("#{File.basename($0, '.rb')}-#{t0.strftime("%H%M%S")}")

[-7, -1, -0.5].each do |day_offset|
	t1 = Time.at((t0 + day_offset*24*3600 + hour_offset*3600).to_i/3600*3600)
	t2 = t1 +  3600
	$log.info("Listing markers for #{t1} - #{t2}")

	events = Array.new
	eventdb.retrieve('events', GitHubArchive::Event, 'WHERE ? <= timestamp AND timestamp < ?', t1.to_i, t2.to_i).each do |event|
		events << event
	end

	markers = Markers.new
	events.each do |event|
		location = locationdb.retrieve('locations', GoogleApi::Geocoding, 'WHERE address=?', event.location)[0]
		if location and location.status == 'OK'
			begin
				markers << Marker.new(event, location)
			rescue Emoji::Error => e
				$log.error(e.message + " - ignoring")
			end
		end
	end

	dstpath = File.join(dstdir, t1.utc.strftime("%Y%m%d%H.json"))
	File.open(dstpath, 'w') do |f|
		f.print markers.to_json
	end
	$log.info("Created in #{dstpath} #{markers.size} markers from #{events.size} events")
end
