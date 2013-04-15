#sudo apt-get install sqlite3 sqlite3-pcre
.load /usr/lib/sqlite3/pcre.so
SELECT * FROM events WHERE comment REGEXP ':\w+:';

