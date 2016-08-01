/**
 * Created by Anykey on 19.05.2016.
 */

var ROUTE_LAYER = 'ROUTE_LAYER';
var WIFI_LAYER = 'WIFI_LAYER';
var WELL_LAYER = 'WELL_LAYER';
var BUILD_LAYER = 'BUILD_LAYER';
var GPS_LAYER = 'GPS_LAYER';
var GPS_ROUTE_LAYER = 'GPS_ROUTE_LAYER';
var TRAFFIC_LAYER = 'TRAFFIC_LAYER';
var CUSTOM_POINT_LAYER = 'CUSTOM_POINT_LAYER';

var MARKERS_POLYLINE = "0";//"markers + polyline",
var MARKER_CIRCLE = "1"; // "marker + circle",
var MARKER = "2"; //"marker",

var BuildsArray = [];
var RoutesArray = [];
var WifiArray = [];
var WellArray = [];
var TrafficArray = [];
var CustomPointsArray = [];


var districtModal = aModal.clear();
function AObjectRegistrator(locationId) {
  
  this.locationId = locationId;
  this.aMapObject = null;
  this.callback = this.send;
  
  this.setLocationId = function (locationId) {
    this.locationId = locationId;
    return this;
  };
  
  this.getLocationId = function () {
    return this.locationId;
  };
  
  this.setMapObject = function (aMapObject) {
    this.aMapObject = aMapObject;
  };
  
  this.getMapObject = function () {
    return this.aMapObject;
  };
  
  this.setCallback = function (callBack) {
    this.callback = callBack;
  };
  
  this.getCallback = function () {
    return this.callback;
  };
  
  this.send = function () {
    this.aMapObject.send();
  };
}

var aBillingAddressManager = new ABillingLinkManager();
function ABillingLinkManager() {
  
  this.registerBuild = function (locationID, coordx, coordy) {
    return 'index.cgi?qindex=' + index +
      '&LOCATION_ID=' + locationID +
      '&coordy=' + coordx +
      '&coordx=' + coordy +
      '&change=1&header=2&MAP_TYPE=' + MAP_TYPE;
  };
  
  this.addBuild = function (streetId, buildNumber, coordx, coordy) {
    return 'index.cgi?qindex=' + index +
      '&STREET_ID=' + streetId +
      '&ADD_ADDRESS_BUILD=' + buildNumber +
      '&coordy=' + coordx +
      '&coordx=' + coordy +
      '&change=1&header=2&MAP_TYPE=' + MAP_TYPE;
  };
  
  this.addressChooseLocation = function () {
    return 'index.cgi?qindex=' + index +
      '&SHOW_ADDRESS=1&SHOW_UNREG=1&header=2';
  };
  
  this.removeMarkersCoords = function (LOCATION_ID) {
    return 'index.cgi?qindex=' + index +
      // '&LOCATION_ID=' + LOCATION_ID +
      '&del=' + LOCATION_ID +
      '&header=2';
  };
  
  this.getMarkersForLayer = function (TYPE) {
    return 'index.cgi?qindex=' + map_index +
      '&EXPORT_LIST=' + TYPE;
  };
  
  this.getForm = function (params) {

    params.MAP_TYPE = MAP_TYPE;

    return 'index.cgi?qindex=' + index + '&' +
      $.param(params) +
      '&header=2';
  }
}

function ABillingLocation(LocationArray) {
  
  var self = this;
  
  this.locationArray = null;
  this.districtId = null;
  this.streetId = null;
  this.locationId = null;
  this.newNumber = null;
  
  if (LocationArray) this.setLocation(LocationArray);
  
  this.setLocation = function (LocationArray) {
    this.locationArray = LocationArray;
    this.districtId = LocationArray[0];
    this.streetId = LocationArray[1];
    this.locationId = LocationArray[2];
    this.newNumber = LocationArray[3];
  };
  
  this.hasLocation = function () {
    return this.locationArray != null;
  };
  
  this.getLocationId = function () {
    return this.locationId;
  };
  
  
  this.askLocation = function (callback) {
    $.get(aBillingAddressManager.addressChooseLocation(), function (data) {
      
      districtModal
        .setId('ModalLocation')
        .setHeader('Choose address')
        .setBody(data)
        .addButton('Cancel', 'districtModalCancelButton', 'default')
        .addButton('Add', 'districtModalButton', 'primary')
        .show(setUpDistrictModalForm);
      
      function setUpDistrictModalForm() {
        
        // Removing unused form elements
        $('#flatDiv').remove();
        $('#addressButtonsDiv').remove();
        
        // Make build choose select 100% wide
        var $changeBuildMenu = $('.changeBuildMenu');
        var $addBuildMenu = $('.addBuildMenu');
        
        $changeBuildMenu.removeClass('col-md-4');
        $addBuildMenu.removeClass('col-md-4');
        
        $changeBuildMenu.addClass('col-md-9');
        $addBuildMenu.removeClass('col-md-6');
        
        //bind handlers
        $('#districtModalButton').on('click', function () {
          
          var dId = $('input#DISTRICT_ID').val();
          var sId = $('input#STREET_ID').val();
          var lId = $('input#LOCATION_ID').val();
          
          var newNumber = $('.addBuildMenu input').val() || null;
          
          self.setLocation([dId, sId, lId, newNumber]);
          
          districtModal.hide();
          
          if (callback) {
            console.log('callback');
            callback(self);
          }
        });
        
        $('#districtModalCancelButton').on('click', function () {
          discardAddingPoint(districtModal)
        })
      }
      
    }, 'text');
  };
}


