/**
 * Created by Anykey on 28.09.2015.
 *
 */
//MarkerClusterer for generated objects, e.g. ASearch results
var markerHolder;

/** Holds Markers, processed and placed on map  */
var markers = [];

/**
 * Created by Anykey on 02.10.2015.d
 */


var aDrawController;

function DrawController() {
  var self = this;

  this.aObjectRegistrator = new AObjectRegistrator();

  this.options = {
    drawingControl: false,
    drawingControlOptions: null
  };

  this.callback = function (e) {
    var mapObject = this.aObjectRegistrator.getMapObject();
    mapObject.setLatLng(e.position);

    console.log('default callback');
  };

  this.drawingManager = null;
  this.map = null;

  this.setControlsEnabled = function (boolean) {
    this.options.drawingControl = boolean;
    return this;
  };

  this.setCallback = function (callback) {
    this.callback = callback;
    return this;
  };

  this.getCallback = function () {
    return this.callback;
  };

  this.setMapObject = function (aMapObject) {
    this.aObjectRegistrator.setMapObject(aMapObject);
  };

  this.init = function (map) {
    this.options.map = map;
    this.drawingManager = new google.maps.drawing.DrawingManager(this.options);
    return this;
  };

  this.getObjectRegistrator = function () {
    return this.aObjectRegistrator;
  };

  this.clearDrawingMode = function () {
    google.maps.event.clearInstanceListeners(this.drawingManager);
    this.drawingManager.setDrawingMode(null);

  };

  this.setDrawingMode = function (string) {
    if (this.drawingManager == null)
      throw new Error("drawingManager not initialized");
    var drawingMode = '';
    switch (string) {
      case null:
        drawingMode = null;
        google.maps.event.clearInstanceListeners(self.getDrawingManager());
        break;
      case POINT:
        drawingMode = google.maps.drawing.OverlayType.MARKER;
        break;
      case LINE:
        drawingMode = google.maps.drawing.OverlayType.POLYLINE;
        break;
      case POLYGON:
        drawingMode = google.maps.drawing.OverlayType.POLYGON;
        break;
      case CIRCLE:
        drawingMode = google.maps.drawing.OverlayType.CIRCLE;
        break;
      case CUSTOM_POINT:
        drawingMode = google.maps.drawing.OverlayType.MARKER;
        break;
      default:
        console.warn('Unsupported drawing mode: ' + string);
    }
    this.drawingManager.setDrawingMode(drawingMode);

    addListener(drawingMode);
  };

  this.getDrawingManager = function () {
    return this.drawingManager;
  };

  function addListener(type) {
    var objectType = type;

    //removing prev listeners
    google.maps.event.clearInstanceListeners(self.getDrawingManager());

    //adding current listener
    if (type != null)
      google.maps.event.addListener(self.getDrawingManager(), 'overlaycomplete', function (e) {

        //Disable drawing mode
        self.setDrawingMode(null);

        //Get defined callback
        var cb = self.getCallback();
        //Call
        cb(e, objectType);
      });
  }
}


function addNewPoint(type) {

  operationMode = 1;

  //Initialize controllers
  if (!aDrawController) {
    aDrawController = new DrawController();
    aDrawController
      .setControlsEnabled(false)
      .setCallback(overlayCompleteCallback)
      .init(map);
  }

  if (ObjectTypeRefs[type]) {
    aDrawController.setDrawingMode(ObjectTypeRefs[type]);

    aTooltip.display('<h3>' + _NOW_YOU_CAN_ADD_NEW + _LANG_TYPE_NAME[type] + _TO_MAP + '</h3>', 2000);

    var btn = $('#dropOperationCtrlBtn').find('button');
    btn.attr('class', 'btn btn-danger');

  }
  else {
    throw new Error('Unsupported drawing mode');
  }
  var mapObject = MapObjectTypesRefs.getMapObject(type);
  aDrawController.setMapObject(mapObject);

  _log(LEVEL_INFO, 'aDrawController', type);
  _log(LEVEL_INFO, 'aDrawController.mapObject', mapObject);
}



