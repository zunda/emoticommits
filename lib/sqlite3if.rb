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

module Schemable
	def to_h
		result = {}
		self.class.schema.keys.each do |key|
			result[key] = self.send(key)
		end
		return result
	end
end

class SQLite3Database < SQLite3::Database
	SQLite3Types = {Time => 'integer', String => 'text', Float => 'real'}

	# Specifies default timeout
	def open(dbpath, timeout = 100)
		db = super(dbpath)
		db.timeout(timeout)
		return db
	end

	# Creates table with schame as a Hash of key:column-name and value:Ruby type
	def create_table(table, schema)
		sql = "CREATE TABLE IF NOT EXISTS #{table} (\n"
		sql << schema.to_a.map{|row, type| "#{row} #{SQLite3Types[type]}"}.join(",\n")
		sql << "\n);"
		execute(sql)
	end

	def insert(table, schema, hash_values)
		keys = schema.keys.join(',')
		placeholders = (['?'] * schema.keys.size).join(',')
		sql = "INSERT INTO #{table}(#{keys}) VALUES (#{placeholders})"
		values = schema.keys.map do |k|
			value = hash_values[k]
			value = value.to_i if schema[k] == Time
			value
		end
		execute(sql, values)
	end

	def select(sql, *args, &block)
		execute("SELECT #{sql};", *args, &block)
	end
end
