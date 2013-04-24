#
# usage: ruby start-time end-time scratch/create_markers.rb location-db-path event-db-path... > json
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

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'githubarchive'
require 'geocoding'
require 'sqlite3if'
require 'marker'

t0 = Time.parse(ARGV.shift)
t1 = Time.parse(ARGV.shift)
$stderr.puts "Extracting events from #{t0.utc} to #{t1.utc}"

locationdb = SQLite3Database.open(ARGV.shift)

events = Array.new
ARGV.each do |eventdbpath|
	eventdb = SQLite3Database.open(eventdbpath)
	eventdb.retrieve('events', GitHubArchive::Event, 'WHERE ? <= timestamp AND timestamp < ?', t0.to_i, t1.to_i).each do |event|
		events << event
	end
end

markers = Markers.new
events.each do |event|
	location = locationdb.retrieve('locations', GoogleApi::Geocoding, 'WHERE address=?', event.location)[0]
	if location and location.status == 'OK'
		markers << Marker.new(event, location)
	end
end

puts markers.to_json
