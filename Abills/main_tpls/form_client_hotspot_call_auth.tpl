<form action='$SELF_URL' METHOD='POST' class='form-inline' name=admin_form>
    
    <input type=hidden name='DOMAIN_ID' value='%DOMAIN_ID%'>
    <input type=hidden name='PHONE' value='%PHONE%'>
    <input type=hidden name='mac' value='%mac%'>

    <fieldset>
        <div class='box box-theme'>
            <div class='box-body'>
                Перезвоните на номер %AUTH_NUMBER%
            </div>
        </div>
        %BUTTON%

    </fieldset>

</form>