function toggleRemoveMarkerMode() {

  operationMode = 2;

  for (var key in markers) {
    //remove default listener
    google.maps.event.clearInstanceListeners(markers[key], 'click');

    //add custom listener
    google.maps.event.addListener(markers[key], 'click', function () {
      console.log(this);
      showConfirmModal(this.id)
    });
  }

  var btn = $('#dropOperationCtrlBtn').find('button');
  btn.attr('class', 'btn btn-danger');

  new ATooltip('<h2>' + _NOW_YOU_CAN_REMOVE_MARKER + '</h2>')
    .setClass('danger')
    .show();

  setTimeout(function () {
    new ATooltip('<h2>' + _CLICK_ON_A_MARKER_YOU_WANT_TO_DELETE + '</h2>')
      .setClass('info')
      .show();
  }, 2000);

  function showConfirmModal(id) {
    var confirmModalRemove = aModal.clear();

    window['LOCATION_ID'] = id;

    confirmModalRemove
      .setBody('<div id="confirmModalContent">' + _REMOVE + '?</div>')
      .setFooter(
        '<button id="confirmModalCancelBtn" class="btn btn-default">Cancel</button>' +
        '<button id="confirmModalConfirmBtn" class="btn btn-success">Yes</button>')
      .show(bindBtnEvents);


    function bindBtnEvents(modal) {
      $('#confirmModalCancelBtn').on('click', function (modal) {
        console.log('#confirmModalCancelBtn');
        discardRemovingPoint(modal);
      });

      $('#confirmModalConfirmBtn').on('click', function () {
        console.log('#confirmModalConfirmBtn');
        confirmModalRemove.destroy();
        removeMarker(window['LOCATION_ID']);
      });
    }

  }

  function removeMarker(id) {
    loadToModal(aBillingAddressManager.removeMarkersCoords(id))
  }
}

function discardRemovingPoint(modal) {
  aModal.destroy();
  location.reload(false);
}


var drawing_last_overlay;
function overlayCompleteCallback(e) {

  //getRegistrator
  var registrator = aDrawController.getObjectRegistrator();

  //getObject
  var object = registrator.getMapObject();
  drawing_last_overlay = e.overlay;

  //Pass overlay to object
  object.emit(e.overlay);

  showConfirmModal();

  function showConfirmModal() {
    if (form_location_id) {
      confirmModal.clear();
      confirmModal
        .setBody('<div id="confirmModalContent">' + _ADD + ' ' + _NEW + ' ' + _LANG_TYPE_NAME[object.getType()] + '?</div>')
        .setFooter(
          '<button id="confirmModalCancelBtn" class="btn btn-default">Cancel</button>' +
          '<button id="confirmModalConfirmBtn" class="btn btn-success">Yes</button>')
        .show(bindBtnEvents);
    } else {
      confirmAddingPoint();
    }

    function bindBtnEvents() {
      $('#confirmModalCancelBtn').on('click', function (modal) {
        discardAddingPoint(modal);
      });

      $('#confirmModalConfirmBtn').on('click', function () {
        confirmAddingPoint();
      });
    }
  }
}

var confirmModal = new AModal();
function confirmAddingPoint() {
  confirmModal.hide();

  aDrawController.getObjectRegistrator().send();
}

function discardAddingPoint() {
  //removing discarded marker
  if (drawing_last_overlay)
    drawing_last_overlay.setMap(null);

  aModal.destroy();
}

function dropOperation() {
  switch (operationMode) {
    case 0:
      return;
      break;
    case 1:
      if (aDrawController) aDrawController.clearDrawingMode();

      var btn = $('#dropOperationCtrlBtn').find('button');
      btn.attr('class', 'btn btn-primary');

      discardAddingPoint(aModal);
      break;
    case 2:
      discardRemovingPoint(aModal);
      break;
  }

  operationMode = 0;
}