var GPSControls = (function () {
  var layer = GPS_ROUTE_LAYER;

  events.on('layersready', function () {
    if (!MapLayers.hasLayer(layer)) MapLayers.createLayer(GPS_ROUTE, MARKERS_POLYLINE, false);
    
  });

  function showRouteFor(admin_id, color_no) {

    var no_request = form_no_route;
    
    if (showRouteFor.caller.name === 'onclick') {
      form_date = null;
      no_request = false;
    }
    
    if (!no_request)
      if (!form_date) {

        function requestRouteLayer(formObject) {
          requestLayer(layer, admin_id, color_no, formObject.date, formObject.time_from, formObject.time_to);
          events.off('GPS_ROUTE_DATE_CHOOSED', requestRouteLayer);
        }
        
        events.on('GPS_ROUTE_DATE_CHOOSED', requestRouteLayer);
        
        function requestDate() {
          var dateModal = aModal.clear();

          var dateModalBody =
            '<div class="modal-body"><div class="row">'
            + '<label class="control-label col-md-2">Date</label>'
            + '<div class="col-md-10">'
            + '<input type="text" id="dateModal_DATE" class="form-control tcal">'
            + '</div><hr/>'

            + '<div class="row">'
            + '<label class="control-label col-md-2">Time</label>'
            + '<div class="col-md-5">'
            + '<input type="text" id="dateModal_TIME1" value="00:00" class="form-control">'
            + '</div>'

            + '<div class="col-md-5">'
            + '<input type="text" id="dateModal_TIME2" value="23:59" class="form-control">'
            + '</div>'

            + '</div></div>';

          dateModal
            .setBody(dateModalBody)
            .addButton('Submit', 'dateModal_SUBMIT', 'btn btn-primary')
            .setSmall(true)
            .show(dateModalConfigure);

          function dateModalConfigure() {
            //init Tcal
            f_tcalInit();

            //cache DOM
            var date_input = $('#dateModal_DATE');
            var time_from_input = $('#dateModal_TIME1');
            var time_to_input = $('#dateModal_TIME2');
            var submit_btn = $('#dateModal_SUBMIT');

            // Get current date
            var date_default = new Date();
            var year = date_default.getYear() + 1900;
            var month = date_default.getMonth() + 1;
            var day = date_default.getDate();

            var date_string = year
              + '-' + ensureLength(month, 2)
              + '-' + ensureLength(day, 2);

            date_input.val(date_string);

            submit_btn.on('click', requestRouteForDate);

            function requestRouteForDate(e) {
              e.preventDefault();

              // Clear all event handlers
              submit_btn.off();
              
              events.emit('GPS_ROUTE_DATE_CHOOSED', {
                "date": date_input.val(),
                "time_from": time_from_input.val(),
                "time_to": time_to_input.val()
              });


              dateModal.hide();
              dateModal.destroy();
            }
          }
        }
        
        requestDate();
      }
      else {
        requestLayer(layer, admin_id, color_no, form_date);
      }
  }
  
  function requestLayer(layer, admin_id, colorNo, date, time_from, time_to) {
    $.getJSON(aBillingAddressManager.getMarkersForLayer(
      'gps_route&AID=' + admin_id +
      '&colorNo=' + colorNo +
      '&DATE=' + date +
      "&TIME_FROM=" + time_from +
      "&TIME_TO=" + time_to
    ))
      .done(function (json) {
        
        if (json.length == 1 && json[0].MESSAGE) {
          new ATooltip()
            .setText('<h1>' + json[0].MESSAGE + '</h1>')
            .setClass('danger')
            .setTimeout(2000)
            .show();
          
          return false;
        }
        
        events.on(layer + '_RENDERED', function () {
          MapLayers.setLayerVisible(layer, true);
        });
        
        BillingObjectParser.processGPSRoute(json, layer, colorNo);
      })
      
      .fail(function (jqxhr, textStatus, error) {
        var err = textStatus + ", " + error;
        new ATooltip("<h4>Request Failed: " + err + "</h4>").setClass('danger').show();
      });
  }
  
  return {
    showRouteFor: showRouteFor
  }
})();


