<form class='form-inline' name='report_panel' id='report_panel' method='get'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'/>

  <div class='container-fluid row justify-content-md-center pb-3 pt-3'>
    <div class='form-group row' style='margin: 0 5px;'>
      <label class='control-label' for='FILTER'>_{FILTERS}_: </label>
      <input type='text' name='FILTER' value='%FILTER%' class='form-control' id='FILTER'>
    </div>

    <div class='form-group col-md-3 row' style='margin: 0 5px;'>
      <label class='col-md-3 control-label' for='FILTER_FIELD'>_{FIELDS}_: </label>
      <div class='col-md-9'>
        %FIELDS_SEL%
      </div>
    </div>

    <div class='form-group row' style='margin: 0 5px;'>
      <label class='control-label' for='REFRESH'>_{REFRESH}_ (sec): </label>
      <input type='text' name='REFRESH' value='%REFRESH%' size='4' class='form-control' id='REFRESH'>
      <input type='SUBMIT' name='SHOW' value='_{SHOW}_' class='btn btn-primary' id='SHOW'>
    </div>

  </div>
</form>