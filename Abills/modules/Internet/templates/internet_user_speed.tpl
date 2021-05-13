<FORM action='$SELF_URL' METHOD=POST>
    <input type=hidden name=index value=$index>
    <input type=hidden name=CID value='%ISG_CID_CUR%'>
    <input type=hidden name=sid value='$sid'>

    <div class='card card-primary card-outline'>
        <div class='card-header with-border'><h4 class='card-title'>TURBO _{MODE}_</h4></div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='control-label'>_{SPEED}_ (kb):</label>
                %SPEED_SEL%
            </div>
            <div class='form-group row'>
                <input type=submit name=change value='_{ACTIVATE}_' class='btn btn-primary'>
            </div>
        </div>
    </div>
</FORM>
