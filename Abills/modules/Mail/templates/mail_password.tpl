<script>
  jQuery(function () {
    var gen_btn = jQuery('#generate_btn');
    var cp_btn = jQuery('#copy_btn');

    gen_btn.on('click', function () {
      suggestPassword('%PW_CHARS%', '%PW_LENGTH%');
    });

    cp_btn.on('click', function () {
      suggestPasswordCopy(this.form)
    });

  });
</script>

<div class='form-group'>
  <label class='control-label col-md-5' for='text_pma_pw'>_{PASSWD}_</label>
  <div class='col-md-6'>
    <input type='password' class='form-control pass-field' id='text_pma_pw' name='newpassword' title='_{PASSWD}_'/>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-5' for='text_pma_pw2'>_{CONFIRM_PASSWD}_</label>
  <div class='col-md-6'>
    <input type='password' class='form-control pass-field' name='confirm' id='text_pma_pw2' title='_{CONFIRM}_'/>
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-5' for='text_pma_pw2'>
  <input type='button' id='generate_btn' class='btn btn-info btn-xs' value='_{GENERED_PARRWORD}_'>
  <input type='button' id='copy_btn' class='btn btn-info btn-xs' value='Copy'>

  </label>
  <div class='col-md-6'>
    <input type='text' class='form-control' name='generated_pw' id='generated_pw' />
  </div>
</div>

