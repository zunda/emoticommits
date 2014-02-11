#
# Copyright (c) 2014 zunda <zunda at freeshell.org>
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

# This is to test the changes from GitHub API Beta to V3
# http://developer.github.com/v3/versions/
# that may affect this application.

require 'test/unit'
require 'zlib'
require 'net/http'	# for Net::ReadTimeout

$:.unshift(File.join(File.dirname(__FILE__), '..', 'test'))
require 'datapath_helper'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'conf'
require 'githubapi'

class Configuration < ConfigurationBase
	attr_reader :github_auth
end
conf = Configuration.load('~/.githubarchiverc')
if conf._error_
	$stderr.puts "Warning: #{conf._error_.message}"
	exit 1
end
$auth = conf.github_auth

def prep_githubarchive
	basename = "2014-02-10-22.json"
	js = Zlib::GzipReader.new(open("http://data.githubarchive.org/#{basename}.gz")).read
	File.open(datapath(basename), 'w') do |f|
		f.write js
	end
end

class TestApi < Test::Unit::TestCase
	# Gist
	# The `user` (beta) or `owner` (V3) are not used

	# Issue
	# Omitted `pull_request` is not used

	# Repository
	# Omitted `master_branch` or recommended `default_branch` are not used

	# User Emails
	# not used

	# Following deprecated paths and parameters are not used
	# /gists/:id/fork or /gists/:id/forks
	# /legacy/issues/search/:owner/:repository/:state/:keyword
	# /legacy/repos/search/:keyword
	# /legacy/user/search/:keyword
	# /legacy/user/email/:email
	# /repos/:owner/:repo/hooks/:id/test or /repos/:owner/:repo/hooks/:id/tests
	# /repos/:owner/:repo/forks
	# merge_commit_sha for pull request
	# rate or resources[“core”] for rate limit
	# forks or fork_count for repository
	# master_branch or default_branch for repository
	# open_issues or open_issues_count for repository
	# public for repository
	# wathcers or watcher_count for repository
	# bio for user
	# gravatar_url or avator_url are not used - but GravatarUrl is generated

	def test_basic_query
		skip('OK on 2014-02-10 with githubapi.rb - 0.2.0 with accept header for API V3')
		c = GitHubApi::Commit.new('zunda', 'emoticommits', 'dae5ae97d721acef8748e3dbfadab001b175a8f3', auth: $auth)
		c.read_and_parse
		assert_equal('auto commit', c.comment)
		assert_equal('https://github.com/zunda/emoticommits/commit/dae5ae97d721acef8748e3dbfadab001b175a8f3', c.html_url)
	end
end

# prep_githubarchive
