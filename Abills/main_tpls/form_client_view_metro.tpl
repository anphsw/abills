<link rel="stylesheet" type="text/css" href="https://fonts.googleapis.com/css?family=Roboto">
<link rel="stylesheet" type="text/css" href="/styles/%HTML_STYLE%/css/infopanels.css">

<div class="row dynamicTile">
    <div class="row">
        <div id="infoPanelsDiv"></div>
    </div>
</div>

<!-- InfoPanels -->
<script type='text/javascript' src='/styles/%HTML_STYLE%/js/infopanels.js'></script>

<script>
    var panels = %METRO_PANELS% ;
    if (panels.length > 0){
        jQuery.each(panels, function (index, entry) {
            AInfoPanels.InfoPanelsArray.push(entry);
        });

        events.emit('infoPanels_renewed', true);
    }
</script>
