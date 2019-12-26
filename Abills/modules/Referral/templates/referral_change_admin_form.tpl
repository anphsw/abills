<div class='box box-theme box-form'>
  <div class='box-header with-border text-center'><h5>_{ADD_FRIEND}_</h5></div>
  <form name='ADD_FRIEND' id='form_ADD_FRIEND' method='post' class='form form-horizontal'>
    <div class='box-body'>

      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>
      <input type='hidden' name='REFERRAL_UID' value='%REFERRAL_UID%'/>
      <div class='form-group'>
        <label class='control-label col-md-3' for='FIO'>_{FIO}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='FIO' value='%fio%'
                 id='FIO'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PHONE'>_{PHONE}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='PHONE' value='%phone%'
                 id='PHONE'/>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3' for='ADDRESS'>_{ADDRESS}_</label>
        <div class='col-md-9'>
          <textarea cols="10" style="resize: vertical" class='form-control' name='ADDRESS'
                 id='ADDRESS'>%address%</textarea>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='ADDRESS'>_{STATUS}_</label>
        <div class='col-md-9'>
          %STATUS_SELECT%
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3' for='ADDRESS'>_{TARIF_PLAN}_</label>
        <div class='col-md-9'>
          %TARIF_SELECT%
        </div>
      </div>
    </div>
    <div class='box-footer'>
      %ACTION%
    </div>
  </form>
</div>

