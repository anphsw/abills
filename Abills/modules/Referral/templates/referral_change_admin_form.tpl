<div class='card card-primary card-outline box-form container-md'>
  <div class='card-header with-border text-center'><h5>_{ADD_FRIEND}_</h5></div>
  <form name='ADD_FRIEND' id='form_ADD_FRIEND' method='post' class='form form-horizontal'>
    <div class='card-body'>

      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>
      <input type='hidden' name='REFERRAL_UID' value='%REFERRAL_UID%'/>
      <div class='form-group row'>
        <label class='control-label col-md-4' for='FIO'>_{FIO}_</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='FIO' value='%fio%'
                 id='FIO'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4' for='PHONE'>_{PHONE}_</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='PHONE' value='%phone%'
                 id='PHONE'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4'> </label>
        <div class='col-md-8'>
          %ADDRESS_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4'>_{STATUS}_</label>
        <div class='col-md-8'>
          %STATUS_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4'>_{TARIF_PLAN}_</label>
        <div class='col-md-8'>
          %TARIF_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-md-8'>
           <textarea cols="10" style="resize: vertical" class='form-control' name='COMMENTS'
                              id='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      %ACTION%
    </div>
  </form>
</div>
