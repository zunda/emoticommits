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
$:.unshift(File.join(File.dirname(__FILE__), '..', 'test'))
require 'datapath_helper'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'geocoding'

include GoogleApi

class TestQuery < Test::Unit::TestCase
	def test_uri
		t = Geocoding.new('1600 Amphitheatre Parkway, Mountain View, CA')
		assert_equal('http://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway%2C+Mountain+View%2C+CA&sensor=false', t.uri)
	end

	def test_query
		ts = Time.utc(2013, 4, 15, 1, 2, 3)
		r = Geocoding.new('1600 Amphitheatre Parkway, Mountain View, CA')
		r.read(datapath('geocoding.json'))
		r.parse(ts)
		assert_equal('OK', r.status)
		assert_equal(ts, r.timestamp)
		assert_in_delta(37.42291810, r.lat, 0.005)
		assert_in_delta(-122.08542120, r.lng, 0.005)
	end
end
