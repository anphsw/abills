/**
 * Created by Anykey on 06.01.2016.
 *
 */

//Legacy fix
var ymaps = window['ymaps'];
var google = ymaps;

var MarkerClusterer = ymaps.Clusterer;

/**
 * Created by Anykey on 02.10.2015.d
 */


var aDrawController;

function DrawController() {
  var self = this;
  this.aObjectRegistrator = new AObjectRegistrator();

  this.options = {
    enabled: false,
    editing: false
  };

  this.geometry = null;
  this.drawingManager = null;
  this.map = null;

  this.callback = function (e) {
    var mapObject = this.aObjectRegistrator.getMapObject();
    mapObject.setLatLng(e.position);

    console.warn('default callback');
  };


  this.setControlsEnabled = function (boolean) {
    // this.options.drawingControl = boolean;
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
    _log(1, 'Yandex Maps DrawController', 'init');
    return this;
  };

  this.getObjectRegistrator = function () {
    return this.aObjectRegistrator;
  };

  this.clearDrawingMode = function () {
    this.drawingManager.setDrawingMode(null);
  };

  this.setDrawingMode = function (string) {
    // if (this.drawingManager == null)
    //   throw new Error("drawingManager not initialized");

    _log(1, "Type setDrawingMode", string);
    // var drawingMode = '';
    switch (string) {
      case null:

        if (self.drawingManager){
          self.drawingManager.stopEditing();
          self.drawingManager = null;
        }

        return true;
        break;
      case CUSTOM_POINT:
      case POINT:
        self.geometry = (new MarkerBuilder(map))
          .setIcon("build_green")
          .setPosition([])
          .build();

        break;
      case LINE:
        self.geometry = PolylineBuilder.build(
          {
            path : [],
            strokeColor: '#ff0000',
            strokeWidth: 5
          });

        break;
      case POLYGON:
        self.geometry = new ymaps.Polygon();
        break;
      case CIRCLE:
        // https://tech.yandex.ru/maps/doc/jsapi/2.1/ref/reference/Circle-docpage/#geometry
        (new ATooltip).display("<h3>Not Implemented in Yandex Maps API</h3>", 3000);
        return false;

        self.geometry = CircleBuilder.build(
          { // CIRCLE
            RADIUS : 0.0
          },
          { // MARKER
            geometry : { _coordinates : [] }
          }
        );
        break;
      default:
        console.warn('Unsupported drawing mode: ' + string);
    }

    if (self.geometry == null) {
      console.warn("Geometry is null");
    }

    // Add to map
    map.geoObjects.add(self.geometry);

    // Extract editor
    self.drawingManager = self.geometry.editor;

    this.drawingManager.startEditing();
    this.drawingManager.startDrawing();

    // TODO: Add confirmBtn to MapControls
    self.geometry.events.once('click', function () { self.geometry.editor.stopEditing() });

    // Define callback
    self.geometry.events.once('editorstatechange', function(){
      self.callback(self.geometry);
    });

    return true;
  };

  this.getDrawingManager = function () {
    return this.drawingManager;
  };

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
    if (!aDrawController.setDrawingMode(ObjectTypeRefs[type])) {
      throw new Error("Draw Controller not loaded");
    }

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

  // FIXME: MapLayers should do this
  for (var key in markers) {
    //remove default listener
    google.maps.event.clearInstanceListeners(markers[key], 'click');

    //add custom listener
    google.maps.event.addListener(markers[key], 'click', function () {
      console.log(this);
      showConfirmModal(this.id)
    });
  }

  // FIXME : mapControls should do this
  var btn = $('#dropOperationCtrlBtn').find('button');
  btn.attr('class', 'btn btn-danger');

  new ATooltip('<h2>' + _NOW_YOU_CAN_REMOVE_MARKER + '</h2>')
    .setClass('danger')
    .setTimeout(1000)
    .show();

  setTimeout(function () {
    new ATooltip('<h2>' + _CLICK_ON_A_MARKER_YOU_WANT_TO_DELETE + '</h2>')
      .setClass('info')
      .setTimeout(1000)
      .show();
  }, 2000);

  function showConfirmModal(id) {
    var confirmModalRemove = aModal.clear();

    confirmModalRemove
      .setBody('<div id="confirmModalContent">' + _REMOVE + '?</div>')
      .setFooter(
        '<button id="confirmModalCancelBtn" class="btn btn-default">Cancel</button>' +
        '<button id="confirmModalConfirmBtn" class="btn btn-success">Yes</button>')
      .show(bindBtnEvents);


    function bindBtnEvents(modal) {
      $('#confirmModalCancelBtn').on('click', function (modal) {
        discardRemovingPoint(modal);
      });

      $('#confirmModalConfirmBtn').on('click', function () {
        confirmModalRemove.destroy();
        removeMarker(id);
      });
    }

  }

  function removeMarker(id) {
    loadToModal(aBillingAddressManager.removeMarkersCoords(id))
  }
}