function AMap(callback) {

  var self = this;
  //Loading script if not downloaded
  if (!document.getElementById('google_api_script')) {
    var scriptElement = document.createElement('script');
    scriptElement.id = 'google_api_script';
    scriptElement.src = 'https://maps.googleapis.com/maps/api/js?libraries=places,drawing&callback=initialize&key=' + MAP_KEY;

    document.getElementsByTagName('head')[0].appendChild(scriptElement);
  }

  this.map = null;

  this.init = function (mapDiv, mapOptions, callback) {
    var mapOptions_ = mapOptions || {};
    mapOptions_.mapTypeId = getMapView(CONF_MAPVIEW);

    this.map = new google.maps.Map(
      mapDiv,
      mapOptions_
    );

    google.maps.event.addListener(this.map, 'click', function (event) {
      closeInfoWindows();

      events.emit('mapsClick', event);
    });

    google.maps.event.addDomListener(window, "resize", function () {
      var center = aMap.getCenter();
      google.maps.event.trigger(map, "resize");
      map.setCenter(center);
    });

    if (callback) callback(this.map);
    return this.map;
  };

  this.createPosition = function (x, y) {
    return new google.maps.LatLng(x, y);
  };

  this.setCenter = function (x, y) {
    this.map.setCenter(this.createPosition(x, y));
  };

  this.getCenter = function () {
    return this.map.getCenter();
  };

  this.setZoom = function (zoom) {
    //this.map.setZoom(zoom);
  };

  this.getZoom = function () {
    this.map.getZoom();
  };

  this.addObjectToMap = function (object) {
    object.setMap(self.map);
  };

  this.removeObjectFromMap = function (object) {
    object.setMap(null);
  };

  this.getNewClusterer = function (map_type, map) {
    //add new marker clusterer (For Marker Grouping)
    return new MarkerClusterer(map);
  };
  
  this.getLength = function (arrayOfPoints) {
    Math.round(google.maps.geometry.spherical.computeLength(arrayOfPoints));
  };

  this.animatePolyline = function(setup, polyline){

    var polylineColor = (polyline.COLOR) ? aColorPalette.getColorHex(polyline.COLOR) : aColorPalette.getNextColorHex();

    if (setup) {
      //Process route polyline
      var lineSymbol = {
        path: google.maps.SymbolPath.CIRCLE,
        scale: 8,
        strokeColor: polylineColor
      };

      polyline.icons = [{
        icon: lineSymbol,
        offset: '100%'
      }];

      return true;
    }


    makeAnimatedCircleOnLine(polyline);

    function makeAnimatedCircleOnLine(line) {
      var count = 0;
      var handler = 0;

      function nextTick(){
        count = (count + 1) % 200;

        // Get icon
        var icons = line.get('icons');
        if (!icons){
          if (handler != 0) window.clearInterval(handler);
          return false;
        }

        // Modify
        icons[0].offset = (count / 2) + '%';

        // Set icon
        line.set('icons', icons);
      }

      handler = window.setInterval(nextTick, 200);
    }
  };

  function getMapView(CONF_MAPVIEW) {
    switch (CONF_MAPVIEW) {
      case 'SATELLITE' :
        return google.maps.MapTypeId.SATELLITE;
        break;
      case 'HYBRID' :
        return google.maps.MapTypeId.HYBRID;
        break;
      case  'TERRAIN' :
        return google.maps.MapTypeId.TERRAIN;
        break;
      default:
        return google.maps.MapTypeId.ROADMAP;
        break;
    }
  }
}

AMap.prototype = map;

