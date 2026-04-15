
<FORM ID='period_panel'  class='card-body form-main' role='form'  name='period_panel'  action='%SELF_URL%' METHOD='POST'>
    <input type='hidden' name='NAS_ID' value='%NAS_ID%' form='period_panel'>
    <input type='hidden' name='PON_TYPE' value='%PON_TYPE%' form='period_panel'>
    <input type='hidden' name='info_pon_onu' value='%INFO_PON_ONU%' form='period_panel'>
    <input type='hidden' name='index' value='%index%' form='period_panel'>
    <input type='hidden' name='ONU' value='%ONU%' form='period_panel'>
    <input type='hidden' name='visual' value='4' form='period_panel'>

    <div class='card card-primary card-outline card-form'>
        <div class='card-body'>
            <div class='row form-inline flex'>
            %DATE_RANGE% <input type='submit' name='show' value='_{SHOW}_' class='btn btn-primary'  FORM='period_panel' ID='show'/>
            </div>
        </div>
    </div>
</form>

<div class='row'>
%GRAPHS%
</div>