function DistrictPolygoner() {
  var self = this;
  this.districtsArray = [];
  this.computed = false;
  this.polygonsArray = [];

  this.active = false;

  this.addBuild = function (districtId, latLng) {
    var arr = this.districtsArray[districtId];

    //If it is first point in district
    if (typeof (arr) === 'undefined') {
      //define new array
      this.districtsArray[districtId] = [latLng];
    } else {
      //add point to existing array
      arr.push(latLng);
    }

    this.computed = false;
  };

  this.toggle = function () {
    var btn = $('#polygonToggle').find('button');

    if (this.active) {
      this.hidePolygons();
      if (btn) {
        btn.removeClass('btn-primary');
        btn.addClass('btn-danger');
      }
    }
    else {
      this.showPolygons();
      if (btn) {
        btn.addClass('btn-primary');
        btn.removeClass('btn-danger');
      }
    }
  };

  this.hidePolygons = function () {
    $.each(this.polygonsArray, function (i, e) {
      aMap.removeObjectFromMap(e);
    });
    this.active = false;
  };

  this.showPolygons = function () {
    if (!this.computed) this.compute();

    $.each(self.polygonsArray, function (i, e) {
      aMap.addObjectToMap(e);
    });

    this.active = true;
  };

  this.compute = function () {
    this.hidePolygons();
    self.polygonsArray = [];

    var arr = this.districtsArray;

    for (var pointsArr in arr) {
      if (!arr.hasOwnProperty(pointsArr)) continue;

      var points = arr[pointsArr];
      if (points.length > 2) {
        createShell(points);
      }
    }
    this.computed = true;
  };

  function createShell(points) {

    var hullPoints = []; //output of magic algorithm

    //sort
    points.sort(sortPointY);
    points.sort(sortPointX);

    //Do some magic
    var hullPoints_size = chainHull_2D(points, points.length, hullPoints);

    var color = aColorPalette.getNextColorHex();

    var polygon = PolygonBuilder.build({
      paths: hullPoints,
      strokeColor: color,
      strokeOpacity: 0.8,
      strokeWeight: 2,
      fillColor: color,
      fillOpacity: 0.35
    });

    self.polygonsArray.push(polygon); //save reference
  }

  function sortPointX(a, b) {
    return a.lng - b.lng
  }

  function sortPointY(a, b) {
    return a.lat - b.lat
  }

  function isLeft(a, b, c) {
    return (b.lng - a.lng) * (c.lat - a.lat) - (c.lng - a.lng) * (b.lat - a.lat)
  }

  function chainHull_2D(a, b, c) {
    var f, h, d = 0, e = -1, g = 0, i = a[0].lng;
    for (f = 1; b > f && a[f].lng == i; f++);
    if (h = f - 1, h == b - 1)return c[++e] = a[g], a[h].lat != a[g].lat && (c[++e] = a[h]), c[++e] = a[g], e + 1;
    var j, k = b - 1, l = a[b - 1].lng;
    for (f = b - 2; f >= 0 && a[f].lng == l; f--);
    for (j = f + 1, c[++e] = a[g], f = h; ++f <= j;)if (!(isLeft(a[g], a[j], a[f]) >= 0 && j > f)) {
      for (; e > 0 && !(isLeft(c[e - 1], c[e], a[f]) > 0);)e--;
      c[++e] = a[f]
    }
    for (k != j && (c[++e] = a[k]), d = e, f = j; --f >= h;)if (!(isLeft(a[k], a[h], a[f]) >= 0 && f > h)) {
      for (; e > d && !(isLeft(c[e - 1], c[e], a[f]) > 0);)e--;
      if (a[f].lng == c[0].lng && a[f].lat == c[0].lat)return e + 1;
      c[++e] = a[f]
    }
    return h != g && (c[++e] = a[g]), e + 1
  }
}

/**
 * Created by Anykey on 19.05.2016.
 */


var LayerRequest = (function () {
  
  var TYPElistRefs = {
    BUILD_LAYER: 'builds',
    WELL_LAYER: 'wells',
    WIFI_LAYER: 'wifis',
    ROUTE_LAYER: 'routes',
    GPS_LAYER: 'gps',
    GPS_ROUTE_LAYER: 'gps_route',
    TRAFFIC_LAYER: 'traffic',
    CUSTOM_POINT_LAYER: 'custom_point'
  };
  
  function requestAndRender(TYPE) {
    var list_name = TYPElistRefs[TYPE];
    
    if (typeof (list_name) === 'undefined') {
      console.warn('[ Maps.ABillingRequest ] List name not defined');
    }
    
    var link = aBillingAddressManager.getMarkersForLayer(list_name);
    
    $.getJSON(link)
      .done(
        function (json) {
          BillingObjectParser.render(json, TYPE);
        })
      .fail(
        function (jqxhr, textStatus, error) {
          var err = textStatus + ", " + error;
          new ATooltip("<h3>Request Failed: " + err + "</h3>").setClass('danger').show();
        });
  }
  
  return {
    requestAndRender: requestAndRender
  }
})();

