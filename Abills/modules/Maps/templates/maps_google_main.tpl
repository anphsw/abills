<!-- Google Maps -->


<!-- Processing Perl variables to JavaScript -->

%JS_VARIABLES%

<div class='panel panel-default'>
    <div class='panel-body' id='map-wrapper'>
        <div id='mapHelper' style='display: none; position: fixed; z-index: 9999; top: 10em; left: 35vw'
             aria-hidden='true' class='alert alert-warning'></div>
        <div id='map' class='col-md-12' style='height: 90vh'>
        </div>
    </div>
    <div class='panel-footer'></div>
</div>

<script id='maps_general' src='/styles/default_adm/js/maps/general.js'></script>

<!--Google maps specific logic-->
<script id='google_clusterer_script' src='/styles/default_adm/js/maps/google-clusterer.min.js'></script>
<script id='maps_google_script' src='/styles/default_adm/js/maps/google.js'></script>

<!-- General Maps logic -->
<script id='maps_script' src='/styles/default_adm/js/maps/maps.js'></script>

<!--Defining markers-->
<!-- Builds -->
<script defer> %BUILDS% </script>
<!-- NAS -->
<script defer> %NAS% </script>
<!-- OBJECTS -->
<script defer> %OBJECTS% </script>
<!-- ROUTES -->
<script defer> %ROUTES% </script>
<!-- WIFI -->
<script defer> %WIFIS% </script>
<!-- WELL -->
<script defer> %WELLS% </script>
<!-- GPS -->
<script defer> %GPS% </script>