function MarkerBuilder(map) {
  this._marker = {};

  this._marker.type = 'default';

  this._marker.map = map;
  this._marker.position = null;
  this._marker.draggable = false;
  this._marker.clickable = true;

  this.setId = function (id) {
    this._marker.id = id;
    return this;
  };

  this.setTitle = function (title) {
    this._marker.title = title || '';
    return this;
  };

  this.setLabel = function (label) {
    if (typeof label != 'undefined') {
      this._marker.label = label;
      if (this._marker.icon) //defines position of marker Label according to top-left corner
        this._marker.icon.labelOrigin = new google.maps.Point(35, 35);
    }
    return this;
  };

  this.setIcon = function (fileName, sizeArr) {
    var width = 32;
    var height = 37;
    
    var name = '';

    if (fileName === 'default_green') {
      name = null;
    }
    else if (fileName != null) {
      this._marker.type = fileName;
      name = this.getIconFileName(fileName);
    }

    if (typeof sizeArr != 'undefined') {
      width  = sizeArr[0];
      height = sizeArr[1];
    }
    this._marker.icon = new google.maps.MarkerImage(
        name,
        new google.maps.Size(width, height)
    );
    


    return this;
  };

  this.setIconOffset = function (offsetArr) {
    return this;
  };

  this.setType = function (type, sizeArr) {
    return this.setIcon(type, sizeArr);
  };

  this.setPosition = function (latLng) {
    this._marker.position = latLng;
    return this;
  };

  this.setInfoWindow = function (infoWindow) {
    this._marker._infoWindow = infoWindow;
    return this;
  };

  this.setNavigation = function (address) {
    var addr = address || _MAKE_ROUTE;

    this._marker._infoWindow += aNavigation.getNavigationLink(addr);

    return this;
  };

  this.setAnimation = function (animationName) {
    var animation;
    switch (animationName) {
      case 'DROP':
        animation = google.maps.Animation.DROP;
        break;
      default:
        throw new Error('Unknown animation: ' + animationName);
    }
    this._marker.animation = animation;
    return this;
  };

  this.setDraggable = function (boolean) {
    this._marker.draggable = boolean;
    return this;
  };

  this.setDynamic = function (boolean) {
    this._marker.dynamic = boolean;
    return this;
  };

  this.setClickable = function (boolean) {
    this._marker.clickable = boolean;
    return this;
  };

  this.setMetaInformation = function (object) {
    this._marker.metaInfo = object;
    return this;
  };

  this.build = function () {
    if (this._marker.position == null) {
      throw new Error("Position not set");
    }

    if (this._marker.map == null) {
      this._marker.map = map;
    }

    if (this._marker.title == null) {
      this._marker.title = '';
    }

    var result = new google.maps.Marker(this._marker);

    result.latLng = {
      lat: result.position.lat,
      lng: result.position.lng
    };

    //create infowindow
    infoWindows[this._marker.id] = new InfoWindowBuilder()
      .setMarker(this._marker)
      .setContent(this._marker._infoWindow)
      .build();

    if (this._marker.clickable) {
      google.maps.event.addListener(result, 'click', function () {
        closeInfoWindows();

        //open _infoWindow for current marker;
        //infoWindows[id].open(map, markers[id]);
        var infoWindow = this._infoWindow;
        infoWindow.setContent(infoWindow.content);

        //open infowindow
        openedInfoWindows.push(infoWindow);
        infoWindow.open(map, this);
      });
      result._infoWindow = infoWindows[this._marker.id];
    }

    if (this._marker.draggable && this._marker.type == 'user') {
      google.maps.event.addListener(result, 'dragend', function (event) {
        mapCenterLatLng = event.latLng;
      });
    }

    //if this marker is not an DB object, add it to second Clusterer
    if (this._marker.dynamic) {
      if (!markerHolder) markerHolder = new MarkerClusterer(map);
      markerHolder.addMarker(result);
    }

    //clear
    this._marker = {};
    return result;
  };

  this.getIconFileName = function (fileName) {
    var name = fileName;
    //Check if it is not an external URL
    if (fileName.indexOf('://') == -1 && fileName.indexOf('images') == -1)
      name = '/styles/default_adm/img/maps/' + fileName + '.png';

    return name;
  };

}

var CircleBuilder = (function () {
  
  function build(Circle, marker) {
    
    var circle = new google.maps.Circle({
      map: null,
      radius: Circle.RADIUS
    });
    
    circle.bindTo('center', marker, 'position');

    return circle;
  }
  
  return {
    build: build
  }
  
})();

var PolylineBuilder = (function () {

  function build(object) {
    var polyline = new google.maps.Polyline(object);

    google.maps.event.addListener(polyline, 'click', function (event) {

      closeInfoWindows();

      PolyInfoWindow = new google.maps.InfoWindow({});
      PolyInfoWindow.setContent(object.POLYINFOWINDOW);
      PolyInfoWindow.position = event.latLng;
      PolyInfoWindow.open(map);

    });

    return polyline;
  }

  return {
    build: build
  }

})();

var PolygonBuilder = (function () {

  var defaults = {
    strokeColor: aColorPalette.getNextColorHex(),
    strokeOpacity: 0.8,
    strokeWeight: 2,
    fillColor: aColorPalette.getCurrentColorHex(),
    fillOpacity: 0.35
  };

  function build(object) {
    var res = $.extend({}, defaults, object);
    return new google.maps.Polygon(res);
  }

  return {
    build: build
  }

})();

var SymbolBuilder = (function(){
  
  function build(object) {
    var objectColor = (object.COLOR) ? aColorPalette.getColorHex(object.COLOR) : aColorPalette.getNextColorHex();

    return {
      path: google.maps.SymbolPath[(object.path)],
      scale: 8,
      strokeColor: objectColor
    }
  }
  
  
  return {
    build: build
  }
  
})();