var BillingObjectParser = (function () {
  
  function render(data, type_) {
    var type = MapLayers.toType(type_);
    
    if (data.length == 1 && data[0].MESSAGE) {
      new ATooltip()
        .setText('<h1>' + data[0].MESSAGE + '</h1>')
        .setClass('danger')
        .setTimeout(2000)
        .show();
      
      return false;
    }
    
    switch (type) {
      case BUILD:
        //case CLIENTS_ONLINE:
        //case CLIENTS_OFFLINE:
        processBuilds(data);
        aDistrictPolygoner.showPolygons();
        break;
      case ROUTE:
        processRoutes(data);
        break;
      case WIFI:
        processWifi(data);
        break;
      case WELL:
        processWells(data);
        break;
      case GPS:
        processGPS(data);
        break;
      case TRAFFIC:
        processTraffic(data);
        break;
      case CUSTOM_POINT:
        processCustom(data);
        break;
      default:
        throw new Error('ABillingObjectParser: not defined logic to render a layer');
    }
    
    events.emit(type_ + '_RENDERED', true);
  }
  
  function processBuilds(Builds) {
    
    $.each(Builds, function (i, Build) {
      //create object to save it later
      var newBuild = {marker: null};
      
      newBuild.marker = AMapSimpleDrawer.drawMarker(Build.MARKER);
      
      aDistrictPolygoner.addBuild(Build.MARKER.DISTRICT,
        {
          lat: Build.MARKER.COORDS[0],
          lng: Build.MARKER.COORDS[1]
        }
      );
      
      MapLayers.pushToLayer(BUILD_LAYER, newBuild);
      
      markers[Build.MARKER.ID] = newBuild.marker;
    });
  }
  
  function processRoutes(Routes) {
    $.each(Routes, function (i, Route) {
      //create route object to save it later
      var newRoute = {
        markers: [],
        polyline: null
      };
      
      // Process route markers
      $.each(Route.MARKERS, function (i, marker) {
        var routeMarker = AMapSimpleDrawer.drawMarker(marker);
        newRoute.markers.push(routeMarker);
      });
      
      //Process route polyline
      newRoute.polyline = AMapSimpleDrawer.drawPolyline(Route.POLYLINE);
      
      MapLayers.pushToLayer(ROUTE_LAYER, newRoute);
    });
  }
  
  function processWifi(WIFIArray) {
    $.each(WIFIArray, function (i, Wifi) {
      
      //Create object to save it later
      var newWifi = {marker: null, circle: null};
      
      newWifi.marker = AMapSimpleDrawer.drawMarker(Wifi.MARKER);
      newWifi.circle = AMapSimpleDrawer.drawCircle(Wifi.CIRCLE, newWifi.marker);
      
      MapLayers.pushToLayer(WIFI_LAYER, newWifi);
    });
  }
  
  function processWells(WELLArray) {
    $.each(WELLArray, function (i, Well) {
      //create object to save it later
      var newWell = {marker: null};
      
      newWell.marker = AMapSimpleDrawer.drawMarker(Well.MARKER);
      
      MapLayers.pushToLayer(WELL_LAYER, newWell);
    });
  }
  
  function processGPS(GPSArray) {
    $.each(GPSArray, function (i, gps) {
      //create object to save it later
      var newGps = {marker: null};
      
      newGps.marker = AMapSimpleDrawer.drawMarker(gps.MARKER);
      
      MapLayers.pushToLayer(GPS_LAYER, newGps);
    });
  }
  
  function processGPSRoute(GPSRoute, layer, colorNo) {
    $.each(GPSRoute, function (i, Route) {
      
      //create route object to save it later
      var newRoute = {
        markers: [],
        polyline: null
      };
      
      // Color for route
      var colorHex = aColorPalette.getColorHex(colorNo);
      AMapSimpleDrawer.setColor(colorHex);
      
      // Process route markers
      $.each(Route.MARKERS, function (i, marker) {
        // Set icon parameters
        marker.TYPE = 'position/' + colorNo;
        marker.SIZE = [15, 15];
        
        // Draw and save markers
        var routeMarker = AMapSimpleDrawer.drawMarker(marker);
        newRoute.markers.push(routeMarker);
      });
      
      
      // Check if animation available 
      var animationAvailable = aMap.animatePolyline(true, Route.POLYLINE);
      
      newRoute.polyline = AMapSimpleDrawer.drawPolyline(Route.POLYLINE);
      
      // If animation available set animate handlers
      if (animationAvailable) {
        aMap.animatePolyline(false, newRoute.polyline);
      }
      
      MapLayers.pushToLayer(layer, newRoute);
      
      events.emit(layer + '_RENDERED', true);
    });
  }
  
  function processTraffic(TrafficArray) {
    $.each(TrafficArray, function (i, Build) {
      //Create object to save it later
      var newTraffic = {marker: null, circle: null};
      
      newTraffic.marker = AMapSimpleDrawer.drawMarker(Build.MARKER);
      newTraffic.circle = AMapSimpleDrawer.drawCircle(Build.CIRCLE, newTraffic.marker);
      
      console.log(newTraffic);
      
      MapLayers.pushToLayer(TRAFFIC_LAYER, newTraffic);
    });
  }
  
  function processCustom(CustomPointsArray) {
    $.each(CustomPointsArray, function (i, CustomPoint) {
      //create object to save it later
      var newCS = {marker: null};
      newCS.marker = AMapSimpleDrawer.drawMarker(CustomPoint.MARKER);
      MapLayers.pushToLayer(CUSTOM_POINT_LAYER, newCS);
    });
  }
  
  var AMapSimpleDrawer = (function () {
    
    var color_ = 'green';
    
    function drawMarker(object) {
      var x = object.COORDS[0];
      var y = object.COORDS[1];
      var infoWindow = object.INFO || '';
      var type = object.TYPE || 'build';
      var meta = object.META || null;
      var sizeArr = object.SIZE || [32, 37];
      var offsetArr = (object.CENTERED) ? [-sizeArr[0] / 2, -sizeArr[1] / 2] : [-sizeArr[0] / 2, -sizeArr[1]];
      
      var count = (object.COUNT) ? '' + object.COUNT : undefined;
      var id = object.ID;
      
      var mb = new MarkerBuilder(map);
      mb
        .setPosition(createPosition(x, y))
        .setType(type)
        .setIcon(type, sizeArr)
        .setIconOffset(offsetArr)
        .setLabel(count)
        .setId(id);
      
      if (infoWindow) mb.setInfoWindow(infoWindow);
      if (meta) mb.setMetaInformation(meta);
      
      var marker = mb.build();
      
      aMap.removeObjectFromMap(marker);
      
      return marker;
    }
    
    function drawPolyline(object) {
      
      object.path = makePath(object.RAWPATH);
      object.strokeColor = object.strokeColor || color_;
      
      var polyline = PolylineBuilder.build(object);
      
      aMap.removeObjectFromMap(polyline);
      
      function makePath(PointsArray) {
        var result = [];
        $.each(PointsArray, function (i, e) {
          result.push(createPosition(e[0], e[1]));
        });
        return result;
      }
      
      return polyline;
    }
    
    function drawCircle(Circle, marker) {
      return CircleBuilder.build(Circle, marker);
    }
    
    function setColor(color) {
      color_ = color;
    }
    
    return {
      drawMarker: drawMarker,
      drawPolyline: drawPolyline,
      drawCircle: drawCircle,
      setColor: setColor
    }
  })();
  
  function getDrawer(){
    return AMapSimpleDrawer;
  }
  
  return {
    render: render,
    processBuilds: processBuilds,
    processRoutes: processRoutes,
    processWifi: processWifi,
    processWells: processWells,
    processGPS: processGPS,
    processGPSRoute: processGPSRoute,
    processTraffic: processTraffic,
    processCustom: processCustom,
    getDrawer : getDrawer
  }
})();


