</form>

<div id='s%ID%' class='tab-pane fade %ACTIVE%'>
  <form action='$SELF_URL' method='POST' id='FORM%ID%'>
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='LEAD_ID' value='%LEAD_ID%'>
    <input type='hidden' name='STEP_ID' value='%ID%'>
    <div class='timeline'>

      %TIMELINE_ITEMS%

    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='ADMIN'>_{ADMIN}_:</label>
      <div class='col-md-8'>
        %ADMIN_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='ACTION'>_{ACTION}_:</label>
      <div class='col-md-8'>
        %ACTION_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='PLANNED_DATE-%ID%'>_{PLANNED}_ _{DATE}_:</label>
      <div class='col-md-8'>
        <input type='text' id='PLANNED_DATE-%ID%' name='PLANNED_DATE' value='%DATE%' placeholder='%DATE%'
               class='form-control datepicker with-time'>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='MESSAGE-%ID%'>_{MESSAGE}_:</label>
      <div class='col-md-8'>
        <textarea id='MESSAGE-%ID%' class='form-control custom-control' rows='3' style='resize:none'
                  name='MESSAGE'></textarea>
      </div>
    </div>

    <div class='form-group row'>
      <input form='FORM%ID%' type='submit' class='btn btn-primary custom-send' name='add_message' value='_{SEND}_'>
    </div>
  </form>
</div>
