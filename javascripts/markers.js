function markersBasename(time) {
  var basename = time.getUTCFullYear();
  var m = time.getUTCMonth() + 1;
  if (m < 10) {
    basename += "0";
  }
  basename += m;
  basename += time.getUTCDate();
  var h = time.getUTCHours();
  if (h < 10) {
    basename += "0";
  }
  basename += h;
  return basename
}

function loadMarkers(basename, markers) {
  var http = new XMLHttpRequest();
  http.open('GET', "markers/" + basename + ".json.gz");
  http.send(null);
  loaded_markers_basename = basename;
  http.onreadystatechange = function() {
    if ((http.readyState == 4) && (http.status == 200)) {
      JSON.parse(http.responseText).forEach(function(marker) {
        if (page_time < new Date(marker.time)) {
          markers.queue.push(marker);
        }
      });
    };
  };
};

function addMarkers(page_time, wall_time, markers, conf, mapwindow) {
  while(
    markers.queue.length > 0 &&
    new Date(markers.queue[0].time) < page_time
  ) {
    var marker = markers.queue.shift();
    var icon = marker.icon;
    var size;
    var until;
    if (marker.emotion) {
      size = conf.emoticon.size;
      until = new Date(wall_time.getTime() + conf.emoticon.duration);
    } else {
      size = conf.avatar.size;
      icon += "?s=" + conf.avatar.size;
      until = new Date(wall_time.getTime() + conf.avatar.duration);
    };
    var pin = mapwindow.dropPin(marker.lat, marker.lng, icon, size, marker.url);
    if (marker.emotion) {
      markers.emoticons.push({until: until, marker: pin});
    } else {
      markers.avatars.push({until: until, marker: pin});
    }
  };
};
function removeMarkers(wall_time, markers, mapwindow) {
  while(markers.avatars.length > 0 && markers.avatars[0].until < wall_time) {
    mapwindow.removePin(markers.avatars.shift().marker);
  }
  while(markers.emoticons.length > 0 && markers.emoticons[0].until < wall_time) {
    mapwindow.removePin(markers.emoticons.shift().marker);
  }
}
