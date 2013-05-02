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
require 'uri'
require 'yajl'
require 'socket'

require 'sqlite3if'

# APIs referred from
# https://developers.google.com/maps/documentation/geocoding/
module GoogleApi
	class Geocoding
		URL = URI::parse('http://maps.googleapis.com/maps/api/geocode/json')
		VERSION = '0.0.0'
		AGENT = "zundan@gmail.com - GoogleApi - #{VERSION}"

		def Geocoding.schema
			{'timestamp' => Time, 'address' => Float, 'lat' => Float, 'lng' => Float, 'status' => String}
		end
		include Schemable

		attr_reader :uri

		def initialize(address = nil)
			if address
				@address = address
				uri = URL.dup
				uri.query = URI.encode_www_form('address'=>@address, 'sensor'=>'false')
				@uri = uri.to_s
			end
		end

		def read(uri = nil)
			current_retry = 0
			max_retry = 3
			begin
				@js = Yajl::Parser.parse(open(uri || @uri, 'User-Agent' => AGENT).read)
			rescue SocketError, Errno::ENETUNREACH => e
				if current_retry < max_retry
					current_retry += 1
					sleep(600)
					retry
				end
				raise e
			end
		end

		def parse(timestamp = Time.now)
			@status = @js['status']
			if @status == 'OK'
				@lat = @js['results'][0]['geometry']['location']['lat']
				@lng = @js['results'][0]['geometry']['location']['lng']
			end
			@timestamp = timestamp
		end

		def Geocoding.query(address, timestamp = Time.now)
			r = Geocoding.new(address)
			r.read
			r.parse(timestamp)
			return r
		end
	end
end
