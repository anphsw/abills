<form method='POST' action=$SELF_URL>

<input type='hidden' name='index' value=$index>

<div class='panel panel-primary form-horizontal'>
<div class='panel-heading'>_{BALANCE}_</div>
<div class='panel-body'>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{CASHBOX}_</label>
    <div class='col-md-9'>
      %CASHBOX_SELECT%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{FROM}_ _{DATE}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control tcal' name='FROM_DATE' value='%FROM_DATE%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{TO}_ _{DATE}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control tcal' name='TO_DATE' value='%TO_DATE%'>
    </div>
  </div>
</div>
<div class='panel-footer'>
  <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
</div>

</div>

</form>
<div class='col-md-4'>

    <div class='panel panel-primary'>
    <div class='panel-heading'>
        <div class='row'>
            <div class='col-xs-3'>
            <i class='glyphicon glyphicon-plus fa-5x'></i>
            </div>
            <div class='col-xs-9 text-right'>
                <div style='font-size: 40px'>%TOTAL_COMING%</div>
             </div>
        </div>
    </div>
    </div>
</div>
<div class='col-md-4'>
    <div class='panel panel-danger'>
        <div class='panel-heading'>
            <div class='row'>
            <div class='col-xs-3'>
                <i class='glyphicon glyphicon-minus fa-5x'></i>
             </div>
             <div class='col-xs-9 text-right'>
                <div style='font-size: 40px'>%TOTAL_SPENDING%</div>
             </div>
            </div>
        </div>
    </div>
</div>
<div class='col-md-4'>
    <div class='panel panel-success'>
        <div class='panel-heading'>
            <div class='row'>
                <div class='col-xs-3'>
                <i class='fa fa-calculator fa-5x'></i>
                </div>
                <div class='col-xs-9 text-right'>
                    <div style='font-size: 40px'>%BALANCE%</div>
                </div>
            </div>
        </div>
    </div>
</div>
%CHART%