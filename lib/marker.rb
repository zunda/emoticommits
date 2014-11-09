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

require 'yajl'

require 'githubarchive'
require 'geocoding'
require 'sqlite3if'
require 'emoji'

class Marker
	GravatarUrl = 'http://www.gravatar.com/avatar/%s?d=http%%3A%%2F%%2Fassets.github.com%%2Fimages%%2Fgravatars%%2Fgravatar-user-420.png'
	EmoticonUrl = 'http://assets.github.com/images/icons/emoji/%s.png'

	def Marker.schema
		{'time' => Time, 'emotion' => TrueClass, 'lat' => Float, 'lng' => Float, 'icon' => String, 'url' => String}
	end
	include Schemable

	def to_json(*args, &block)
		# http://geojson.org/geojson-spec.html
		props = {:time => @time.iso8601, :emotion => @emotion, :icon => @icon, :url => @url}
		Yajl::Encoder.encode(
			{:type => 'Point', :coordinates => [@lat, @lng], :properties => props},
			args, block)
	end

	def initialize(event = nil, geocoding = nil)
		@time = event.timestamp
		@lat = geocoding.lat
		@lng = geocoding.lng
		@url = event.url
		emoji = Emoji::Scanner.first_emoji(event.comment)
		if emoji
			@emotion = true
			@icon = EmoticonUrl % emoji[1..-2]	# strip :'s
		else
			@emotion = false
			@icon = GravatarUrl % event.gravatar_id
		end
	end
end

class Markers < Array
	def to_json(*args, &block)
		# http://geojson.org/geojson-spec.html
		Yajl::Encoder.encode(
			{:type => 'GeometryCollection', :geometries => self.sort_by{|x| x.time}},
			args, block)
	end
end
