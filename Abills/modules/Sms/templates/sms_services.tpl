<form action='%SELF_URL%' method='post' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SERVICES}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label for='NAME' class='control-label col-md-3 required'>_{NAME}_:</label>
        <div class='col-md-9'>
          <input id='NAME' name='NAME' value='%NAME%' required placeholder='_{NAME}_' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='PLUGIN' class='control-label col-md-3 required'>Plug-in:</label>
        <div class='col-md-9'>
          %PLUGIN_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='STATUS'>_{DISABLED}_:</label>
        <div class='col-md-9'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='STATUS' name='STATUS' %STATUS% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='BY_DEFAULT'>_{DEFAULT}_:</label>
        <div class='col-md-9'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='BY_DEFAULT' name='BY_DEFAULT' %BY_DEFAULT% value='1'>
          </div>
        </div>
      </div>

      <div id='PLUGIN_SETTINGS_CONTAINER'></div>

      <div class='form-group row'>
        <label for='DEBUG' class='control-label col-md-3'>DEBUG:</label>
        <div class='col-md-9'>
          %DEBUG_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label for='DEBUG_FILE' class='control-label col-md-3'>DEBUG _{FILE}_:</label>
        <div class='col-md-9'>
          <input id='DEBUG_FILE' name='DEBUG_FILE' value='%DEBUG_FILE%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <div class='col-sm-12 col-md-12'>
          <textarea id='COMMENT' name='COMMENT' cols='50' rows='4' class='form-control' placeholder='_{COMMENTS}_'>%COMMENT%</textarea>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>

<script>
  try {
    var pluginsSettings = JSON.parse('%PLUGINS_SETTINGS%');
  } catch (err) {
    console.log('JSON parse error.');
  }

  jQuery(() => {
    if (jQuery('#SMS_PLUGIN').val()) {
      formPluginSetting(jQuery('#SMS_PLUGIN').val());
    }

    jQuery('#SMS_PLUGIN').on('change', function () {
      let plugin = jQuery(this).val();
      formPluginSetting(plugin);
    });
  });

  function clearSettings() {
    jQuery('#PLUGIN_SETTINGS_CONTAINER').html('');
  }

  function formPluginSetting(plugin) {
    clearSettings();

    if (!plugin) return;

    let pluginSettings = pluginsSettings[plugin];
    if (!pluginSettings || !pluginSettings.CONF) return;

    let settingsContainer = jQuery('#PLUGIN_SETTINGS_CONTAINER');
    settingsContainer.append(jQuery('<hr>'));

    Object.keys(pluginSettings.CONF).forEach(field => {
      let label = jQuery('<label></label>').addClass('control-label col-md-3').text(`${field}:`).attr('FOR', field);
      let input = jQuery('<input/>').addClass('form-control').attr('id', field).attr('name', field).val(pluginSettings.CONF[field]);
      let inputCol = jQuery('<div></div>').addClass('col-md-9').append(input);
      let formGroup = jQuery('<div></div>').addClass('form-group row').append(label).append(inputCol);

      settingsContainer.append(formGroup);
    });
    settingsContainer.append(jQuery('<hr>'));
  }

</script>
