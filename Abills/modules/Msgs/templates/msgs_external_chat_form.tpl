<form method='POST' action='%SELF_URL%' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>


  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{MSGS_EXTERNAL_CHAT}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' disabled name='NAME' id='NAME' value='%NAME%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='LOGIN'>_{USER}_:</label>
        <input type=hidden name=UID id='UID_HIDDEN' value='%UID%'/>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='text' form='unexistent' class='form-control' name='LOGIN' value='%USER_LOGIN%' id='LOGIN'
                   readonly='readonly'/>
            <div class='input-group-append'>
              %USER_SEARCH%
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 control-label' for='SUBJECT'>_{SUBJECT}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='SUBJECT' value='%SUBJECT%' id='SUBJECT' %SUBJECT_EXT_PARAMS%/>
        </div>
      </div>

      <div class='form-group row %CHAPTER_EXT_CLASS%'>
        <label class='col-md-4 control-label'>_{CHAPTER}_:</label>
        <div class='col-md-8'>
          %CHAPTERS_SEL%
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='change' value='_{CHANGE}_'>
    </div>
  </div>
</form>