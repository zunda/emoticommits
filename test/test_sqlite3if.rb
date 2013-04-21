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
require 'tmpdir'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'sqlite3if'

class TestObject
	def TestObject.schema
		{'time' => Time, 'string' => String, 'integer' => Integer, 'float' => Float}
	end
	include Schemable
end

class TestSQLite3Database < Test::Unit::TestCase
	def test_single_insert_and_retrieve
		t = TestObject.new
		t.time = Time.utc(2013, 4, 15, 1, 2, 3)
		t.string = 'Hello'
		t.integer = 42
		t.float = 3.14

		Dir::Tmpname.create(File.basename(__FILE__, '.rb')) do |dbpath|
			db = SQLite3Database.open(dbpath)
			db.create_table('testtable', TestObject.schema)
			db.insert('testtable', t)
			obj = db.retrieve('testtable', TestObject, '')[0]
			assert_equal(obj.time, t.time)
			assert_equal(obj.string, t.string)
			assert_equal(obj.integer, t.integer)
			assert_equal(obj.float, t.float)
		end
	end

	def test_two_insert_and_retrieve
		t = TestObject.new
		t.time = Time.utc(2013, 4, 15, 1, 2, 3)
		t.string = 'Hello'
		t.integer = 42
		t.float = 3.14
		
		u = TestObject.new
		u.time = Time.utc(2013, 4, 15, 1, 2, 4)
		u.string = 'Good bye'
		u.integer = 43
		u.float = 3.14

		Dir::Tmpname.create(File.basename(__FILE__, '.rb')) do |dbpath|
			db = SQLite3Database.open(dbpath)
			db.create_table('testtable', TestObject.schema)
			db.insert('testtable', t)
			db.insert('testtable', u)
			obj = db.retrieve('testtable', TestObject, '')
			assert_equal(obj[0].time, t.time)
			assert_equal(obj[0].string, t.string)
			assert_equal(obj[0].integer, t.integer)
			assert_equal(obj[0].float, t.float)
			assert_equal(obj[1].time, u.time)
			assert_equal(obj[1].string, u.string)
			assert_equal(obj[1].integer, u.integer)
			assert_equal(obj[1].float, u.float)
		end
	end

	def test_insert_and_retrieve_with_block
		t = TestObject.new
		t.time = Time.utc(2013, 4, 15, 1, 2, 3)
		t.string = 'Hello'
		t.integer = 42
		t.float = 3.14
		
		u = TestObject.new
		u.time = Time.utc(2013, 4, 15, 1, 2, 4)
		u.string = 'Good bye'
		u.integer = 43
		u.float = 3.14

		Dir::Tmpname.create(File.basename(__FILE__, '.rb')) do |dbpath|
			db = SQLite3Database.open(dbpath)
			db.create_table('testtable', TestObject.schema)
			db.insert('testtable', t)
			db.insert('testtable', u)
			r = Array.new
			db.retrieve('testtable', TestObject, '') do |obj|
				r << obj
			end
			assert_equal(r[0].time, t.time)
			assert_equal(r[0].string, t.string)
			assert_equal(r[0].integer, t.integer)
			assert_equal(r[0].float, t.float)
			assert_equal(r[1].time, u.time)
			assert_equal(r[1].string, u.string)
			assert_equal(r[1].integer, u.integer)
			assert_equal(r[1].float, u.float)
		end
	end
end