/** Shows how Map objects are referencing to overlay type*/
var ObjectTypeRefs = {
  BUILD: POINT,
  WELL: POINT,
  DISTRICT: POINT,
  ROUTE: LINE,
  WIFI: CIRCLE,
  CUSTOM_POINT: CUSTOM_POINT
};

/**
 * Presents an object that will be registered.
 * Model
 * */
var AMapObject = {
  type: "null",
  create: function (values) {
    var instance = Object.create(this);
    Object.keys(values).forEach(function (key) {
      instance[key] = values[key];
    });
    return instance;
  },
  getType: function () {
    return this.type;
  },
  setType: function (type) {
    this.type = type;
  }
};

var AMapPoint = AMapObject.create({
  latLng: null,
  emit: function (event) {
    this.latLng = event.position;
  }
});

var AMapBuild = AMapPoint.create({
  type: BUILD,
  send: function () {
    
    var x = this.latLng.lat();
    var y = this.latLng.lng();
    
    if (form_location_id) {
      registerBuild(form_location_id, x, y);
    } else {
      var location = new ABillingLocation();
      location.askLocation(function (locationC) {
        
        districtModal.hide();
        
        if (locationC.newNumber) {
          var sId = locationC.streetId;
          var newNumber = locationC.newNumber;
          addBuild(sId, newNumber, x, y);
        } else {
          var location_id = locationC.getLocationId();
          registerBuild(location_id, x, y);
        }
      });
    }
    function registerBuild(location_id, x, y) {
      var link = aBillingAddressManager.registerBuild(location_id, x, y);
      loadToModal(link);
    }
    
    function addBuild(streetId, buildNumber, x, y) {
      var link = aBillingAddressManager.addBuild(streetId, buildNumber, x, y);
      loadToModal(link);
    }
  }
});

