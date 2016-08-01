/**
 * Created by Anykey on 15.09.2015.
 *
 * General logic for maps
 */
/*Log name*/
var MODULE = 'Maps';

/** Holds main map container */
var mapDiv;
var map;

/** Holds references to tooltip panels for markers */
var infoWindows = [];
var markers     = [];

/** Holds map center as google.maps.LatLng object */
var mapCenterLatLng;

var operationMode = 0;

var hasRealPosition = false;
var realPosition    = null;

function fullScreenDistrict() {
  var height    = window.innerHeight;
  var width     = window.innerWidth;
  var newWindow = window.open("/admin/index.cgi?qindex=" + index + "&header=1&MAP=1",
      "new",
      'width=' + width + ', height=' + height);
  newWindow.focus();
}

/**
 * Created by Anykey on 15.09.2015.
 *
 * Script that defines Maps logic
 *
 */

/*Marker Builder*/
var aMarkerBuilder;

//holders for instances of A... map objects. Initialized when called;
var aNavigation;
var aSearch;
var aControls;

if (DISTRICT_POLYGONS_ENABLED && typeof DistrictPolygoner !== 'undefined')
  var aDistrictPolygoner = new DistrictPolygoner();

//if (CLUSTERING_ENABLED) {
/**
 * MarkerClusterer for grouping points
 */
var markerClusterer;
//Set distance at which markers will be grouped in a cluster
var CLUSTERER_GRID_SIZE = 30;

//}
//Holding global refernces;
var openedInfoWindows = []; //last opened infowindow

/**
 * THIS IS START POINT OF A SCRIPT
 *
 *  WHEN AMAP HAS BEEN CREATING, IT LOAD MAPS API SCRIPTS ON PAGE,
 *
 *  WHICH WHEN READY CALL initialize FUNCTION
 * */
var aMap = new AMap();


//Main function for setting up a map
function initialize() {
  $(function () {
    var mapOptions = ({
      rotateControls: true
    });
    
    mapDiv = document.getElementById('map');
    
    events.on('mapsconfigured', register_messagechecker_extension);
    
    events.on('mapsLoaded', function () {
      configureMap();
    });
    
    map = aMap.init(mapDiv, mapOptions, function (map_) {
      map = map_;
      
      //Getting deal with mapCenter
      getMapCenter();
      
      if (form_query_search || form_type_search) {
        events.on('mapsLoaded', function () {
          if (mapCenterLatLng)
            makeSearch(mapCenterLatLng);
        });
      }
      
      events.on('mapsLoaded', function () {
        if (form_show_build) {
          //AMapLayers.setLayerVisible(BUILD_LAYER);
          showBuild(form_show_build);
        }
        
        //If it is register build action
        if (form_location_type) {
          if (form_location_id || form_route_id) {
            addNewPoint(form_location_type);
          }
        }
        
        if (form_make_navigation_route) {
          if (form_nav_x && form_nav_y) {
            var destination = createPosition(form_nav_x, form_nav_y);
            aNavigation     = new Navigation(map);
            aNavigation.createExtendedRoute(destination);
          }
        }
        
        if (form_show_gps) {
          MapLayers.toggleLayer(GPS_LAYER);
          
          events.on(GPS_LAYER + '_ENABLED', function () {
            //get color for requested admin
            var objects = MapLayers.getLayerObjects(GPS_LAYER);
            
            var color = 17;
            var pos_x, pos_y;
            
            var found = false;
            
            $.each(objects, function (i, obj) {
              if (obj) {
                if (form_show_gps == obj.marker.metaInfo.ADMIN) {
                  found = true;
                  
                  var marker = obj.marker;
                  color      = marker.metaInfo.colorNo;
                  pos_x      = marker.metaInfo.x;
                  pos_y      = marker.metaInfo.y;
                  GPSControls.showRouteFor(form_show_gps, color);
                  changePosition(pos_x, pos_y, 18);
                }
              }
            });
            
            if (!found) {
              alert('No GPS information for administrator with this ID: ' + form_show_gps);
            }
          });
        }
      });
      
      events.emit('mapsLoaded', true);
    });
    
    //process builds moved to -drawing.js
  });
}

