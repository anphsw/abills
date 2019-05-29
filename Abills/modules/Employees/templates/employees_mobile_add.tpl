<form action=$SELF_URL METHOD=POST class='form-horizontal'>
  <input type='hidden' name=index value=$index>
  <input type='hidden' name=ID value='%ID%'>

  <div class='box box-theme box-form'>
    <!-- head -->
    <div class='box-header with-border'>_{EMPLOYEE}_</div>
    <!-- body -->
    <div class='box-body'>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{EMPLOYEE}_</label>
        <div class='col-md-9'>
          %ADMINS%
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{CELL_PHONE}_</label>
        <div class='col-md-9'>
          %CELL_PHONE%
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{DAY}_ _{MONTHES_A}_</label>
        <div class='col-md-9'>
          %DAY_NUM%
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{SUM}_</label>
        <div class='col-md-9'>
          %MOB_SUM%
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{STATUS}_</label>
        <div class='col-md-9'>
          %MOB_STATUS%
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label' for='MOB_COMMENT'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' rows='2' name='MOB_COMMENT' id='MOB_COMMENT'>%MOB_COMMENT%</textarea>
        </div>
      </div>

    </div>
    <!-- footer -->
    <div class='box-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>

  </div>

</form>