var AMapWell = AMapPoint.create({
  type: WELL,
  
  send: function () {
    var params = {
      TYPE: this.type,
      COORDX: this.latLng.lng(),
      COORDY: this.latLng.lat()
    };
    
    
    var link = aBillingAddressManager.getForm(params);
    loadToModal(link);
  }
});

var AMapDistrict = AMapPoint.create({
  type: DISTRICT,
  
  send: function () {
    
    var params = {
      TYPE: this.type,
      COORDX: this.latLng.lng(),
      COORDY: this.latLng.lat(),
      ZOOM: map.getZoom()
    };
    
    var link = aBillingAddressManager.getForm(params);
    loadToModal(link);
  }
});

var AMapCustomPoint = AMapPoint.create({
  type: CUSTOM_POINT,
  
  send: function () {
    
    var COORDX = this.latLng.lng();
    var COORDY = this.latLng.lat();
    
    var link = '?get_index=maps_show_custom_point_form&header=2&COORDX=' + COORDX + '&COORDY=' + COORDY;
    //aModal.hide();
    loadToModal(link);
  }
});

var AMapWifi = AMapPoint.create({
  type: WIFI,
  radius: 0,
  emit: function (overlay) {
    
    this.latLng = overlay.center;
    this.radius = Math.round(overlay.radius)
  },
  
  send: function () {
    
    var params = {
      TYPE: this.type,
      COORDX: this.latLng.lng(),
      COORDY: this.latLng.lat(),
      RADIUS: this.radius
    };
    
    var link = aBillingAddressManager.getForm(params);
    loadToModal(link);
  }
  
});

var AMapRoute = AMapObject.create({
  type: ROUTE,
  points: [],
  length: 0,
  
  setPoints: function (newPoints) {
    this.points = newPoints;
    this.length = aMap.getLength(newPoints);
  },
  getPoints: function () {
    return this.points;
  },
  emit: function (overlay) {
    console.log(overlay);
    this.setPoints(overlay.getPath().getArray());
  },
  send: function () {
    
    var params = {
      TYPE: this.type,
      POINTS: transformArray(this.points),
      ROUTE_LENGTH: this.length
    };
    //If got route id, pass it back
    if (form_route_id) params.ROUTE_ID = form_route_id;
    
    var link = aBillingAddressManager.getForm(params);
    loadToModal(link);
    
    function transformArray(arrayOfPoints) {
      var str = '';
      
      $.each(arrayOfPoints, function (i, latLng) {
        console.log(latLng);
        str += latLng.lng() + ',' + latLng.lat() + ';';
      });
      console.log(str);
      return str;
    }
  }
});

/** Shows how Map objects are referencing to JavaScript Models of map objects*/
var MapObjectTypesRefs = (function () {
  
  var refs = {
    BUILD: AMapBuild,
    WELL: AMapWell,
    DISTRICT: AMapDistrict,
    ROUTE: AMapRoute,
    WIFI: AMapWifi,
    CUSTOM_POINT: AMapCustomPoint
  };
  
  function getMapObject(TYPE) {
    var res = refs[TYPE];
    if (typeof(res) !== 'undefined') {
      return res;
    }
    console.log(refs);
    throw new Error('undefined type : ' + TYPE);
  }
  
  return {getMapObject: getMapObject};
})();


