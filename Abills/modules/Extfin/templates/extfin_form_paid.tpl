<form action='$SELF_URL' METHOD='POST'>
    <input type=hidden name='index' value='$index'>
    <input type=hidden name='OP_SID' value='%OP_SID%'>
    <input type=hidden name='UID' value='$FORM{UID}'>
    <input type=hidden name='ID' value='$FORM{chg}'>

    <div class='panel panel-primary panel-form form-horizontal'>
        <div class='panel-heading'>_{FEES}_</div>
        <div class='panel-body'>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{SUM}_:</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name='SUM' value='%SUM%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{DESCRIBE}_:</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=DESCRIBE value='%DESCRIBE%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{TYPE}_:</label>
                <div class='col-md-9'>
                    %TYPE_SEL%
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{ACCOUNT}_:</label>
                <div class='col-md-9'>
                    %MACCOUNT_SEL%
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{DATE}_:</label>
                <div class='col-md-9'>
                    %DATE_LIST%
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{CLOSED}_:</label>
                <div class='col-md-9'>
                    <input type=checkbox name=STATUS value=1 %STATUS%>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>EXT ID:</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=EXT_ID value='%EXT_ID%'>
                </div>
            </div>
        </div>
        <div class='panel-footer'>
            <input type=submit name=%ACTION% value='%ACTION_LNG%' class='btn btn-primary'>
        </div>
    </div>
</form>
