<form action='%SELF_URL%' name='ADD_FRIEND' id='form_ADD_FRIEND' method='post' class='form-horizontal'>
  <div class='card card-form card-primary card-outline'>
    <div class='card-body'>
      <input type='hidden' name='index' value='%index%'/>
      <input type='hidden' name='REFERRER' value='%REFERRER%'/>
      <input type='hidden' name='module' value='Referral'>

      <div class='form-group row'>
        <label class='control-label col-md-3 col-sm-3 required' for='FIO'>_{FIO}_</label>
        <div class='col-sm-9 col-md-9'>
          <input type='text' required class='form-control' name='FIO' value='%FIO%' id='FIO'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3 col-sm-3 required' for='PHONE'>_{PHONE}_</label>
        <div class='col-sm-9 col-md-9'>
          <input type='text' required class='form-control' name='PHONE' value='%PHONE%' id='PHONE'/>
        </div>
      </div>

      %ADDRESS_SEL%

      <div class='form-group row'>
        <label class='control-label col-md-3 col-sm-3' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-sm-9 col-md-9'>
          <textarea cols="10" style="resize: vertical" class='form-control' name='COMMENTS' id='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>

      %CAPTCHA%

    </div>
    <div class='card-footer'>
      <input type='submit' name='add' value='_{REGISTRATION}_' class='btn btn-primary'>
    </div>
  </div>
</form>





