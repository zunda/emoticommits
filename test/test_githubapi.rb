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
require 'zlib'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'test'))
require 'datapath_helper'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'githubapi'

include GitHubApi

class StubFile; end

class TestApi < Test::Unit::TestCase
	def test_timestamp
		t = Base.new(datapath('SingleCommitComment.json'))
		t.read_and_parse
		assert_equal(Time.utc(2013,4,12,18,1,44), t.timestamp)
	end

	def test_econnreset
		t = Base.new(datapath('SingleCommitComment.json'))
		def t.open(*args)
			x = StubFile.new
			def x.read(*args)
				raise Errno::ECONNRESET
			end
			return x
		end
		assert_raises(ReadError){t.read_and_parse}
	end

	def test_readtimeout
		t = Base.new(datapath('SingleCommitComment.json'))
		def t.open(*args)
			x = StubFile.new
			def x.read(*args)
				raise Net::ReadTimeout
			end
			return x
		end
		assert_raises(ReadError){t.read_and_parse}
	end
end

class TestSingleCommitComment < Test::Unit::TestCase
	def test_json_url
		t = SingleCommitComment.new('zunda', 'test', '1')
		assert_equal("#{Base::HOST}/repos/zunda/test/comments/1", t.json_url)
	end
end

class TestDownload < Test::Unit::TestCase
	def test_json_url
		t = Download.new('zunda', 'test', '1')
		assert_equal("#{Base::HOST}/repos/zunda/test/downloads/1", t.json_url)
	end
end

class TestGist < Test::Unit::TestCase
	def test_json_url
		t = Gist.new('1')
		assert_equal("#{Base::HOST}/gists/1", t.json_url)
	end
end

class TestSinglePullRequest < Test::Unit::TestCase
	def test_json_url
		t = SinglePullRequest.new('zunda', 'test', '1')
		assert_equal("#{Base::HOST}/repos/zunda/test/pulls/1", t.json_url)
	end
end

class TestCommit < Test::Unit::TestCase
	def test_json_url
		t = Commit.new('zunda', 'test', '1')
		assert_equal("#{Base::HOST}/repos/zunda/test/commits/1", t.json_url)
	end

	def test_parse
		t = Base.new(datapath('382ef451cee512f798c624d51b5fd372670f2063.json'))
		assert_nothing_raised{t.read_and_parse}
	end
end