function InfoWindowBuilder(marker) {

  this._infoWindow = {};

  if (marker)
    this._infoWindow.position = marker.position;

  this._infoWindow.content = '';

  this.setPosition = function (latLng) {
    this._infoWindow.position = latLng;
    return this;
  };

  this.getPosition = function () {
    return this._infoWindow.position;
  };

  this.setMarker = function (markerObj) {
    this._infoWindow.position = markerObj.position;
    this._infoWindow.content = markerObj.title;

    return this;
  };

  this.setContent = function (text) {
    this._infoWindow.content = text;

    return this;
  };

  this.build = function () {
    var result = new google.maps.InfoWindow(this._infoWindow);

    this._infoWindow = {};

    return result;
  };
}

function MapControls(map) {
  this._controlDivs = [];

  this.addBtn = function (icon, onclickString, title, id, class_) {
    var index = this._controlDivs.length;
    var div = document.createElement('div');

    var controlBtnDiv = createControlBtn(icon, onclickString, class_);

    if (typeof (id) !== 'undefined')
      $(div).attr('id', id);
    else
      $(div).attr('id', 'ctrlBtn_' + index);

    new SimpleControlObject(div, title, controlBtnDiv);

    div.index = index;

    this._controlDivs[index] = div;
    return this;
  };


  this.addDropdown = function (icon, arrOptions, title, id, class_) {
    var index = this._controlDivs.length;
    var div = document.createElement('div');

    if (typeof (id) !== 'undefined')
      $(div).attr('id', id);
    else
      $(div).attr('id', 'ctrlBtn_' + index);

    var divB = createBtnDropdown(icon, arrOptions, class_, id);

    new SimpleControlObject(div, title, divB);

    div.index = index;

    this._controlDivs[index] = div;
    return this;
  };

  this.hideBtn = function (id) {
    $('#' + id).hide();
    var center = map.getCenter();
    google.maps.event.trigger(map, "resize");
    map.setCenter(center);
  };

  this.init = function () {
    if (this._controlDivs.length > 0)
    //Pass it to google maps control block;
      $.each(this._controlDivs, function (i, entry) {
        map.controls[google.maps.ControlPosition.TOP_CENTER].push(entry)
      });

    events.emit('controlsready', true);
  };

  this.reload = function () {
    map.controls[google.maps.ControlPosition.TOP_CENTER] = {};

    this.init();
  };
  
  function createBtnDropdown(icon, arrOptions, class_, id) {

    var btnClass = class_ || 'primary';
    var options = [];
    $.each(arrOptions, function (i, entry) {
      if (entry != undefined) {
        options[i] = '<li><a role="button" onclick="' + entry[1] + '" id="' + id + '_' + i + '">' + entry[0] + '</a></li>';
      }
    });

    return '<div class="btn-group">' +
      '<button type="button" class="btn btn-' + btnClass + ' dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">' +
      '<span class="glyphicon glyphicon-' + icon + '"></span>&nbsp;<span class="caret"></span></button>' +
      '<ul class="dropdown-menu">' +
      options.join("") +
      '</ul>' +
      '</div>'
  }

  function createControlBtn(icon, onclickString, newBtnClass) {
    var btnClass = newBtnClass || 'primary';
    return '<div class="btn-group">' +
      '<button type="button" class="btn btn-' + btnClass + '" onclick="' + onclickString + '">' +
      '<span class="glyphicon glyphicon-' + icon + '"></span></button>' +
      '</button>' +
      '</div>';
  }


  function SimpleControlObject(controlDiv, title, text, onclick) {
    // Set CSS for the control border.
    var controlUI = document.createElement('div');
    controlUI.style.backgroundColor = '#fff';
    controlUI.style.border = '2px solid #fff';
    controlUI.style.borderRadius = '1px';
    controlUI.style.boxShadow = '0 2px 6px rgba(0.3,0,.3,0)';
    controlUI.style.cursor = 'pointer';
    controlUI.style.margin = '0';
    controlUI.style.padding = '0';
    controlUI.style.textAlign = 'center';
    controlUI.title = title;
    controlDiv.appendChild(controlUI);

    // Set CSS for the control interior.
    var controlText = document.createElement('div');
    controlText.style.color = 'rgb(25,25,25)';
    controlText.style.fontFamily = 'Roboto,Arial,sans-serif';
    controlText.style.fontSize = '16px';
    controlText.style.paddingLeft = '0';
    controlText.innerHTML = text;
    controlUI.appendChild(controlText);

    // Setup the click event listeners.
    if (onclick) {
      controlUI.addEventListener('click', function () {
        onclick();
      });
    }

  }

}

