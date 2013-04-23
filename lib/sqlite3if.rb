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
	def Schemable.included(mod)
		mod.schema.keys.each do |key|
			class_eval("attr_accessor :#{key}")
		end
	end
end

class SQLite3Database < SQLite3::Database
	SQLite3Types = {Time => 'integer', String => 'text', Float => 'real', TrueClass => 'integer'}

	def initialize(*args)
		super(*args)
		@timeout = 0.1
		@max_retry = 10
	end

	# Specifies default timeout
	def open(dbpath, timeout = 100)
		db = super(dbpath)
		db.timeout(timeout)
		@timeout = timeout/1000.0
		return db
	end

	def execute_with_retry(sql, *args, &block)
		current_retry = 0
		begin
			execute(sql, *args, &block)
		rescue SQLite3::BusyException
			raise if current_retry >= @max_retry
			current_retry += 1
			sleep(@timeout)
			retry
		end
	end

	# Creates table with schame as a Hash of key:column-name and value:Ruby type
	def create_table(table, schema)
		sql = "CREATE TABLE IF NOT EXISTS #{table} (\n"
		sql << schema.to_a.map{|row, type| "#{row} #{SQLite3Types[type]}"}.join(",\n")
		sql << "\n);"
		execute_with_retry(sql)
	end

	def insert(table, obj)
		schema = obj.class.schema
		keys = schema.keys.join(',')
		placeholders = (['?'] * schema.keys.size).join(',')
		sql = "INSERT INTO #{table}(#{keys}) VALUES (#{placeholders})"
		values = schema.keys.map do |k|
			value = obj.send(k)
			value = value.to_i if schema[k] == Time
			value = value ? 1 : 0 if schema[k] == TrueClass
			value
		end
		execute_with_retry(sql, values)
	end

	def select(sql, *args, &block)
		execute_with_retry("SELECT #{sql};", *args, &block)
	end

	def retrieve_with_block(table, klass, where, *args)
		keys = klass.schema.keys.join(',')
		execute_with_retry("SELECT * from #{table} #{where};", *args).each do |row|
			obj = klass.new
			klass.schema.keys.each_with_index do |key, i|
				value = row[i]
				value = Time.at(value) if klass.schema[key] == Time and value
				value = (value == 1) if klass.schema[key] == TrueClass and value
				obj.send("#{key}=", value)
			end
			yield(obj)
		end
	end
	private :retrieve_with_block

	def retrieve(table, klass, where, *args, &block) 
		if block_given?
			return retrieve_with_block(table, klass, where, *args, &block)
		else
			result = Array.new
			retrieve_with_block(table, klass, where, *args) do |obj|
				result << obj
			end
			return result
		end
	end
end
