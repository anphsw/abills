<script>
  jQuery('.gps-map-btn').on('click', function() {
    let coords = jQuery(this).data('coords');
    if (!coords) return;

    map.setView(coords.split(';'), 18);
  })
</script>