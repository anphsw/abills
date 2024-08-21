<script type='text/javascript'>
  var ext_reports = {};

  sendRequest(`/api.cgi/ureports/plugins?snakeCase=1`, {}, 'GET')
    .then(data => {
      ext_reports = data;
      console.log(data)
    });

  jQuery(document).ready(function () {
    jQuery('#MODULE_%ID%').on('change', function() {
      let module = jQuery(this).val();
      jQuery('#COMMENTS_%ID%').val(ext_reports[module].COMMENTS);
    });
  });
</script>