var MapLayers = (function () {
  
  var Layers = {};
  var layerStructureRefs = {};
  
  var clustering = false;
  var clustererGridSize = 30;
  
  function setLayerVisible(LAYER, boolean) {
    
    var layer = Layers[(LAYER)];
    
    var layerObjects = layer.objects;
    var clusterer = layer.clusterer;
    var clusteringForLayer = layer.clusteringEnabled;
    
    var state = (boolean) ? map : null;
    
    switch (layerStructureRefs[(LAYER)]) {
      
      case MARKER :
        $.each(layerObjects, function (i, object) {
          addObjectToMap(object.marker);
        });
        break;
      case MARKER_CIRCLE :
        $.each(layerObjects, function (i, object) {
          addObjectToMap(object.marker);
          object.circle.setMap(state);
        });
        break;
      case MARKERS_POLYLINE :
        $.each(layerObjects, function (i, object) {
          $.each(object.markers, function (i, marker) {
            addObjectToMap(marker);
          });
          object.polyline.setMap(state);
        });
        break;
    }
    
    Layers[LAYER].enabled = boolean;
    
    events.emit(LAYER + "_ENABLED", true);
    
    function addObjectToMap(object) {
      if (clusteringForLayer) {
        state ? clusterer.addMarker(object) : clusterer.removeMarker(object);
      }
      else {
        state ? aMap.addObjectToMap(object) : aMap.removeObjectFromMap(object);
      }
    }
  }
  
  function enableLayer(LAYER) {
    
    if (Layers[LAYER].objects.length != 0) {
      setLayerVisible(LAYER, true);
    } else {
      //If has no objects, request them from server
      requestLayer(LAYER);
    }
    
    AMapLayersBtns.enableButton(toType(LAYER));
  }
  
  function disableLayer(LAYER) {
    setLayerVisible(LAYER, false);
    AMapLayersBtns.disableButton(toType(LAYER));
  }
  
  function toggleLayer(LAYER) {
    var currentState = Layers[LAYER].enabled;
    switch (currentState) {
      case true:
        disableLayer(LAYER);
        break;
      case false:
        enableLayer(LAYER);
        break;
    }
  }
  
  function requestLayer(LAYER_TYPE) {
    events.on(LAYER_TYPE + '_RENDERED', function () {
      setLayerVisible(LAYER_TYPE, true);
    });
    
    LayerRequest.requestAndRender(LAYER_TYPE);
  }
  
  function pushToLayer(LAYER, data) {
    Layers[LAYER].objects.push(data);
  }
  
  function getLayerObjects(LAYER) {
    return Layers[LAYER].objects;
  }
  
  function getClusterer(LAYER) {
    return Layers[(LAYER)].clusterer;
  }
  
  function toLayer(string) {
    // TODO : generify 
    var references = {
      build: "BUILD_LAYER",
      wifi: "WIFI_LAYER",
      nas: "NAS_LAYER",
      gps: "GPS_LAYER",
      traffic: "TRAFFIC_LAYER",
      custom_point: 'CUSTOM_POINT_LAYER'
    };
    
    return references[string] || 'BUILD_LAYER';
  }
  
  function toType(string_LAYER) {
    var type = string_LAYER.toUpperCase();
    
    //IF GIVEN LAYER, REMOVE '_LAYER' PART OF STRING
    if (type.indexOf('_LAYER') != -1) {
      var index = type.indexOf('_LAYER');
      type = type.substring(0, index);
    }
    
    return type;
  }
  
  function createLayer(layerName, layerRef, clusteringForLayer) {
    var layer = layerName.toUpperCase() + "_LAYER";
    
    Layers[layer] = {
      enabled: false,
      objects: [],
      clusterer: aMap.getNewClusterer('', map),
      clusteringEnabled: (typeof (clusteringForLayer) !== 'undefined') ? clusteringForLayer : clustering
    };
    
    layerStructureRefs[layer] = layerRef;
    
    return layer;
  }
  
  function hasLayer(layer) {
    return typeof (Layers[(layer)]) !== 'undefined';
  }
  
  var AMapLayersBtns = (function () {
    //cache DOM
    var $controlBlock = null;
    
    var typeBtnRefs = {
      BUILD: null,
      WIFI: null,
      ROUTE: null,
      WELL: null,
      TRAFFIC: null,
      CUSTOM_POINT: null,
      GPS: null
    };
    
    events.on('layersready', cacheDOM);
    
    function cacheDOM() {
      $controlBlock = $('#showLayersControlBlock');
      typeBtnRefs = {
        BUILD: $controlBlock.find('#showLayersControlBlock_0'),
        WIFI: $controlBlock.find('#showLayersControlBlock_1'),
        ROUTE: $controlBlock.find('#showLayersControlBlock_2'),
        WELL: $controlBlock.find('#showLayersControlBlock_3'),
        TRAFFIC: $controlBlock.find('#showLayersControlBlock_4'),
        CUSTOM_POINT: $controlBlock.find('#showLayersControlBlock_5'),
        GPS: $controlBlock.find('#showLayersControlBlock_6')
      };
    }
    
    function enableButton(TYPE) {
      cacheDOM();
      typeBtnRefs[TYPE].attr('class', 'bg bg-success');
    }
    
    function disableButton(TYPE) {
      cacheDOM();
      typeBtnRefs[TYPE].attr('class', '');
    }
    
    function toggleButton(TYPE) {
      cacheDOM();
      var disabled = typeBtnRefs[TYPE].attr('class') == '';
      if (disabled) {
        enableButton(TYPE);
      } else {
        disableButton(TYPE);
      }
    }
    
    //interface
    return {
      enableButton: enableButton,
      disableButton: disableButton,
      toggleButton: toggleButton,
    }
  })();
  
  function setClusteringEnabled(cluster_size) {
    clustering = true;
    if (Layers.length > 0)
      throw new Error("You have called setClusteringEnabled() too late. Call me before creating any layers");
    clustererGridSize = cluster_size || 30;
  }
  
  return {
    toLayer: toLayer,
    toType: toType,
    
    hasLayer: hasLayer,
    pushToLayer: pushToLayer,
    toggleLayer: toggleLayer,
    enableLayer: enableLayer,
    setLayerVisible: setLayerVisible,
    
    setClusteringEnabled: setClusteringEnabled,
    
    getLayerObjects: getLayerObjects,
    getClusterer: getClusterer,
    createLayer: createLayer,
    
    buttons: AMapLayersBtns
  };
})();