function Navigation(map) {
  var self = this;

  this.init = function (map) {
    this.directionsService = new google.maps.DirectionsService;
    this.directionsDisplay = new google.maps.DirectionsRenderer;
    this.directionsDisplay.setMap(map)
  };

  if (map) {
    this.init(map);
  }

  this.getNavigationLink = function (string) {
    return '<br /></hr><br />' + '<div class="text-center">' +
      '<a onclick="aNavigation.createNavigationRoute(mapCenterLatLng, openedInfoWindows[openedInfoWindows.length - 1].position)">' +
      '<span class="glyphicon glyphicon-share-alt"></span>&nbsp;' +
      string +
      '</a>' +
      '</div>';
  };

  this.createNavigationRoute = function (origin, destination, callback) {
    var request = ({
      origin: origin,
      destination: destination,
      travelMode: google.maps.TravelMode.DRIVING,
      unitSystem: google.maps.UnitSystem.METRIC
    });

    this.directionsService.route(request, function (response, status) {
      if (status === google.maps.DirectionsStatus.OK) {
        aNavigation.directionsDisplay.setDirections(response);
        if (callback) {
          callback(response);
        }
      } else {
        window.alert('Directions request failed due to ' + status);
      }
    });
  };

  this.showRoute = function () {
    if (!hasRealPosition) {
      getLocation(function (positionArr) { //success
        var lat = positionArr[0];
        var lng = positionArr[1];

        var latLng = createPosition(lat, lng);

        self.createNavigationRoute(latLng, aMap.getCenter());
      }, function () { //error
        alert("Can't get your real position");
      })
    } else {
      self.createNavigationRoute(realPosition, aMap.getCenter());
    }
  };

  this.createExtendedRoute = function (destination) {
    if (!hasRealPosition) {
      getLocation(function (positionArr) { //success
        var lat = positionArr[0];
        var lng = positionArr[1];

        var latLng = createPosition(lat, lng);

        self.createNavigationRoute(latLng, destination, function (response) {
          var leg = response.routes[0].legs[0];

          var distance = leg.distance.text;
          var duration = leg.duration.text;

          var start_address = leg.start_address;
          var end_address = leg.end_address;

          var body = '' +
            '<label>' + _START + ':&nbsp;</label>' + '<span>' + start_address + '</span><br />' +
            '<label>' + _END + ':&nbsp;</label>' + '<span>' + end_address + '</span><br />' +
            '<label>' + _DISTANCE + ':&nbsp;</label>' + '<span>' + distance + '</span><br />' +
            '<label>' + _DURATION + ':&nbsp;</label>' + '<span>' + duration + '</span><br />';


          aModal.clear()
            .setHeader(_ROUTE)
            .setBody(body)
            .show();
        })
      });
    }
  }

}

function Search() {
  this.service = null;
  this.ready = false;
  this.isAvailable = true;
  /**
   * Provides NearbySearch for defined types: atm, bank, etc
   * @param objectTypes - an array of types
   * @param location - a Position object
   */
  this.init = function (map) {
    this.service = new google.maps.places.PlacesService(map);
    this.ready = true;
  };

  this.isReady = function () {
    return this.ready;
  };

  this.makeNearbySearch = function (objectTypes, location) {
    if (!this.ready) this.init(map);
    this.service.nearbySearch({
      location: location,
      radius: 5000,
      types: objectTypes
    }, callbackDefault);

  };

  /** Provides searching for a keywords
   * Query can be a text */
  this.makeQuerySearch = function (query, location) {
    if (!this.ready) this.init(map);
    if (query) {
      var request = {
        location: location,
        radius: '5000',
        query: query
      };

      this.service.textSearch(request, callbackDefault);
    }
  };

  /** Callback for search */
  function callbackDefault(results, status) {
    if (status === google.maps.places.PlacesServiceStatus.OK) {
      for (var i = 0; i < results.length; i++) {

        // Swap coordinates
        var temp = results[i].geometry.location.lat;
        results[i].geometry.location.lat = results[i].geometry.location.lng;
        results[i].geometry.location.lng = temp;

        createDefaultMarker(results[i], form_icon);
      }
    }
  }

}