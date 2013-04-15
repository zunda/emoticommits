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
require 'githubarchive'

include GitHubArchive

class TestEvent < Test::Unit::TestCase
	V = {'timestamp' => Time.utc(2013, 4, 14, 0, 0, 0, 0),
		'comment' => 'Hello World',
		'location' => 'In the sky',
		'url' => 'http://localhost/',
		'type' => 'Type',
		'gravatar_id' => 'unknown'
	}

	def setup
		@t = Event.new(V['timestamp'], V['comment'], V['location'], V['url'], V['type'], V['gravatar_id'])
	end

	def test_to_h
		assert_equal(V.sort, @t.to_h.sort)
	end

	def test_attr_reader
		V.keys.each do |k|
			assert_equal(V[k], @t.send(k))
		end
	end
end