function getMapCenter() {
  if (form_x && form_y) { //if it is set explicitly
    console.log('START: ' + 'Coordinates set by FORM params ' + form_x + ', ' + form_y);
    setMapCenter([form_x, form_y]);
  }
  else if (mapCenter == '') {
    if (form_show_gps) {
      console.log('START: Coordinates skipped. Showing GPS route');
      return true;
    }
    console.log('START: ' + 'Coordinates will be retrieved by getPosition()');
    goToRealPosition(
        function (position) {
          setMapCenter(position);
          if (form_query_search || form_type_search) {
            makeSearch(mapCenterLatLng);
          }
        },
        function () {
          setMapCenter([48, 25]);
          if (form_query_search || form_type_search) {
            makeSearch(mapCenterLatLng);
          }
        }
    );
  }
  else if (mapCenter != '') {
    console.log('START: ' + 'Coordinates set by mapCenter');
    console.log('(non reversed) MapCenter: ' + mapCenter);
    var mapCenterSplitted = mapCenter.split(', ');
    
    var y = mapCenterSplitted[0];
    var x = mapCenterSplitted[1];
    
    mapCenterLatLng = createPosition(x, y);
    
    changePosition(x, y, mapCenterSplitted[2]);
  }
  return true;
}

function configureMap() {
  
  aMarkerBuilder = new MarkerBuilder(map);
  
  aSearch = new Search();
  aSearch.init(map);
  
  aNavigation = new Navigation();
  aNavigation.init(map);
  
  if (CLUSTERING_ENABLED) {
    MapLayers.setClusteringEnabled(CLUSTERER_GRID_SIZE);
  }
  MapLayers.createLayer(ROUTE, MARKERS_POLYLINE);
  MapLayers.createLayer(WIFI, MARKER_CIRCLE);
  MapLayers.createLayer(WELL, MARKER);
  MapLayers.createLayer(BUILD, MARKER);
  MapLayers.createLayer(GPS, MARKER);
  MapLayers.createLayer(TRAFFIC, MARKER);
  MapLayers.createLayer(CUSTOM_POINT, MARKER);
  events.emit('layersready');
  
  if (form_show_controls) addControls();
  function addControls() {
    aControls = new MapControls(map);
    
    //Buttons are defined in order they will appear in Map Controls
    
    if (addPointCtrlEnabled && (typeof DrawController != 'undefined')) {
      aControls.addDropdown('plus',
          [
            [_BUILD, 'addNewPoint(BUILD)'],
            [_ROUTE, 'addNewPoint(ROUTE)'],
            [_WIFI, 'addNewPoint(WIFI)'],
            [_WELL, 'addNewPoint(WELL)'],
            [_CUSTOM_POINT, 'addNewPoint(CUSTOM_POINT)']
          ],
          _ADD + ' ' + _POINT, 'addOperationCtrlBtn', 'success');
      aControls.addBtn('minus', 'toggleRemoveMarkerMode()', _REMOVE + ' ' + _MARKER + ' ' + _LOCATION, 'removeLocation', 'danger');
      aControls.addBtn('remove-sign', 'dropOperation()', _DROP, 'dropOperationCtrlBtn');
    }
    
    
    if (layersCtrlEnabled) {
      
      aControls.addDropdown('eye-open',
          [
            [_BUILD, 'MapLayers.toggleLayer(BUILD_LAYER)'],
            [_WIFI, 'MapLayers.toggleLayer(WIFI_LAYER)'],
            [_ROUTES, 'MapLayers.toggleLayer(ROUTE_LAYER)'],
            [_WELLS, 'MapLayers.toggleLayer(WELL_LAYER)'],
            [_TRAFFIC, 'MapLayers.toggleLayer(TRAFFIC_LAYER)'],
            [_CUSTOM_POINT, 'MapLayers.toggleLayer(CUSTOM_POINT_LAYER)'],
            (GPS_layer_enabled != '0') ? [_GPS, 'MapLayers.toggleLayer(GPS_LAYER)'] : ['', '']
          ],
          _TOGGLE + ' ' + _MAP_OBJECT_LAYERS, 'showLayersControlBlock'
      );
    }
    
    if (searchCtrlEnabled && aSearch.isAvailable)
      aControls.addDropdown('search',
          [
            [_BY_QUERY, 'showModalQuerySearch()'],
            [_BY_TYPE, 'showModalTypeSearch()']
          ],
          _SEARCH
      );
    
    if (navigationCtrlEnabled)
      aControls.addBtn('road', 'aNavigation.showRoute()', _NAVIGATION, 'makeNavigationCtrl', 'primary');
    
    if (DISTRICT_POLYGONS_ENABLED) {
      aControls.addBtn('bookmark', 'aDistrictPolygoner.toggle()', _TOGGLE + ' ' + _POLYGONS, 'polygonToggle');
    }
    
    if (CLUSTERING_ENABLED) {
      events.on('mapsconfigured', function () {
        window['BuildClustererControl'] = new ClustererControl(BUILD_LAYER, 'clusterToggle');
      });
      aControls.addBtn('map-marker', 'BuildClustererControl.toggle()', _TOGGLE + ' ' + _MARKER + ' ' + _CLUSTERS, 'clusterToggle', 'success');
    }
    
    aControls.init();
  }
  
  events.emit('mapsconfigured');
}

