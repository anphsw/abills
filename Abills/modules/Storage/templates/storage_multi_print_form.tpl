<form action='%SELF_URL%' METHOD='POST'>
  <input type='hidden' name='index' value='%index%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{PRINT}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
      </div>
    </div>

    <div class='card-body p-0'>
      %TABLE%
    </div>

    <div class='card-footer'>
      <a href='?qindex=%index%&PRINT_DOC=%PRINT_DOC%&ACT=%ACT%&pdf=%PDF%'
         id='printBtn' target='docs' class='btn btn-primary float-right'>_{PRINT}_</a>
    </div>
  </div>
</form>

<script>
  jQuery(document).ready(function () {
    const printButton = jQuery('#printBtn');
    const checkboxes = jQuery("input[type='checkbox'][name='INSTALL_IDS']:not([disabled])");

    checkboxes.on('change', function() {
      const baseUrl = printButton.attr('href').split('&INSTALL_IDS=')[0];

      const checkedInstallations = checkboxes.filter(':checked')
        .map(function() {
          return this.value;
        })
        .get();

      if (checkedInstallations.length > 0) {
        const installationParam = '&INSTALL_IDS=' + checkedInstallations.join(';');
        printButton.attr('href', baseUrl + installationParam);
      } else {
        printButton.attr('href', baseUrl);
      }
    });
  });
</script>