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

require 'sqlite3'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'geocoding'
require 'conf'

dbpath = ARGV.shift

sqlite_type = {Time => 'integer', String => 'text', Float => 'real'}
db = SQLite3::Database.open(dbpath)
db.execute(<<"_END")
create table if not exists locations (
#{GoogleApi::Geocoding.schema.to_a.map{|k, t| "#{k} #{sqlite_type[t]}"}.join(",\n")}
);
_END

keys = GoogleApi::Geocoding.schema.keys.join(',')
placeholders = (['?'] * GoogleApi::Geocoding.schema.keys.size).join(',')
db_insert = "INSERT INTO locations(#{keys}) VALUES (#{placeholders})"

ARGV.each do |address|
	location = GoogleApi::Geocoding.query(address)
	h = location.to_h
	values = GoogleApi::Geocoding.schema.keys.map do |k|
		k != 'timestamp' ? h[k] : h[k].to_i
	end
	db.execute(db_insert, *values)
end

db.close