function setMapCenter(position) {
  
  //getPosition returns Number[];
  if ($.isArray(position))
    mapCenterLatLng = createPosition(position[0], position[1]);
  else
    mapCenterLatLng = position;
  
  createUserMarker(mapCenterLatLng);
  
  console.log(map);
  
  aMap.map.setCenter(mapCenterLatLng);
  
  aMap.map.setZoom(16);
}

function createUserMarker(positionLatLng) {
  
  var markerBuilder = new MarkerBuilder(map);
  
  hasRealPosition = true;
  realPosition    = positionLatLng;
  
  markerBuilder
      .setPosition(positionLatLng)
      .setIcon('user')
      .setTitle(form_title)
      .setDraggable(true)
      .setClickable(false)
      .build();
  return this;
}

function getDefinedMapCenter() {
  
  if (mapCenterLatLng) {
    return mapCenterLatLng;
  }
  if (mapCenter != '') {
    var $center = mapCenter.split(', ');
    var latLng  = createPosition($center[0], $center[1]);
    var zoom    = parseInt($center[2]);
    return [latLng, zoom];
  } else {
    return [createPosition(48, 25), 7];
  }
}

//Additional
/**
 *  Change position to coords
 */
function changePosition(x, y, zoom) {
  var newPos = createPosition(x, y);
  // goto point
  map.setCenter(newPos);
  //set zoom
  map.setZoom(parseInt(zoom) || 10);
  
  //save as last position
  lastPosX = x;
  lastPosY = y;
  
  //save as last zoom
  lastZoom = zoom;
}

function createPosition(x, y) {
  return aMap.createPosition(x, y);
}

function showModalQuerySearch() {
  
  var input = getSimpleRow('modalSearch', 'modalSearchInput', 'Search');
  
  var modal = aModal.clear()
      .setHeader('Query search')
      .setBody(input)
      .addButton('Cancel', 'modalCancelBtn', 'default')
      .addButton('Search', 'modalQuerySearchBtn', 'primary')
      .show();
  
  setTimeout(function () {
    $('#modalQuerySearchBtn').on('click', function () {
      var val = $('#modalSearchInput').val();
      
      aSearch.makeQuerySearch(val, mapCenterLatLng);
      
      aModal.hide();
    });
    
    $('#modalCancelBtn').on('click', aModal.hide);
  }, 500);
  
}

function showModalTypeSearch() {
  
  var input = '<form id="modalTypeSearch" class="form form-horizontal">' +
      getCheckboxRow('atm', 'modalTypeSearchAtm', 'ATM') +
      getCheckboxRow('bank', 'modalTypeSearchBank', 'Banks') +
      getCheckboxRow('finance', 'modalTypeSearchFinance', 'Finance') +
      '</form>';
  
  var modal = aModal.clear()
      .setId('modalTypeSearchModal')
      .setHeader('Query search')
      .setBody(input)
      .addButton('Cancel', 'modalCancelBtn', 'default')
      .addButton('Search', 'modalQuerySearchBtn', 'primary')
      .show(function (modal) {
        
        $('#modalQuerySearchBtn').on('click', function () {
          var types = [];
          
          var form = $('#modalTypeSearch');
          
          if (form.find('#modalTypeSearchAtm').prop('checked')) types.push('atm');
          if (form.find('#modalTypeSearchBank').prop('checked')) types.push('bank');
          if (form.find('#modalTypeSearchFinance').prop('checked')) types.push('finance');
          
          if (types.length > 0) {
            aSearch.makeNearbySearch(types, mapCenterLatLng);
          }
          aModal.destroy();
        });
        
        $('#modalCancelBtn').on('click', modal.destroy);
      }, 500);
}

