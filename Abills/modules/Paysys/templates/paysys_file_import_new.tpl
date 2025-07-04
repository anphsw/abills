<div class='card card-primary card-outline'>
  <div class='card-header with-border'>
    <h5 class='card-title'>_{IMPORT}_</h5>
  </div>
  <div class='card-body'>

    <form class='form' name='paysys_upload_form' id='paysys_upload_form' method='post' enctype='multipart/form-data'>

      <input type='hidden' name='index' value='%index%'>
      <input type='hidden' name='import_file' value='1'/>
      <input type='hidden' name='add' value='1'/>
      <input type='hidden' name='SYSTEM_ID' value='%SYSTEM_ID%'/>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='UPLOAD_FILE'>_{FILE}_:</label>
        <div class='col-md-8'>
          <input type='file' accept='.csv,.CVS' name='UPLOAD_FILE' id='UPLOAD_FILE' class='control-element' required/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='UPLOAD_FILE'>_{DATE}_ Виписки:</label>
        <div class='col-md-8'>
          %DATE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 text-right' for='SAVE_FILE'>_{SAVE}_ _{FILE}_:</label>
        <div class='col-md-9'>
          <div class='form-check text-left'>
            <input class='form-check-input' type='checkbox' id='SAVE_FILE' name='SAVE_FILE' value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 text-right' for='REWRITE'>_{NAME}_ _{DEFAULT}_:</label>
        <div class='col-md-9'>
          <div class='form-check text-left'>
            <input class='form-check-input' type='checkbox' id='REWRITE' name='REWRITE' value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 text-right' for='REWRITE'>_{REWRITE}_:</label>
        <div class='col-md-9'>
          <div class='form-check text-left'>
            <input class='form-check-input' type='checkbox' id='REWRITE' name='REWRITE' value='1'>
          </div>
        </div>
      </div>

    </form>
  </div>

  <div class='card-footer'>
    <button type='submit' class='btn btn-primary' id='paysys_upload' form='paysys_upload_form'>_{IMPORT}_</button>
  </div>
</div>
