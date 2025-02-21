<form action='%SELF_URL%' method='post'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='UID' value='%UID%'>

  <div class='card card-outline card-primary container-md'>
    <div class='card-header'>
      <h3 class='card-title'>_{MOBILE_COMMUNICATION}_</h3>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3 text-right required'>_{TARIF_PLAN}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            %TP_SEL%
            %TP_CHANGE_BTN%
          </div>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3 text-right required'>_{STATUS}_:</label>
        <div class='col-md-9'>
          %STATUS_SEL%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>

