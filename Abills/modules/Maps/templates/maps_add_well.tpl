<form action=$SELF_URL name=well_add_form class='form form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=COORDX value=%COORDX%>
    <input type=hidden name=COORDY value=%COORDY%>

    <div class='panel panel-primary'>
        <div class='panel-header'>
            <h4>_{ADD_WELL}_</h4>
        </div>
        <div class='panel-body'>
            <div class='form-group'>
                <label class='control-label col-md-3' for='wellName'>_{NAME}_:</label>

                <div class='col-md-9'>
                    <input class='form-control' type=text name=NAME id='wellName' maxlength="33">
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3' for='wellDescribe'>_{DESCRIBE}_:</label>

                <div class='col-md-9'>
                    <textarea class='form-control' name=COMMENT id='wellDescribe' cols=30 rows=5></textarea>
                </div>
            </div>
        </div>
        <div class='panel-footer'>
            <input type=submit name=add_well value=_{ADD}_ class='btn btn-primary'>
        </div>
    </div>
</form>
