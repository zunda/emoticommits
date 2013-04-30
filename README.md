emoticommits
============

Commits and comments with emotions are good for your health :smile:

Have a look at http://zunda.github.io/emoticommits/. The map shows commits and comments of GitHub users, along with their avatars, or, better than those, emoticons :smiley: from commit messages or comments. Please note that *not all activities are shown*.

The idea of showing acitivities on a world map heavily comes from the late [Hello world! - greetings to the planet](http://www.lizard-tail.com/isana/lab/hello_world/) by which showed greetings from Twitter users real time. The big difference seems to be that the GitHub users do not care much about if it is day or night :grinning:

Implementation
--------------
### Extracting commits and comments with locations
A server runs [record_activity.rb](bin/record_activity.rb) as an [hourly cron job](etc/crontab) that parses hourly JSON file from [GitHub Archive](http://www.githubarchive.org). The process extracts events from the JSON file, queries [GitHub API](http://developer.github.com/) when needed, and stores them into an SQLite3 database. It seems that about half of events can be queired within the limited time - meaning that *not all activities are shown on the map*. Queries are shuffled before executed so events are distributed evenly in the time period. Afterwards, it looks up GitHub users' locations from GeoCoding results stored in another SQLite3 database, and queries the [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/) up to 100 locaitons, so that queries will be within the rate limit of 2,500/day.

### Creating JSON files for markers on the map
The [map](http://zunda.github.io/emoticommits/) loads a JSON file of markers thorugh [markers.js](../gh-pages/javascripts/markers.js), which show commits or comments along with users' location, every hour on 50 minutes.

As the map shows evetns of either 24 hours ago or 7 days ago, JSON files of markers for 23 hours ago and 7 days minus 1 hour ago are created, by [create_markers.rb] (bin/create_markers.rb) as another [cron job](etc/crontab), from the local databases every hour and automatically committed and pushed to the [GitHub pages](http://zunda.github.io/emoticommits/).

### Displaying night on the map
The [map](http://zunda.github.io/emoticommits/) shows day and night areas through [sun.js](../gh-pages/javascripts/sun.js). The JavaScript calculates direction (latitude and longitude) of the Sun on the earth and creates paths, as great cicles on the Earth surface, for the night shade divided into four areas. A [```google.maps.Polygon```](https://developers.google.com/maps/documentation/javascript/reference#Polygon) converts the great circles onto the Mercator map with the [```geodesic: true``` option](https://developers.google.com/maps/documentation/javascript/reference#PolylineOptions).

License
-------
Please see the [LICENSE file](LICENSE.md).
