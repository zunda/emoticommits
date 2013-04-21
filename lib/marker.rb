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

require 'githubarchive'
require 'geocoding'
require 'sqlite3if'
require 'emoji'

class Marker
	GravatarUrl = 'http://www.gravatar.com/avatar/%s'
	EmoticonUrl = 'http://assets.github.com/images/icons/emoji/%s.png'

	def Marker.schema
		{'time' => Time, 'emotion' => TrueClass, 'lat' => Float, 'lng' => Float, 'icon' => String, 'url' => String}
	end
	include Schemable

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
