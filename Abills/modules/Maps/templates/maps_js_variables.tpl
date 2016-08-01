<!-- Processing Perl vars to JS -->
<script>
    var index = '$index';
    var map_index = '%MAP_INDEX%';

    var MAP_TYPE = '%MAP_TYPE%';
    var MAP_KEY = '%MAP_API_KEY%';

    var _USER = '_{USER}_';
    var _USERS = '_{USERS}_';
    var _STREET = '_{STREET}_';
    var _BUILD = '_{BUILD}_';
    var _NAVIGATION_WARNING = '_{NAVIGATION_WARNING}_' || 'You have disabled retrieving your location in browser';

    var _ROUTE = '_{ROUTE}_' || 'Route';
    var _ROUTES = '_{ROUTES}_' || 'Routes';
    var _WIFI = '_{WIFI}_' || 'Wi-Fi';
    var _DISTRICT = '_{DISTRICT}_' || 'District';
    var _WELL = '_{WELL}_' || 'Well';
    var _CUSTOM_POINT = '_{CUSTOM_POINT}_' || 'Custom point';
    var _WELLS = '_{WELLS}_' || 'Wells';
    var _GPS = 'GPS';
    var _ADD = '_{ADD}_' || 'Add';
    var _NEW = '_{NEW}_' || 'New';
    var _POINT = '_{POINT}_' || 'Point';
    var _BUILDS = '_{BUILDS}_' || 'Builds';
    var _TRAFFIC = '_{TRAFFIC}_' || 'Traffic';

    var _SEARCH = '_{SEARCH}_' || 'Search';
    var _BY_QUERY = '_{BY_QUERY}_' || 'By Query';
    var _BY_TYPE = '_{BY_TYPE}_' || 'By Types';

    var _TOGGLE = '_{TOGGLE}_' || 'Toggle';
    var _POLYGONS = '_{POLYGONS}_' || 'Polygons';
    var _MARKER = '_{MARKER}_' || 'Marker';
    var _CLUSTERS = '_{CLUSTERS}_' || 'Clusters';

    var _REMOVE = '_{REMOVE}_' || 'Remove';
    var _LOCATION = '_{LOCATION}_' || 'Location';

    var _MAP_OBJECT_LAYERS = '_{MAP_OBJECT_LAYERS}_' || 'Map object Layers';
    var _DROP = '_{DROP}_' || 'Drop';

    var _MAKE_ROUTE = '_{MAKE_ROUTE}_' || 'Make Navigation Route';
    var _NOW_YOU_CAN_REMOVE_MARKER = '_{NOW_YOU_CAN_REMOVE_MARKER}_' || 'Now you can remove marker';
    var _CLICK_ON_A_MARKER_YOU_WANT_TO_DELETE = '_{CLICK_ON_A_MARKER_YOU_WANT_TO_DELETE}_' || 'Click on a marker you want delete';

    var _NOW_YOU_CAN_ADD_NEW = '_{NOW_YOU_CAN_ADD_NEW}_' || 'Now you can add new';
    var _DEL_MARKER = '_{DELETE_MARKER}_' || 'Delete marker';
    var _TO_MAP = '_{TO_MAP}_' || 'to map';

    var _NAVIGATION = '_{NAVIGATION}_' || 'Go to point';

    var _LANG_TYPE_NAME = {
        BUILD: _BUILD,
        ROUTE: _ROUTE,
        WIFI: _WIFI,
        DISTRICT: _DISTRICT,
        WELL: _WELL,
        CUSTOM_POINT : _CUSTOM_POINT
    };

    var _DISTANCE = '_{DISTANCE}_' || 'Distance';
    var _DURATION = '_{DURATION}_' || 'Duration';

    var _END = '_{END}_' || 'End';
    var _START = '_{START}_' || 'Start';

    //ENABLING FEATURES
    var SHOW_MARKERS = '%SHOW_MARKERS%' || true;
    var CLUSTERING_ENABLED = '%CLUSTERING_ENABLED%' || true;
    var DISTRICT_POLYGONS_ENABLED = '%DISTRICT_POLYGONS_ENABLED%' || true;

    //CONTROL BLOCK
    var addPointCtrlEnabled = '%ADD_FORM%' || false;
    var layersCtrlEnabled = true;
    var searchCtrlEnabled = true;
    var navigationCtrlEnabled = '%NAVIGATION_BTN%' || false;

    var GPS_layer_enabled = '%HAS_GPS_LAYER%' || false;

    //INPUT PARAMS
    var mapCenter = '%MAPSETCENTER%';
    var CONF_MAPVIEW = '%MAP_VIEW%' || '';

    var form_x = '%COORDX%';
    var form_y = '%COORDY%';

    var form_title = '%TITLE%';
    var form_content = '%CONTENT%';

    var form_query_search = '%search_query%';
    var form_type_search = '%search_type%';
    var form_icon = '%ICON%';

    var form_show_controls = '%SHOW_CONTROLS%' || false;

    var form_show_build = '%show_build%' || false;
    var form_show_gps = '%show_gps%' || false;
    var form_no_route = '%NO_ROUTE%' || false;
    var form_date = '%DATE%' || false;

    var form_location_id = '%LOCATION_ID%';
    var form_route_id = '%ROUTE_ID%';
    var form_location_type = '%LOCATION_TYPE%';

    var form_make_navigation_route = '%makeNavigationTo%';
    var form_nav_x = '%nav_x%';
    var form_nav_y = '%nav_y%';

    //Constants
    var BUILD = "BUILD";
    var ROUTE = "ROUTE";
    var DISTRICT = "DISTRICT";
    var WIFI = "WIFI";
    var WELL = "WELL";
    var NAS = "NAS";
    var GPS = "GPS";
    var GPS_ROUTE = "GPS_ROUTE";
    var TRAFFIC = "TRAFFIC";
    var CUSTOM_POINT = 'CUSTOM_POINT';

    var POINT = "POINT";
    var LINE = "LINE";
    var POLYGON = "POLYGON";
    var CIRCLE = "CIRCLE";

    var CLIENTS_ONLINE = "CLIENTS_ONLINE";
    var CLIENTS_OFFLINE = "CLIENTS_OFFLINE";


</script>
