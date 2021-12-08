<form action=$SELF_URL METHOD=POST>
    <input type='hidden' name='index' value=%INDEX%>
    <input type='hidden' name='chg' value=$FORM{chg}>

    <div class='card card-primary card-outline card-form'>
        <h4 class='card-title'>_{TARIF_PLAN}_</h4>

        <div class='card-body'>
            <div class='form-group row'>
                <label class='col-md-3 control-label' for='NAME'>_{NAME}_</label>
                <div class='col-md-9'>
                    <input type='text' required class='form-control' id='NAME' NAME='NAME' VALUE='%NAME%'>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-md-3 control-label' for='MONTH_FEE'>_{MONTH_FEE}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' id='MONTH_FEE' NAME='MONTH_FEE' VALUE='%MONTH_FEE%'>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-md-3 control-label'>Internet</label>
                <div class='col-md-9'>
                    %INTERNET%
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-3 control-label'>IPTV</label>
                <div class='col-md-9'>
                    %IPTV%
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-3 control-label'>VOIP</label>
                <div class='col-md-9'>
                    %VOIP%
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-3 control-label' for='COMMENT'>_{COMMENTS}_</label>
                <div class='col-md-9'>
                    <textarea class='form-control' placeholder='_{COMMENTS}_' name='COMMENT'
                              id='COMMENT'>%COMMENT%</textarea>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-md-3 control-label' for='PERIOD_ALIGNMENT'>_{MONTH_ALIGNMENT}_:</label>
                <div class='col-md-9'>
                    <div class='form-check text-left'>
                        <input type='checkbox' class='form-check-input' id='PERIOD_ALIGNMENT' name='PERIOD_ALIGNMENT'
                               %PERIOD_ALIGNMENT% value='1'>
                    </div>
                </div>
            </div>

        </div>

        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'>
        </div>

    </div>
</form>