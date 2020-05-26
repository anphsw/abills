<form method='POST' class='form-horizontal' name='CRM_LEADS' id='CRM_LEADS'>
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='send' value='1'>

    <div class='box box-theme box-form'>
        <div class='box-header with-border'>
            <h4 class='box-title'>_{DELIVERY}_</h4>
        </div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3'>_{SUBJECT}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input type='text' class='form-control' placeholder='_{SUBJECT}_' name='SUBJECT' id='SUBJECT'
                           value='%SUBJECT%'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3'>_{MESSAGE}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <textarea name='MSGS' id='MSGS' rows='6' cols='45;' class='form-control'>%MSGS%</textarea>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3'>_{TYPE}_:</label>
                <div class='col-md-8 col-sm-9'>
                    %TYPE_SEND%
                </div>
            </div>
            <div class='box-footer'>
                <input type='submit' name='show' value='_{SEND}_' class='btn btn-primary pull-left'>
            </div>
        </div>
    </div>
    %TABLE%
</form>