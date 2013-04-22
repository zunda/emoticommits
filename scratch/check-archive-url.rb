#
# usage: ruby scrach/check-archive-url.rb
# Shows properties of githubarchive jsons
#
# http://data.githubarchive.org/2012-11-04-0.json.gz
#   from 00:00PDT/07:00UTC to 01:00PDT/08:00UTC
# http://data.githubarchive.org/2012-11-04-1.json.gz
#   from 01:00PDT/08:00UTC to 01:00PST/09:00UTC
# http://data.githubarchive.org/2012-11-04-2.json.gz
#   from 02:00PST/10:00UTC to 03:00PST/11:00UTC
# http://data.githubarchive.org/2012-11-04-3.json.gz
#   from 03:00PST/11:00UTC to 04:00PST/12:00UTC
#
# http://data.githubarchive.org/2013-03-10-0.json.gz
#   from 00:00PST/08:00UTC to 01:00PST/09:00UTC
# http://data.githubarchive.org/2013-03-10-1.json.gz
#   from 01:00PST/09:00UTC to 03:00PDT/10:00UTC
# http://data.githubarchive.org/2013-03-10-2.json.gz
#   404 Not Found
# http://data.githubarchive.org/2013-03-10-3.json.gz
#   from 03:00PDT/10:00UTC to 04:00PDT/11:00UTC
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
require 'time'

require 'open-uri'
require 'zlib'
require 'yajl'

def timestr(time)
	"#{time.localtime.strftime("%H:%M%Z")}/#{time.utc.strftime("%H:%M%Z")}"
end

ENV['TZ'] = 'America/Los_Angeles'
%w(
	2012-11-04-0
	2012-11-04-1
	2012-11-04-2
	2012-11-04-3
	2013-03-10-0
	2013-03-10-1
	2013-03-10-2
	2013-03-10-3
).each do |timestr|
	url ="http://data.githubarchive.org/#{timestr}.json.gz"
	puts url
	events = Array.new
	begin
		Yajl::Parser.parse(Zlib::GzipReader.new(open(url)).read) do |ev|
			events << ev
		end
		events.sort_by!{|ev| Time.parse(ev['created_at'])}
		t1 = Time.parse(events[0]['created_at'])
		t2 = Time.parse(events[-1]['created_at'])
		puts "  from #{timestr(t1)} to #{timestr(t2)}"
	rescue OpenURI::HTTPError => e
		puts "  " + e.message
	end
end
