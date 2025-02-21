<form class='form form-horizontal hidden-print form-main' action='%SELF_URL%' METHOD='POST' enctype='multipart/form-data'>
  <input type='hidden' name='index' value='$index'>

  <div class='card card-primary card-outline col-md-6 container'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{IMPORT}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='FILE_DATA'>_{FILE}_:</label>
        <div class='col-md-9'>
          <input required id='FILE_DATA' name='FILE_DATA' value='%FILE_DATA%' placeholder='%FILE_DATA%' type='file'
                 class='input-file'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='IMPORT_TYPE'>_{FROM}_:</label>
        <div class='input-group col-md-9'>
          %IMPORT_TYPE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='DATE'>_{DATE}_:</label>
        <div class='input-group col-md-9'>
          <input id='DATE' name='DATE' value='%DATE%' placeholder='%DATE%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='PAYMENT_METHOD'>_{PAYMENT_METHOD}_:</label>
        <div class='input-group col-md-9'>
          %METHOD%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='ENCODE'>_{ENCODE}_:</label>
        <div class='input-group col-md-9'>
          %ENCODE_SEL%
        </div>
      </div>

      %FORM_ER%

      <div class='form-group row'>
        <label class='col-md-3 text-right' for='STATUS'>_{DEBUG}_:</label>
        <div class='col-md-9'>
          <div class='form-check text-left'>
            <input class='form-check-input' type='checkbox' id='DEBUG' name='DEBUG' %DEBUG% value='1'>
          </div>
        </div>
      </div>

      <input type='submit' name='IMPORT' value='_{IMPORT}_' class='btn btn-primary btn-primary'>
    </div>
  </div>
</form>