function makeSearch(position) {
  if (!aSearch.isReady()) aSearch.init(map);
  
  if (typeof position === 'undefined') position = mapCenterLatLng;
  
  if (form_query_search || form_type_search) {
    if (form_query_search) {
      var query = '';
      var $arr  = form_query_search.split(";");
      $.each($arr, function (i, entry) {
        query += entry + ' OR ';
      });
      
      aSearch.makeQuerySearch(query, position)
    }
    
    if (form_type_search) {
      aSearch.makeNearbySearch(form_type_search, position);
    }
  } else
    console.log('no need for search')
}

function goToRealPosition(successCallback) {
  
  function errorCallback() {
    alert(_NAVIGATION_WARNING);
    changePosition(48, 30, 4);
  }
  
  if (!successCallback) {
    successCallback = function (position) {
      form_x = position[0];
      form_y = position[1];
      
      mapCenter = form_x + ', ' + form_y + ', 14';
      
      createDefaultMarker(createPosition(form_x, form_y), 'user');
      changePosition(form_y, form_x, 14);
    };
  }
  getLocation(successCallback, errorCallback);
}

function showBuild(id) {
  
  console.log('Showing build %s', id);
  
  if (markers[id] !== undefined || markers[++id] !== undefined) {
    
    var marker = markers[id];
    changePosition(
        marker.latLng.lat(),
        marker.latLng.lng(),
        15
    );
    
    if (infoWindows[id])
      infoWindows[id].open(map, marker);
    
  } else {
    console.warn(' Trying to show build, but given id(%s) not found', id);
    console.log(markers);
  }
  
}

function createDefaultMarker(place, icon) {
  
  //Instantiating new builder
  var markerBuilder = new MarkerBuilder(map);
  markerBuilder.setPosition(place.geometry.location);
  markerBuilder.setDynamic(true);
  //if icon defined, set icon
  if (icon) {
    markerBuilder.setIcon(icon);
  }
  
  //creating _infoWindow
  var content = place.name + '<br />';
  if (place.formatted_address) content += place.formatted_address;
  markerBuilder.setInfoWindow(content);
  
  markerBuilder.setNavigation("Go to");
  
  
  if (place.id) {
    markerBuilder.setId(place.id);
  }
  
  var result = markerBuilder.build();
  
  markerBuilder = null;
  
  return result;
}

function closeInfoWindows() {
  var infoWindow;
  while (infoWindow = openedInfoWindows.pop()) {
    infoWindow.close();
  }
}

function register_messagechecker_extension() {
  var message_type = 'MAP_EVENT';
  
  var callback = function (event_data) {
    
    var markers = event_data['MARKERS'] || [];
    var lines   = event_data['LINES'] || [];
    
    $.each(markers, function (i, e) {
      process_marker(e);
    });
    
    $.each(lines, function (i, e) {
      process_line(e);
    });
    
    function process_marker(marker) {
      // Should contain coordinates, icon_type, and description
      var coords    = marker.COORDS;
      var icon_type = marker.ICON || 'build_green';
      
      var label     = marker.COUNT;
      var animation = 'DROP';
      var info      = marker.INFO;
      var id        = marker.ID || (new Date()).getMilliseconds();
      
      if (!coords) {
        console.warn('[ Maps ] Got event without coords');
        return false
      }
      
      var mb         = new MarkerBuilder(map);
      var new_marker = mb.setPosition(aMap.createPosition(coords[0], coords[1]))
          .setIcon(icon_type)
          .setInfoWindow(info)
          .setAnimation(animation)
          //.setIcon(type, sizeArr)
          //.setIconOffset(offsetArr)
          .setLabel(label)
          .setId(id)
          .build();
      
      aMap.addObjectToMap(new_marker);
      
    }
    
    function process_line(line) {
      console.log('[ Map ] process_line() Not implemented');
    }
  };
  
  AMessageChecker.extend({TYPE: message_type, CALLBACK: callback});
}