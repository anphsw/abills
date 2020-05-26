<form METHOD=POST class='form-horizontal' >
  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='chg' value='%CHG_ELEMENT%'>

  <div class='box box-theme box-form'>
    <div class='box-header with-border'>
      <h4 class='box-title'>
        _{TICKET_BRIGADE}_
      </h4>
    </div>
    <div class="box-body">
      <div class="form-group">
        <label class="control-label col-md-4 col-sm-3">_{BRIGADE}_:</label>
        <div class="col-md-8 col-sm-9">
          %TEAM%
        </div>
      </div>
      <div class="form-group">
        <div class="col-md-12 col-sm-12">
          %ADDRESS%
        </div>
      </div>
      <div class='col-md-12 col-sm-12'>
        <input type="submit" class="btn btn-primary col-md-12 col-sm-12" name="%PARAM%" value="%SAVE_CHG%">
      </div>
    </div>
  </div>
</form>