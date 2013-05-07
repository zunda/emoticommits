//
// Copyright (c) 2013 zunda <zunda at freeshell.org>
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

var MarkerQueue = {
  zIndex: 0,
  queue: new Array,
  loading: false,
  avatars: new Array,
  emoticons: new Array
};

MarkerQueue.basename = function(time) {
  var basename = time.getUTCFullYear();
  var m = time.getUTCMonth() + 1;
  if (m < 10) {basename += "0";}
  basename += m;
	var d = time.getUTCDate();
	if (d < 10) {basename += "0";}
  basename += d;
  var h = time.getUTCHours();
  if (h < 10) {basename += "0";}
  basename += h;
  return basename
};

MarkerQueue.load = function(basename, page_time) {
  var http = new XMLHttpRequest();
  http.open('GET', "markers/" + basename + ".json");
  http.send(null);
  http.onreadystatechange = function() {
    if ((http.readyState == 4) && (http.status == 200)) {
      var loaded = JSON.parse(http.responseText).filter(function(marker) {
        return (page_time < new Date(marker.time));
      });
      if (loaded.length > 0) {
        MarkerQueue.loading = true;
        if (MarkerQueue.queue.length < 1 ||
          MarkerQueue.queue[MarkerQueue.queue.length - 1].time < loaded[0].time) {
          // Normal sequence in loading markers
          MarkerQueue.queue = MarkerQueue.queue.concat(loaded);
        } else {
          // Sometimes old markers come after new markers
          MarkerQueue.queue = loaded.queue.concat(MarkerQueue.queue);
        };
        MarkerQueue.loading = false;
      };
    };
  };
};

MarkerQueue.add = function(page_time, wall_time, conf, mapwindow) {
  if (! MarkerQueue.loading) {
    while(
      MarkerQueue.queue.length > 0 &&
      new Date(MarkerQueue.queue[0].time) < page_time
    ) {
      var marker = MarkerQueue.queue.shift();
      var icon = marker.icon;
      var size;
      var until;
      var index;
      if (marker.emotion) {
        size = conf.emoticon.size;
        until = new Date(wall_time.getTime() + conf.emoticon.duration);
        index = MarkerQueue.zIndex + 1000;
      } else {
        size = conf.avatar.size;
        icon += "?s=" + conf.avatar.size;
        until = new Date(wall_time.getTime() + conf.avatar.duration);
        index = MarkerQueue.zIndex;
      };
      var pin = mapwindow.dropPin(
        marker.lat, marker.lng, icon, size, marker.url, index);
      MarkerQueue.zIndex += 1;
      if (marker.emotion) {
        MarkerQueue.emoticons.push({until: until, marker: pin});
      } else {
        MarkerQueue.avatars.push({until: until, marker: pin});
      }
    };
  };
};

MarkerQueue.remove = function(wall_time, mapwindow) {
  while(MarkerQueue.avatars.length > 0 && MarkerQueue.avatars[0].until < wall_time) {
    mapwindow.removePin(MarkerQueue.avatars.shift().marker);
  }
  while(MarkerQueue.emoticons.length > 0 && MarkerQueue.emoticons[0].until < wall_time) {
    mapwindow.removePin(MarkerQueue.emoticons.shift().marker);
  }
}

MarkerQueue.removeAll = function(mapwindow) {
  while(MarkerQueue.avatars.length > 0) {
    mapwindow.removePin(MarkerQueue.avatars.shift().marker);
  }
  while(MarkerQueue.emoticons.length > 0) {
    mapwindow.removePin(MarkerQueue.emoticons.shift().marker);
  }
}

MarkerQueue.clear = function() {
  MarkerQueue.queue.length = 0;
}
