<form action=$SELF_URL METHOD=POST>

    <input type='hidden' name='index' value=%INDEX%>
    <input type='hidden' name='UID' value=%UID%>

    <div class='card card-primary card-outline card-big-form'>
        <div class='card-header with-border'>
            <h4 class='card-title'>3Play</h4></div>

        <div class='card-body'>
            <div class='form-group row'>
                <label class='col-md-4 control-label'>_{TARIF_PLAN}_</label>
                <div class='col-md-8'>
                    %TP_SEL%
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-md-4 control-label'>_{STATUS}_</label>
                <div class='col-md-8'>
                    %STATUS_SEL%
                </div>
            </div>
            <br>
            %SERVICES_INFO%
            <br>
            <div class='form-group'>
                <label for='COMMENTS'>
                    <span class='col' style='line-height: 2.2em;'>_{COMMENTS}_:</span>
                    <textarea rows='5' cols='100' name='COMMENTS' class='form-control' id='COMMENTS'>%COMMENTS%</textarea>
                </label>
            </div>

        </div>

        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name='%ACTION%' id='%ACTION%' value='%ACTION_LNG%'>
        </div>

    </div>

</form>