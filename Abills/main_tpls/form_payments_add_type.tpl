<form action=$SELF_URL METHOD=POST class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' id='DEFAULT_UNCLICK' name='DEFAULT_UNCLICK' value=''/>

  <div class='box box-theme box-form'>
    <div class='box-header with-border'>
      <div class='box-title'>
        %BUTTON_NAME%
      </div>
    </div>

    <div class='box-body'>
      <div class='form-group'>
        <label class='control-label col-md-3' for='NEW_ID'>ID:</label>
        <div class='col-md-9'>
          <input %ALLOW_SET_ID% class='form-control' id='NEW_ID' name='NEW_ID' value='%ID%' type='text'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
        <div class='col-md-9'>
          <input class='form-control' id='NAME' required name='NAME' value='%NAME%' type='text'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COLOR'>_{COLOR}_</label>
        <div class='col-md-9'>
          <input class='form-control' ID='COLOR' name='COLOR' value='%COLOR%' type='color'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='DEFAULT_PAYMENT'>_{DEFAULT}_</label>
        <div class='col-md-9'>
          <input
            type='checkbox'
            name='DEFAULT_PAYMENT'
            id='DEFAULT_PAYMENT'
            value='1'
            %CHECK_DEFAULT%
            data-tooltip='%ADMIN_PAY%'
          >
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='FEES_TYPE'>_{FEES}_:</label>
        <div class='col-md-9'>
            %FEES_TYPE%
        </div>
      </div>
    </div>

    <div class='box-footer'>
        <input class='btn btn-primary pull-center' name='%BUTTON_LABALE%' value='%BUTTON_NAME%' type='submit'>
    </div>
  </div>

</form>

<script>
  jQuery(function() {
    jQuery('#DEFAULT_PAYMENT').change(function() {
        if(this.checked) {
          jQuery('#DEFAULT_UNCLICK').val('')
        } else {
          jQuery('#DEFAULT_UNCLICK').val('1')
        }
    });
  });
</script>