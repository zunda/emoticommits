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
require 'zlib'
require 'yajl'
require 'sqlite3'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'githubarchive'

# e.g.
# @github_auth = ['username', 'password']
class Configuration
	def Configuration.load(path)
		c = Configuration.new()
		begin
			c.instance_eval(File.read(path))
		rescue SystemCallError
		end
		return c
	end
	
	attr_reader :github_auth
end

conf = Configuration.load(File.join(ENV['HOME'], '.githubarchiverc'))

dbpath = ARGV.shift

sqlite_type = {Time => 'integer', String => 'text'}
db = SQLite3::Database.open(dbpath)
db.execute(<<"_END")
create table if not exists events (
#{GitHubArchive::Event.schema.to_a.map{|k, t| "#{k} #{sqlite_type[t]}"}.join(",\n")}
);
_END

keys = GitHubArchive::Event.schema.keys.join(',')
placeholders = (['?'] * GitHubArchive::Event.schema.keys.size).join(',')
db_insert = "INSERT INTO events(#{keys}) VALUES (#{placeholders})"

ARGV.each do |src|
	js = open(src)
	if src =~ /\.gz\Z/
		js = Zlib::GzipReader.new(open(src)).read
	end

	Yajl::Parser.parse(js) do |ev|
		begin
			GitHubArchive::EventParser.parse(ev, dry_run: true, auth: conf.github_auth) do |event|
				h = event.to_h
				values = GitHubArchive::Event.schema.keys.map do |k|
					k != 'timestamp' ?  h[k] : h[k].to_i
				end
				db.execute(db_insert, *values)
			end
		rescue GitHubArchive::EventParseError => e
			$stderr.puts e.message
		end
	end
end

db.close