var ClustererControl = function (LAYER, id) {
  
  var self = this;
  
  var DISABLE_MARKERS = 0;
  var SHOW_IN_CLUSTERS = 1;
  var SHOW_NON_CLUSTERED = 2;
  
  this.state = (CLUSTERING_ENABLED) ? SHOW_IN_CLUSTERS : SHOW_NON_CLUSTERED;
  this.layer_name = LAYER;
  this.btnId = id;
  
  this.layerObjects = MapLayers.getLayerObjects(self.layer_name);
  this.layerMarkers = [];
  for (var i = 0; i < self.layerObjects.length; i++) {
    if (!self.layerObjects[i].marker) continue;
    self.layerMarkers.push(self.layerObjects[i].marker);
  }
  
  this.layerClusterer = MapLayers.getClusterer(self.layer_name);
  this.$btn = $('#' + self.btnId).find('button');
  
  if (self.$btn.length <= 0) {
    // Wait 1 second and try again
    setInterval(function () {
      self.$btn = $('#' + self.btnId).find('button');
      // Warn if not found;
      if (self.$btn.length <= 0) console.warn('Button not found :  #' + self.btnId);
    }, 3000);
    
  }
  
  this.toggle = function () {
    self.state++;
    if (self.state > SHOW_NON_CLUSTERED) {
      self.state = DISABLE_MARKERS;
    }
    switch (self.state) {
      case DISABLE_MARKERS:
        self.removeMarkersFromCluster();
        self.removeMarkersFromMap();
        self.$btn.attr('class', 'btn btn-danger');
        break;
      case SHOW_IN_CLUSTERS:
        self.addMarkersToCluster();
        self.$btn.attr('class', 'btn btn-success');
        break;
      case SHOW_NON_CLUSTERED:
        self.enableNonClusteredMarkers();
        self.$btn.attr('class', 'btn btn-warning');
        break;
    }
  };
  
  
  this.addMarkersToCluster = function () {
    _log(5, 'MapsClusterer', 'addMarkersToCluster');
    self.layerClusterer.addMarkers(self.layerMarkers);
  };
  
  this.addMarkersToMap = function () {
    _log(5, 'MapsClusterer', 'addMarkersToMap');
    $.each(self.layerMarkers, function (i, marker) {
      marker.setMap(map);
    });
  };
  
  this.removeMarkersFromCluster = function () {
    _log(5, 'MapsClusterer', 'removeFromCluster');
    self.layerClusterer.clearMarkers();
    
  };
  
  this.removeMarkersFromMap = function () {
    _log(5, 'MapsClusterer', 'removeMarkers');
    $.each(self.layerMarkers, function (i, marker) {
      marker.setMap(null);
    });
  };
  
  this.enableNonClusteredMarkers = function () {
    _log(5, 'MapsClusterer', 'enableNonClustered');
    self.removeMarkersFromMap();
    self.removeMarkersFromCluster();
    self.addMarkersToMap();
  }
  
};





events.on('layersready', function () {
  
  if (BuildsArray.length > 0) {
    events.on(BUILD_LAYER + "_RENDERED", function () {
      MapLayers.enableLayer(BUILD_LAYER);
    });
    BillingObjectParser.render(BuildsArray, BUILD_LAYER);
  }
  
  if (RoutesArray.length > 0) {
    BillingObjectParser.processRoutes(RoutesArray);
    MapLayers.enableLayer(ROUTE_LAYER);
  }
  if (WifiArray.length > 0) {
    BillingObjectParser.processWifi(WifiArray);
    MapLayers.enableLayer(WIFI_LAYER);
  }
  if (WellArray.length > 0) {
    BillingObjectParser.processWells(WellArray);
    MapLayers.enableLayer(WELL_LAYER);
  }
  if (TrafficArray.length > 0) {
    BillingObjectParser.processTraffic(TrafficArray);
    MapLayers.enableLayer(TRAFFIC_LAYER);
  }
  if (CustomPointsArray.length > 0) {
    BillingObjectParser.processCustom(CustomPointsArray);
    MapLayers.enableLayer(CUSTOM_POINT_LAYER);
  }
  
});