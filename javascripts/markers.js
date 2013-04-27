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

function loadMarkers(basename, markers_queue) {
  var http = new XMLHttpRequest();
  http.open('GET', "markers/" + basename + ".json");
  http.send(null);
  loaded_markers_basename = basename;
  http.onreadystatechange = function() {
    if ((http.readyState == 4) && (http.status == 200)) {
      JSON.parse(http.responseText).forEach(function(marker) {
        if (page_time < new Date(marker.time)) {
          markers_queue.push(marker);
        }
      });
    };
  };
};

function addMarkers(page_time, wall_time, markers_queue, on_map) {
  while(
    markers_queue.length > 0 &&
    new Date(markers_queue[0].time) < page_time
  ) {
    var marker = markers_queue.shift();
    var icon = marker.icon;
    var size;
    var until;
    if (marker.emotion) {
      size = emoticon_size;
      until = new Date(wall_time.getTime() + emoticon_duration);
    } else {
      size = avatar_size;
      icon += "?s=" + size;
      until = new Date(wall_time.getTime() + avatar_duration);
    };
    var pin = mapwindow.dropPin(marker.lat, marker.lng, icon, size, marker.url);
    if (marker.emotion) {
      on_map.emoticons.push({until: until, marker: pin});
    } else {
      on_map.avatars.push({until: until, marker: pin});
    }
  };
};
function removeMarkers(wall_time, on_map) {
  while(on_map.avatars.length > 0 && on_map.avatars[0].until < wall_time) {
    mapwindow.removePin(on_map.avatars.shift().marker);
  }
  while(on_map.emoticons.length > 0 && on_map.emoticons[0].until < wall_time) {
    mapwindow.removePin(on_map.emoticons.shift().marker);
  }
}
