#
# usage: ruby update.emojis.rb
#
# Updates lib/emojis.rb from the list of png files
# in emoji-cheat-sheet.com/public/graphics/emojis
# which should be an updated clone of
# git://github.com/arvida/emoji-cheat-sheet.com.git
#
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

# Extract file names from submodule cloned from
# git://github.com/arvida/emoji-cheat-sheet.com.git
emojis_dir = File.join(File.dirname(__FILE__), 'emoji-cheat-sheet.com/public/graphics/emojis')
emojis = Dir.glob(emojis_dir + '/*.png').map{|n| File.basename(n, '.png')}.sort

# Create a library
dstpath = File.join(File.dirname(__FILE__), 'lib/emojis.rb')
File.open(dstpath, 'w') do |f|
	f.puts <<-"_END"
# Created by #{__FILE__}
# with emojis extracted from #{emojis_dir}
module Emoji
	EMOJIS = [
		#{emojis.map{|n| "'#{n}'"}.join(",\n\t\t")}
	]
end
	_END
end

