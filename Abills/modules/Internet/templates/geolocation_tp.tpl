<form action=$SELF_URL METHOD=POST class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='TP_GID' value='%TP_GID%'>
  <!--<input type='hidden' name='subf' value='%SUBF%'>-->

  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h4>_{GEOLOCATION_TP}_</h4></div>
    <div class="box-body">
      <div class='row'>
        <div class='col-sm-12 col-md-12'>
          %GEOLOCATION_TREE%
        </div>
      </div>
      <div class='checkbox'>
        <label>
          <input type='checkbox' name='CLEAR' value=1> _{CLEAR_GEO}_
        </label>
      </div>
    </div>
    <div class="box-footer">
      <input type='submit' class='btn btn-primary' name='BUTTON' value='%BTN_NAME%'>
    </div>
  </div>
</form>
<script>
  jQuery(document).ready(function () {
    jQuery('.tree_box').each(function () {
      if (jQuery(this).prop('checked')) {
        jQuery(this).parent().addClass('text-success');
        jQuery(this).closest('li').find('ul').find('input').each(function () {
          jQuery(this).prop('checked', true);
          jQuery(this).prop('disabled', true);
          jQuery(this).parent().addClass('text-success');
      })
      }
    });
    jQuery('.tree_box').change(function () {
      var a = jQuery(this).prop('checked');
      if (a) {
        jQuery(this).parent().addClass('text-success');
      }
      else {
        jQuery(this).parent().removeClass('text-success');
      }
        jQuery(this).closest('li').find('ul').find('input').each(function () {
          if (a) {
          jQuery(this).prop('checked', true);
          jQuery(this).prop('disabled', true);
          jQuery(this).parent().addClass('text-success');
          }
          else{
            jQuery(this).prop('checked', false);
            jQuery(this).prop('disabled', false);
            jQuery(this).parent().removeClass('text-success');
          }
        });
    });
  });
</script>