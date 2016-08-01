<div class='noprint'>
    <form action=$SELF_URL method=post>
        <input type=hidden name=index value=$index>
        <input type=hidden name=UID value='$FORM{UID}'>
        <input type=hidden name=sid value='$sid'>

        <div class='panel panel-primary'>
            <div class='panel-heading'>
                _{BONUS}_ _{BALANCE_RECHARCHE}_
            </div>
            <div class='panel-body form form-horizontal'>
                <div class='form-group'>
                    <label class='control-label col-md-3'>_{SUM}_:</label>

                    <div class='col-md-9'>
                        <input class='form-control' type=text name=COST value=%COST%>
                    </div>
                </div>
            </div>
            <div class='panel-footer'>
                <input class='btn btn-primary' type=submit name=transfer value='_{BALANCE_RECHARCHE}_'>
            </div>
        </div>
    </form>
</div>