function discardRemovingPoint() {
  aModal.destroy();
  location.reload(false);
}

var confirmModal = new AModal();
var drawing_last_overlay;
function overlayCompleteCallback(overlay) {

  //getRegistrator
  var registrator = aDrawController.getObjectRegistrator();

  //getObject
  var object = registrator.getMapObject();

  drawing_last_overlay = overlay;

  //Legacy
  drawing_last_overlay.position = drawing_last_overlay.latLng;

  //Pass overlay to object
  object.emit(drawing_last_overlay);

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

function AMap() {
  
  var self = this;
  
  _log(LEVEL_INFO, MODULE, 'YMaps AMap.constructor ');
  
  this.map = null;
  
  this.init = function (mapDiv, mapOptions, callback) {
    var mapOptions_ = mapOptions || {};
    
    // Set default center
    mapOptions_.center = mapOptions_.center || [48, 25];
    mapOptions_.zoom = mapOptions_.zoom || 9;
    mapOptions_.controls = ['smallMapDefaultSet'];
    
    self.map = new ymaps.Map(
      mapDiv.id,
      mapOptions_
    );
    
    if (callback) callback(this.map);
    return this.map;
  };
  
  this.createPosition = function (x, y) {
    return [x, y];
  };
  
  this.setCenter = function (x, y) {
    this.map.setCenter([x, y]);
  };
  
  this.getCenter = function () {
    return this.map.getCenter();
  };

  this.setZoom = function (zoom) {
    //this.map.setZoom(zoom);
  };

  this.addObjectToMap = function (object) {
    self.map.geoObjects.add(object);
  };
  
  this.removeObjectFromMap = function (object) {
    self.map.geoObjects.remove(object);
  };

  this.animatePolyline = function (polyline) {
    return false;
  };
  
  this.getNewClusterer = function () {
    var markerClusterer = new ymaps.Clusterer();

    map.geoObjects.add(markerClusterer);

    markerClusterer.setGridSize = function (grid_size) {
      this.options.gridSize = grid_size;
    };

    markerClusterer.addMarker = function (marker) {
      this.add(marker);
    };
    markerClusterer.addMarkers = function (marker) {
      this.add(marker);
    };

    markerClusterer.removeMarker = function (marker) {
      this.remove(marker);
    };

    markerClusterer.clearMarkers = function () {
      this.removeAll();
    };


    return markerClusterer;
  };
  
  this.getLength = function (arrayOfPoints) {
    return arrayOfPoints.polyline.geometry.getDistance();
  }
}

AMap.prototype = map;

function MarkerBuilder(map) {
  this._marker = {};
  
  this._marker.type = 'default';
  
  this._marker.map = map;
  this._marker.geometry = {};
  this._marker.properties = {};
  this._marker.options = {};
  
  this._marker.options.draggable = false;
  this._marker.openBaloonOnClick = false;
  
  this.setId = function (id) {
    this._marker.id = id;
    return this;
  };
  
  this.setTitle = function (title) {
    this._marker.hintContent = title;
    return this;
  };
  
  this.setLabel = function (label) {
    if (label) {
      this._marker.label = label;
    }
    return this;
  };
  
  this.setIcon = function (fileName, sizeArr) {

    // Default icon size
    var width = 32;
    var height = 37;

    if (fileName != null) {
      this._marker.type = fileName;
      
      var name = this.getIconFileName(fileName);
      
      // this._marker.properties.iconContent = "<img src='"+ name +"' />";
      // this._marker.properties.iconSize = [20,20];
      
      this._marker.options.iconLayout = 'default#image';
      this._marker.options.iconImageHref = name;

      if (typeof sizeArr != 'undefined') {
        width = sizeArr[0];
        height = sizeArr[1];
      }
      this._marker.options.iconImageSize = [width, height];
      this._marker.options.iconImageOffset = [-width / 2, -height / 2];
    }
    
    return this;
  };

  this.setIconOffset = function (offsetArr) {
    // var deltaX = offsetArr[0];
    // var deltaY = offsetArr[1];

    this._marker.options.iconImageOffset = offsetArr;
    return this;
  };

  this.setType = function (type) {
    this._marker.type = type;
    return this;
  };
  
  this.setPosition = function (latLng) {
    this._marker.geometry.coordinates = latLng;
    return this;
  };
  
  this.setInfoWindow = function (infoWindow) {
    this._marker.properties.balloonContentBody = infoWindow;
    return this;
  };
  
  this.setNavigation = function (address) {
    console.log('Maps Yandex', 'NOT IMPLEMENTED');
    var addr = address || _MAKE_ROUTE;
    
    this._marker.properties.balloonContentBody += aNavigation.getNavigationLink(addr);
    
    return this;
  };
  
  this.setAnimation = function (animationName) {
    // NOT SUPPORTED
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
    this._marker.openBaloonOnClick = boolean;
    // this._marker.clickable = boolean;
    return this;
  };
  
  this.setMetaInformation = function (object) {
    this._marker.metaInfo = object;
    return this;
  };

  this.build = function () {
    if (this._marker.geometry.coordinates == null) {
      throw new Error("Position not set");
    }
    
    if (this._marker.map == null) {
      this._marker.map = map;
    }
    
    if (this._marker.title == null) {
      this._marker.title = '';
    }
    
    var result = new ymaps.Placemark(this._marker.geometry.coordinates, this._marker.properties, this._marker.options);

    if (this._marker.metaInfo){
      result.metaInfo = this._marker.metaInfo;
    }

    // Google Marker interface
    result.setMap = function (map_) {
      if (map_ != null) {
        map.geoObjects.add(this);
      } else {
        map.geoObjects.remove(this);
      }
    };

    result.latLng = {
      lat: function () {
        return result.geometry._coordinates[0]
      },
      lng: function () {
        return result.geometry._coordinates[1]
      }
    };

    //clear
    this._marker = {};
    return result;
  };
  
  this.getIconFileName = function (fileName) {
    var name = fileName;
    //Check if it is not an external URL
    if (fileName.indexOf('://') == -1)
      name = '/styles/default_adm/img/maps/' + fileName + '.png';
    
    return name;
  };

}


var CircleBuilder = (function () {

  function build(Circle, marker) {
    console.log(marker);
    var circle = new ymaps.Circle([marker.geometry._coordinates, Circle.RADIUS], {},
      {
        geodesic: true
      }
    );

    circle.setMap = function (state) {
      if (state == null) {
        map.geoObjects.remove(this);
      } else {
        map.geoObjects.add(this);
      }
    };

    return circle;
  }

  return {
    build: build
  }

})();


var PolylineBuilder = (function () {

  function build(object) {
    var polyline = new ymaps.Polyline(object.path, {
      hintContent: object.POLYINFOWINDOW
    }, {
      strokeColor: object.strokeColor || '#ff0000',
      strokeWidth: object.strokeWidth || 2,
    });

    polyline.setMap = function (state) {
      if (state != null)
        map.geoObjects.add(this);
      else
        map.geoObjects.remove(this);
    };

    polyline.getPath = function () {
      return {
        getArray: function () {
          var path = polyline.geometry.getCoordinates();
          var array = [];
          $.each(path, function (i, pairOfPoints) {
            // $.each(pairOfPoints, function (i, point) {
            pairOfPoints.lat = function () {
              return pairOfPoints[0]
            };
            pairOfPoints.lng = function () {
              return pairOfPoints[1]
            };
            // });
            array.push(pairOfPoints);
          });
          array.polyline = polyline;
          return array;
        }
      }
    };

    polyline.getLength = function () {
      var distance = 0;

      for (var i = 0, l = polyline.getNumPoints(), point; i < l; i++) {
        if (point) {
          distance += point.distance(polyline.getPoint(i));
        }
        point = polyline.getPoint(i);
      }

      return distance;
    };

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
    strokeWidth: 2,
    fillColor: aColorPalette.getCurrentColorHex(),
    fillOpacity: 0.35
  };

  function build(object) {

    // Legacy
    object.strokeWidth = object.strokeWeight;

    if (object.paths[0].lat) { // Google typed coords
      $.each(object.paths, function (i, point) {
        point[0] = point.lat;
        point[1] = point.lng;
      });
    }

    var res = $.extend({}, defaults, object);

    return new ymaps.Polygon([res.paths], {}, res);
  }


  return {
    build: build
  }
})();

// function InfoWindowBuilder(marker) {
//
//   this._infoWindow = {};
//
//   if (marker)
//     this._infoWindow.position = marker.position;
//
//   this._infoWindow.content = '';
//
//   this.setPosition = function (latLng) {
//     this._infoWindow.position = latLng;
//     return this;
//   };
//
//   this.getPosition = function () {
//     return this._infoWindow.position;
//   };
//
//   this.setMarker = function (markerObj) {
//     this._infoWindow.position = markerObj.position;
//     this._infoWindow.content = markerObj.title;
//
//     return this;
//   };
//
//   this.setContent = function (text) {
//     this._infoWindow.content = text;
//
//     return this;
//   };
//
//   this.build = function () {
//     var result = new google.maps.InfoWindow(this._infoWindow);
//
//     this._infoWindow = {};
//
//     return result;
//   };
// }

function MapControls(map) {
  
  var self = this;

  this._controlDivs = [];
  
  this.btnTemplate =
    '<div id="{{data.id}}" class="conrolBtn">' +
    '<div title="{{data.title}}">' +
    '<div>' +
    '<div class="btn-group">' +
    '<button type="button" class="btn btn-{{ data.class_ }}" {% if data.onclick %} onclick="{{ data.onclick }}" {% endif %}>' +
    '<span class="glyphicon glyphicon-{{data.iconName}}"></span></button>' +
    '</div>' +
    '</div>' +
    '</div>' +
    '</div>';
  this.btnLayout = ymaps.templateLayoutFactory.createClass(this.btnTemplate);
  
  this.dropdownItemTemplate =
    '<li>' +
    '<a role="button" onclick="{{ data.onclick }}" id="{{data.parent_id}}_{{data.index}}">{{data.text}}</a>' +
    '</li>';
  this.dropdownItemLayout = ymaps.templateLayoutFactory.createClass(this.dropdownItemTemplate);
  
  this.dropdownTemplate =
    '<div id="{{data.id}}">' +
    '<div title="{{data.title}}">' +
    '<div class="btn-group">' +
    '<button type="button" class="btn btn-{{data.class_}} dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">' +
    '<span class="glyphicon glyphicon-{{data.iconName}}"></span>&nbsp;<span class="caret"></span>' +
    '</button>' +
    '<ul class="dropdown-menu" id="dropdown_menu_{{ data.id }}">' +
    '</ul>' +
    '</div>' +
    '</div>' +
    '</div>';
  
  this.dropdownTemplateLayout = ymaps.templateLayoutFactory.createClass(this.dropdownTemplate,
    {
      build: function () {
        self.dropdownTemplateLayout.superclass.build.call(this);
        this.childContainerElement = $('#dropdown_menu_' + this._data.data._data.id).get(0);
        
        this.events.fire('childcontainerchange', {
          newChildContainerElement: this.childContainerElement,
          oldChildContainerElement: null
        });
      },
      
      getChildContainerElement: function () {
        return this.childContainerElement;
      }
    }
  );

  this.addBtn = function (icon, onclickString, title, id, class_) {

    var button = new ymaps.control.Button({
      data: {
        iconName: icon,
        onclick: onclickString,
        title: title,
        id: id,
        class_: class_ || 'primary'
      },
      options: {
        layout: this.btnLayout,
        maxWidth: 40
      }
    });

    this._controlDivs.push(button);

    return this;
  };
  
  
  this.addDropdown = function (icon, arrOptions, title, id, class_) {

    var dropdownItems = [];

    for (var i = 0, len = arrOptions.length; i < len; i++) {
      var entry = arrOptions[i];

      dropdownItems[i] = new ymaps.control.ListBoxItem({
        data: {
          index: i,
          parent_id: id,
          text: entry[0],
          onclick: entry[1]
        },
        options: {
          layout: this.dropdownItemLayout
        }
      });

    }

    var dropDown = new ymaps.control.ListBox({
      data: {
        id: id || this._controlDivs.length,
        class_: class_ || 'primary',
        title: title,
        iconName: icon
      },

      items: dropdownItems,

      options: {
        layout: this.dropdownTemplateLayout
      }
    });

    this._controlDivs.push(dropDown);

    return this;
  };
  
  this.hideBtn = function (id) {
    $('#' + id).hide();
    var center = map.getCenter();
    // google.maps.event.trigger(map, "resize");
    map.setCenter(center);
  };
  
  this.init = function () {
    // Adding in reverse order
    for (var i = this._controlDivs.length; i > 0; i--) {
      map.controls.add(this._controlDivs[i - 1]);
    }
    events.emit('controlsready', true);
  };
  
  this.reload = function () {
    return false;
    // this.init();
  };
  
}

function Navigation() {
  
  var self = this;
  
  this.init = function (map) {
    _log(LEVEL_ERROR, MODULE, "Not implemented");
    return true;
    // this.directionsService = new google.maps.DirectionsService;
    // this.directionsDisplay = new google.maps.DirectionsRenderer;
    // this.directionsDisplay.setMap(map)
  };
  
  this.getNavigationLink = function (string) {
    return '<br /></hr><br />' + '<div class="text-center">' +
      '<a onclick="aNavigation.createNavigationRoute(mapCenterLatLng, currentInfoWindow.position)">' +
      '<span class="glyphicon glyphicon-share-alt"></span>&nbsp;' +
      string +
      '</a>' +
      '</div>';
  };
  
  this.createNavigationRoute = function (origin, destination, callback) {
    _log(LEVEL_ERROR, MODULE, "Not implemented");
    return true;
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
    _log(LEVEL_ERROR, MODULE, "Not implemented");
    return true;
    if (!hasRealPosition) {
      getLocation(function (positionArr) { //success
        var lat = positionArr[0];
        var lng = positionArr[1];
        
        var latLng = createPosition(lat, lng);
        
        self.createNavigationRoute(latLng, map.getCenter());
      }, function () { //error
        alert("Can't get your real position");
      })
    } else {
      self.createNavigationRoute(realPosition, map.getCenter());
    }
  };
  
  this.createExtendedRoute = function (destination) {
    _log(LEVEL_ERROR, MODULE, "Not implemented");
    return true;
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
  
  this.isAvailable = false;
  
  /**
   * Provides NearbySearch for defined types: atm, bank, etc
   * @param map
   */
  this.init = function (map) {
    // this.service = new google.maps.places.PlacesService(map);
    map.controls.add('searchControl');
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
        createDefaultMarker(results[i], form_icon);
      }
    }
  }

}