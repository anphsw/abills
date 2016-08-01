<form action='$SELF_URL' METHOD='POST' class='form-inline' name=admin_form>
    <input type=hidden name='GUEST_ACCOUNT' value='1'>
    <input type=hidden name='DOMAIN_ID' value='%DOMAIN_ID%'>

    <fieldset>
        <div class='panel panel-default'>
            <div class='panel-body'>
                <div class='form-group'>
                    <label class='control-label col-md-3' for='PHONE'>_{PHONE}_</label>
                    <div class='input-group'>
                      <span class='input-group-addon' id='basic-addon1'>+%PHONE_PREFIX%</span>
                      <input type='text' id='PHONE' required='required' name='PHONE' class='form-control'/>
                    </div>
                </div>
            </div>
        </div>

    </fieldset>
</form>

