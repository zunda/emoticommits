emoticommits
============

Commits and comments with emotions are good for your health :smile:

Have a look at http://zunda.github.io/emoticommits/

Extracting commits and comments with locations
----------------------------------------------
A server runs [record_activity.rb](bin/record_activity.rb) as an [hourly cron job](etc/crontab) parses hourly JSON file from [GitHub Archive](http://www.githubarchive.org). The process extracts events from the JSON file, queries [GitHub API](http://developer.github.com/) when needed, and stores them into an SQLite3 database. Afterwards, it looks up GitHub users' locations from GeoCoding results stored in another SQLite3 database, and queries the [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/) up to 100 locaitons, so that queries will be within the rate limit of 2,500/day.
