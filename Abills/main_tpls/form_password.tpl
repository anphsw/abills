<script>
  jQuery(function () {
    var gen_btn = jQuery('#generate_btn');
    var cp_btn  = jQuery('#copy_btn');

    gen_btn.on('click', function () {
      suggestPassword('%PW_CHARS%', '%PW_LENGTH%');
    });

    cp_btn.on('click', function () {
      suggestPasswordCopy(this.form)
    });
  });
</script>

<form action='$SELF_URL' METHOD='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  %HIDDDEN_INPUT%
  <div class='panel panel-default panel-form'>
    <div class='panel-heading text-center'><h4>_{PASSWD}_</h4></div>
    <div class='panel-body'>

      <div class='form-group'>
        <label class='control-label col-md-4' for='text_pma_pw'>_{PASSWD}_</label>

        <div class='col-md-8'>
          <input type='password' class='form-control' id='text_pma_pw' name='newpassword' title='_{PASSWD}_'
                 onchange="pred_password.value = 'userdefined';"/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-4' for='text_pma_pw2'>_{CONFIRM_PASSWD}_</label>

        <div class='col-md-8'>
          <input type='password' class='form-control' name='confirm' id='text_pma_pw2' title='_{CONFIRM}_'
                 onchange="pred_password.value = 'userdefined';"/>
        </div>
      </div>


      <div class='form-group'>
        <label class='control-label col-md-6' for='text_pma_pw2'>
          <input type='button' id='generate_btn' class='btn btn-info btn-xs' value='_{GENERED_PARRWORD}_'>
          <input type='button' id='copy_btn' class='btn btn-info btn-xs' value='Copy'>

        </label>

        <div class='col-md-6'>
          <input type='text' class='form-control' name='generated_pw' id='generated_pw'/>
        </div>
      </div>

      <div class='form-group' style='display: %RESET_INPUT_VISIBLE% none'>
        <label class='control-label col-md-5'>_{RESET}_</label>
        <div class='col-md-7'>
          <input type='checkbox' name='RESET' class='control-element' style='margin-top: 7px;'/>
        </div>
      </div>
    </div>
    <div class='panel-footer text-center'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>

<link rel='stylesheet' href='/styles/default_adm/css/client_social_icons.css'>
<div class='row col-md-offset-2'>
  <ul class='social-network social-circle'>
    %SOCIAL_AUTH_BLOCK%
  </ul>
</div>

%EXTRA_FORM%
