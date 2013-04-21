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

require 'test/unit'
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'marker'

class TestMarker < Test::Unit::TestCase
	def test_avatar_marker
		location = GoogleApi::Geocoding.new
		location.lat = 19.7297222
		location.lng = -155.09
		event = GitHubArchive::Event.new
		event.timestamp = Time.utc(2013, 4, 20, 1, 2, 3)
		event.comment = 'usual comment'
		event.url = 'http://example.com/'
		event.gravatar_id = 'deadbeef'
		marker = Marker.new(event, location)
		assert_equal(event.timestamp, marker.time)
		assert_equal(false, marker.emotion)
		assert_equal(location.lat, marker.lat)
		assert_equal(location.lng, marker.lng)
		assert_equal('http://www.gravatar.com/avatar/' + event.gravatar_id, marker.icon)
		assert_equal(event.url, marker.url)
	end

	def test_emotion_marker
		location = GoogleApi::Geocoding.new
		location.lat = 19.7297222
		location.lng = -155.09
		event = GitHubArchive::Event.new
		event.timestamp = Time.utc(2013, 4, 20, 1, 2, 3)
		event.comment = ':smile: comment'
		event.url = 'http://example.com/'
		event.gravatar_id = 'deadbeef'
		marker = Marker.new(event, location)
		assert_equal(event.timestamp, marker.time)
		assert_equal(true, marker.emotion)
		assert_equal(location.lat, marker.lat)
		assert_equal(location.lng, marker.lng)
		assert_equal('http://assets.github.com/images/icons/emoji/smile.png', marker.icon)
		assert_equal(event.url, marker.url)
	end
end

