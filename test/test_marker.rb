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

def sample_location
	unless @sample_location
		@sample_location = GoogleApi::Geocoding.new
		@sample_location.lat = 19.7297222
		@sample_location.lng = -155.09
	end
	return @sample_location
end

def sample_usual_event
	unless @sample_usual_event
		@sample_usual_event = GitHubArchive::Event.new
		@sample_usual_event.timestamp = Time.utc(2013, 4, 20, 1, 2, 3)
		@sample_usual_event.comment = 'usual comment'
		@sample_usual_event.url = 'http://example.com/usual'
		@sample_usual_event.gravatar_id = 'deadbeef'
	end
	return @sample_usual_event
end

def sample_emotional_event
	unless @sample_emotional_event
		@sample_emotional_event = GitHubArchive::Event.new
		@sample_emotional_event.timestamp = Time.utc(2013, 4, 20, 1, 2, 4)
		@sample_emotional_event.comment = ':smile: comment'
		@sample_emotional_event.url = 'http://example.com/emotoinal'
		@sample_emotional_event.gravatar_id = 'deadbeef'
	end
	return @sample_emotional_event
end

class TestMarker < Test::Unit::TestCase
	def test_avatar_marker
		marker = Marker.new(sample_usual_event, sample_location)
		assert_equal(sample_usual_event.timestamp, marker.time)
		assert_equal(false, marker.emotion)
		assert_equal(sample_location.lat, marker.lat)
		assert_equal(sample_location.lng, marker.lng)
		assert_equal(Marker::GravatarUrl % sample_usual_event.gravatar_id, marker.icon)
		assert_equal(sample_usual_event.url, marker.url)
	end

	def test_emotion_marker
		marker = Marker.new(sample_emotional_event, sample_location)
		assert_equal(sample_emotional_event.timestamp, marker.time)
		assert_equal(true, marker.emotion)
		assert_equal(sample_location.lat, marker.lat)
		assert_equal(sample_location.lng, marker.lng)
		assert_equal('http://assets.github.com/images/icons/emoji/smile.png', marker.icon)
		assert_equal(sample_emotional_event.url, marker.url)
	end

	def test_to_json
		m = Marker.new(sample_emotional_event, sample_location)
		js = Yajl::Parser.parse(m.to_json)
		assert_equal(sample_emotional_event.timestamp, Time.parse(js['time']))
		assert_equal(true, js['emotion'])
		assert_equal(sample_location.lat, js['lat'])
		assert_equal(sample_location.lng, js['lng'])
		assert_equal('http://assets.github.com/images/icons/emoji/smile.png', js['icon'])
		assert_equal(sample_emotional_event.url, js['url'])
	end
end

class TestMarkers < Test::Unit::TestCase
	def test_markers_to_json
		m = Markers.new([
			Marker.new(sample_emotional_event, sample_location),
			Marker.new(sample_usual_event, sample_location)
		])
		js = Yajl::Parser.parse(m.to_json)
		assert_equal(sample_usual_event.timestamp, Time.parse(js[0]['time']))
		assert_equal(false, js[0]['emotion'])
		assert_equal(sample_location.lat, js[0]['lat'])
		assert_equal(sample_location.lng, js[0]['lng'])
		assert_equal(Marker::GravatarUrl % sample_usual_event.gravatar_id, js[0]['icon'])
		assert_equal(sample_usual_event.url, js[0]['url'])
		assert_equal(sample_emotional_event.timestamp, Time.parse(js[1]['time']))
		assert_equal(true, js[1]['emotion'])
		assert_equal(sample_location.lat, js[1]['lat'])
		assert_equal(sample_location.lng, js[1]['lng'])
		assert_equal('http://assets.github.com/images/icons/emoji/smile.png', js[1]['icon'])
		assert_equal(sample_emotional_event.url, js[1]['url'])
	end
end
