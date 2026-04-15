<form method='POST' action='%SELF_URL%' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='chg' value='%chg%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='UID' value='%UID%'>
  <input type='hidden' name='chg_device_info' value='%chg_device_info%' id='chg_device_info'>
  <div class='card card-primary card-outline card-form'>
    <div class='card-header text-center'>
      <h3 class='card-title'>_{DEVICE}_</h3>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='UNIQ'>UNIQ: </label>
        <div class='col-md-9'>
          <input required='' type='text' class='form-control' id='UNIQ' name='UNIQ' value='%UNIQ%'/>
        </div>
      </div>

      <div class='form-group row d-none'>
        <label class='control-label col-md-3 required' for='COMMENTS'>_{COMMENTS}_: </label>
        <div class='col-md-9'>
          <textarea id='COMMENTS' name='COMMENTS' cols='50' rows='4' class='form-control' placeholder='_{COMMENTS}_'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='customer_add_device' value='_{ADD}_'>
    </div>
  </div>
</form>

<script>
  jQuery(document).ready(function () {
    let changeDevice = jQuery('#chg_device_info').val();
    if (!changeDevice) return;

    jQuery(`[name='customer_add_device']`).val('_{CHANGE}_').attr('name', 'change_device');
    jQuery('#UNIQ').attr('readonly', 'readonly');
    jQuery('#COMMENTS').parent().parent().removeClass('d-none');
  });
</script>