<div class='text-center'>
  <form action='$SELF_URL' method='post'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=sid value='$sid'>

    <div class='panel panel-primary'>
      <div class='panel-heading text-center'>
        <h4>Изменение данных</h4>
      </div>
      %MESSAGE_CHG%
      <div class='panel-body form form-horizontal'>
        <div class='form-group %FIO_HAS_ERROR% %FIO_HIDDEN%'>
          <label class='col-md-3 required control-label'>_{FIO}_:</label>

          <div class='col-md-9'><input name='FIO' value='%FIO%' class='form-control' %FIO_DISABLE%/></div>
        </div>
        <div class='form-group %PHONE_HAS_ERROR% %PHONE_HIDDEN%'>
          <label class='col-md-3 required control-label'>_{PHONE}_:</label>

          <div class='col-md-9'><input type=text name=PHONE value='%PHONE%' class='form-control' %PHONE_DISABLE%></div>
        </div>
        <div class='form-group %ADDRESS_HIDDEN% %ADDRESS_DISABLE%'>
          <div class='col-md-1'></div>
          <div class='col-md-11'>
            %ADDRESS_SEL%
          </div>
        </div>

        <div class='form-group %EMAIL_HAS_ERROR% %EMAIL_HIDDEN%'>
          <label class='col-md-3 control-label required'>E-mail:</label>

          <div class='col-md-9'><input type=text name=EMAIL value='%EMAIL%' class='form-control' %EMAIL_DISABLE%></div>
        </div>

        %INFO_FIELDS%

      </div>

      <div class='panel-footer text-center'>
        <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary text-center'>
      </div>
    </div>
  </form>
