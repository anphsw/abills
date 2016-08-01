<style>
#paysys-chooser img{
  cursor:pointer;
}
</style>

<form method='POST' action='$SELF_URL' class='form form-horizontal'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='sid' value='$sid'>

<input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>

<div class='panel panel-primary'>

    <div class='panel-heading text-center'>_{BALANCE_RECHARCHE}_</div>
<div class='panel-body'>

<div class='form-group'>
    <label class='col-md-3 control-label'>_{TRANSACTION}_ #:</label>
    <label class='col-md-3 control-label'>%OPERATION_ID%</label>
</div>

<div class='form-group'>
    <label class='col-md-3 control-label required'>_{SUM}_:</label>
    <div class='col-md-9'><input class='form-control' type='text' name='SUM' value='$FORM{SUM}'></div>
</div>

<div class='form-group'>
    <label class='col-md-3 control-label'>_{DESCRIBE}_:</label>
    <div class='col-md-9'><input class='form-control' type='text' name='DESCRIBE' value='Пополнение счёта'></div>
</div>
<div class='form-group'>
    <label class='col-md-12 bg-primary text-center'>_{CHOOSE}_</label>
    %PAY_SYSTEM_SEL%
</div>
</div>

    <div class='panel-footer text-center'><input class='btn btn-primary' type='submit' name=pre value='_{NEXT}_'></div>
</div>


</form>


%MAP%
