<form name='PAYSYS_GROUP_SETTINGS' id='form_PAYSYS_GROUP_SETTINGS' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='SYSTEM_ID' id='SYSTEM_ID' value='%SYSTEM_ID%'>
  <input type='hidden' name='MERCHANT_ID' id='MERCHANT_ID' value='%MERCHANT_ID%'>

  <div class='card big-box card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class="card-title">_{ADD}_ _{_MERCHANT}_</h4>
    </div>

    <div class='card-body'>

      <div class='form-group %HIDE_SELECT%'>
        <label class=' col-md-12 col-sm-12'>_{PAY_SYSTEM}_</label>
        <div class='col-md-12 col-sm-12'>
          %PAYSYS_SELECT%
        </div>
      </div>

      <div id='paysys_connect_system_body'></div>

      <div class='form-group'>
        <label class=' col-sm-12 col-md-12'>_{MERCHANT_NAME2}_:</label>
        <div class='col-sm-12 col-md-12'>
          <input type='text' class='form-control' name='MERCHANT_NAME' value='%MERCHANT_NAME%' required>
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>

<script>
  try {
    var arr = JSON.parse('%JSON_LIST%');
  }
  catch (err) {
    console.log('JSON parse error.');
  }

  function rebuild_form(type) {
    jQuery('.appended_field').remove();
    var keys = Object.keys(arr[type]['CONF']);
    var sorted = keys.sort();
    var systemID = arr[type]['SYSTEM_ID'];
    jQuery('#SYSTEM_ID').attr('value', systemID);

    for (var i = 0; i < sorted.length; i++) {
      var val = arr[type]['CONF'][sorted[i]];
      var param = sorted[i];
      param = param.replace(/(_NAME_)/,'_'+ type.toUpperCase()+'_');

     jQuery("input[name*='MFO']").attr("maxlength", "6");

     jQuery("input[name*='MFO']").attr("title", "Поле должно содержать 6 цифр");

     jQuery("input[name*='MFO']").hover(function(){
         jQuery(this).tooltip()
     });

    // jQuery("input[name*='ACCOUNT_KEY']");

      var element = jQuery("<div></div>").addClass("form-group appended_field");
      element.append(jQuery("<label for=''></label>").text(param).addClass("col-md-12 col-sm-12 "));
      element.append(jQuery("<div></div>").addClass("col-md-12 col-sm-12").append(
        jQuery("<input name='" + param + "' id='" + param + "' value='" + (val || '') + "'>").addClass("form-control")));

      jQuery('#paysys_connect_system_body').append(element);
    }
  }

  jQuery(function () {
    if (jQuery('#MODULE').val()) {
      rebuild_form(jQuery('#MODULE').val());
    }

    jQuery("#MODULE").change(function () {
      rebuild_form(jQuery('#MODULE').val());

    });
  });
</script>