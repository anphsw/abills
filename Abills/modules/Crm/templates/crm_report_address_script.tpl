<script>
  jQuery(function () {
    let street_select = jQuery('#STREET_ID');
    let build_select = jQuery('#BUILD_ID');

    jQuery('#DISTRICT_ID').on('change', function () {
      if (!jQuery(this).val()) return;

      let url = 'index.cgi?get_index=form_address_select2&header=2&DISTRICT_ID=' + jQuery(this).val() + '&STREET=1';
      fetch(url)
        .then(response => {
          if (!response.ok) throw response;
          return response;
        })
        .then(response => response.text())
        .then(result => {
          street_select.html(result);
          initChosen();
          street_select.focus();
          street_select.select2('open');
        })
        .catch(err => {
          console.log(err);
        });
    });

    street_select.on('change', function () {
      if (!jQuery(this).val() || jQuery(this).val() === '0') return;

      let url = 'index.cgi?get_index=form_address_select2&header=2&STREET_ID=' + jQuery(this).val() + '&BUILD=1';
      fetch(url)
        .then(response => {
          if (!response.ok) throw response;
          return response;
        })
        .then(response => response.text())
        .then(result => {

          build_select.html(result);
          build_select.removeAttr('onchange');
          initChosen();
          build_select.focus();
          build_select.select2('open');
        })
        .catch(err => {
          console.log(err);
        });
    });
  });
</script>