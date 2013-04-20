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

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'emoji'

class TestScanner < Test::Unit::TestCase
	def test_detection
		assert_equal(':smile:', Emoji::Scanner.first_emoji('hello world :smile:'))
	end

	def test_only_first
		assert_equal(':smile:', Emoji::Scanner.first_emoji(':smile: :smiley:'))
	end

	def test_plus_detect
		assert(Emoji::EMOJIS.include?('+1'))
		assert_equal(':+1:', Emoji::Scanner.first_emoji(':+1:'))
	end

	def test_minus_detect
		assert(Emoji::EMOJIS.include?('-1'))
		assert_equal(':-1:', Emoji::Scanner.first_emoji(':-1:'))
	end

	def test_bar_detect
		assert(Emoji::EMOJIS.include?('floppy_disk'))
		assert_equal(':floppy_disk:', Emoji::Scanner.first_emoji(':floppy_disk:'))
	end

	def test_number_detect
		assert(Emoji::EMOJIS.include?('1234'))
		assert_equal(':1234:', Emoji::Scanner.first_emoji(':1234:'))
	end

	def test_no_detectoin
		assert_equal(nil, Emoji::Scanner.first_emoji('hello world 12:34:56'))
	end

	def test_no_detection_with_space
		assert_equal(nil, Emoji::Scanner.first_emoji(':smi le:'))
	end
end
