<!--Main Leaflet library-->
<link rel='stylesheet' href='/styles/default_adm/css/modules/maps/leaflet.css'>
<script src='/styles/default_adm/js/maps/leaflet.js'></script>

<!--Leaflet clusters-->
<link rel='stylesheet' href='/styles/default_adm/css/modules/maps/MarkerCluster.css'>
<link rel='stylesheet' href='/styles/default_adm/css/modules/maps/MarkerCluster.Default.css'>
<script src='/styles/default_adm/js/maps/leaflet.markercluster.js'></script>

<!--Leaflet measure control-->
<link rel='stylesheet' href='/styles/default_adm/css/modules/maps/Leaflet.PolylineMeasure.css'>
<script src='/styles/default_adm/js/maps/Leaflet.PolylineMeasure.js'></script>

<!--Leaflet fullscreen-->
<link rel='stylesheet' href='/styles/default_adm/css/modules/maps/leaflet.fullscreen.css'>
<script src='/styles/default_adm/js/maps/Leaflet.fullscreen.min.js'></script>

<!--Leaflet.draw-->
<link rel='stylesheet' href='/styles/default_adm/css/modules/maps/leaflet.draw.css'>
<script src='/styles/default_adm/js/maps/Leaflet.draw.all.js'></script>

<!--Google Maps-->
<script src='/styles/default_adm/js/maps/Leaflet.GoogleMutant.js'></script>

<!--Yandex Maps-->
<script src='/styles/default_adm/js/maps/Leaflet.YandexMap.js'></script>

<link href='/styles/default_adm/css/font-awesome.min.css' rel='stylesheet'>

<link rel='stylesheet' href='/styles/default_adm/css/modules/maps/new-maps.css'>

<script src='/styles/default_adm/js/maps/lodash.min.js'></script>

<script src='/styles/default_adm/js/maps/leaflet.semicircle.js'></script>

%JS_VARIABLES%

<div class='row' id="navbar_collapse" style="display: none">
</div>

<div class='row' id="navbar_container">
  <div class="leaflet-control-zoom leaflet-bar leaflet-control leaflet-custom">
    <a id='hide_button' class="leaflet-control-zoom-in" href="#" title="Hide menu" role="button"
       aria-label="Hide menu">-</a>
  </div>
  <div id="navbar_button_container"></div>
</div>

<div id="home_button" class="leaflet-bar leaflet-control" style="display: none">
  <a title="Go Home" class="polyline-measure-unicode-icon" id="home_a">
    <i class="fa fa-home" aria-hidden="true"></i>
  </a>
</div>


<div class='row' id="search_select">
  <form>
    <div class="input-group">
      <span class="input-group-addon" id="search_hs_button"><i class="glyphicon glyphicon-search"></i></span>
      <div id="select-div"><select id="SELECT_OBJECTS" style="width:100%"></select></div>
    </div>
  </form>
</div>

<div class='row'>

  <div class='box box-theme'>
    <div class='box-body' id='map-wrapper'>
      <div id='map' style='height: 85vh'></div>
    </div>
    <div class='box-footer'></div>
  </div>
  <div class='clearfix'></div>
</div>

<script>

  function putScriptInHead(id, url, callback_load) {
    if (document.getElementById(id))
      return 0;

    let scriptElement = document.createElement('script');

    if (callback_load)
      scriptElement.onload = callback_load;

    scriptElement.id = id;
    scriptElement.src = url;
    document.getElementsByTagName('head')[0].appendChild(scriptElement);
  }

  let map_height = MAP_HEIGHT || '85';
  map_height += 'vh';
  jQuery('#map').css({height: map_height});

  var selfUrl = '$SELF_URL';
  let hide = 0;

  jQuery('#hide_button').on('click', function () {
    if (hide === 0) {
      jQuery('#navbar_button_container').fadeOut(300);
      jQuery('a#hide_button').text('+');
      hide = 1;
    } else {
      jQuery('#navbar_button_container').fadeIn(300);
      jQuery('a#hide_button').text('-');
      hide = 0;
    }
  });

  if (document.getElementById('new_maps')) {
    init_map();
    loadLayers();
  } else {
    putScriptInHead('general_rquests_map', '/styles/default_adm/js/maps/new-general-requests.js',
      putScriptInHead('new_maps', '/styles/default_adm/js/maps/new-maps.js'));
  }
</script>

<!--<script src='/styles/default_adm/js/maps/new-general-requests.js'></script>-->
<!--<script id='maps_main' src='/styles/default_adm/js/maps/new-maps.js'></script>-->