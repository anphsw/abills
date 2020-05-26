<form name='MAPS_POINT_TYPES_FORM' id='form_MAPS_POINT_TYPES_FORM' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='chg' value='%ID%'/>

  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h4>_{OBJECT}_ _{TYPE}_</h4></div>

    <div class='box-body'>
      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME'>_{NAME}_: </label>
        <div class='col-md-9'>
          <input type='text' disabled class='form-control' value='%NAME%' required name='NAME' id='NAME'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='ICON_SELECT'>_{ICON}_: </label>
        <div class="col-md-9">
          <div class="col-md-2" id="DIV_ICON"></div>
          <div class='col-md-8' id="DIV_SELECT">
            %ICON_SELECT%
          </div>
          <div class="col-md-2">
            %UPLOAD_BTN%
          </div>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_: </label>
        <div class='col-md-9'>
          <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='box-footer'>
      <input type='submit' class='btn btn-primary' name='change' value='_{CHANGE}_'>
    </div>
  </div>

</form>

<script>
  jQuery(document).ready(function () {
    let icon_select = jQuery('#ICON_SELECT');
    jQuery('#DIV_ICON').html('<img src="/images/maps/icons/' + icon_select.val() + '.png"/>');

    icon_select.on('change', function () {
      jQuery('#DIV_ICON').html('<img src="/images/maps/icons/' + icon_select.val() + '.png"/>');
    });

    jQuery('#ajax_upload_submit').on('click', function () {
      setTimeout(function () {
        jQuery('.modal').modal('hide');
      }, 2000);
    });
  });

  function updateIcons() {
    jQuery.get('$SELF_URL', 'get_index=_maps2_icon_filename_select&GET_SELECT=1&header=2&ICON=' + jQuery('#ICON_SELECT').val(), function (result) {
      if (result.match("<div class='input-group select'>")){
        jQuery('#DIV_SELECT').html(result);
        initChosen();
        jQuery('#ICON_SELECT').on('change', function () {
          jQuery('#DIV_ICON').html('<img src="/images/maps/icons/' + jQuery('#ICON_SELECT').val() + '.png"/>');
        });
      }
    });
  }
</script>
