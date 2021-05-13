<form action='$SELF_URL' class='form form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=ID value=$FORM{chg}>
    <input type=hidden name=TP_ID value=$FORM{TP_ID}>


    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'>_{TARIF_PLAN}_</div>
        <div class='card-body'>
            <div class='form-group'>
                <label class='control-label col-md-3'>_{TARIF_PLAN}_:</label>
                <div class='col-md-9'>
                    $FORM{TP_ID}
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{NAME}_:</label>
                <div class='col-md-9'>
                    <input type=text name='NAME' class='form-control' value='%NAME%'>
                </div>
            </div>

            <div class='checkbox'>
                <label>
                    <input type=checkbox name='STATE' value='1' %STATE%><strong>_{ACTIVE}_</strong>
                </label>
            </div>

            <hr/>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{COMMENTS}_</label>
                <div class='col-md-9'>
                    <textarea name='COMMENTS' class='form-control' rows='5'>%COMMENTS%</textarea>
                </div>
            </div>
        </div>
        <div class='card-footer'>
            <input class='btn btn-primary' type=submit name=%ACTION% value='%LNG_ACTION%'>
        </div>
    </div>

</form>
