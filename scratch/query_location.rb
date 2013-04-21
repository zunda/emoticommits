#
# usage: ruby scrach/query_location.rb event-db-path location-db-path
# Queries up to 10 locations of events and store them
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

eventdb = SQLite3Database.open(ARGV.shift)
locationdb = SQLite3Database.open(ARGV.shift)
maxquery = 10

queries = 0
eventdb.select('DISTINCT location FROM events').map{|e| e[0]}.shuffle.each do |address|
	if locationdb.select('COUNT(*) FROM locations WHERE (status = "OK" or status = "ZERO_RESULTS") and address = ?', address)[0][0] < 1
		print "#{address} => "
		location = GoogleApi::Geocoding.query(address)
		locationdb.insert('locations', location)
		case location.status
		when 'OK'
			puts "#{location.lat},#{location.lng}"
		else
			puts location.status
		end
		queries += 1
	end
	break if queries >= maxquery
end
