<div class='panel panel-primary panel-form'>
    <div class='panel-heading text-center'><h4>_{EVENT}_ _{STATE}_</h4></div>
    <div class='panel-body'>

        <form name='EVENTS_STATE_FORM' id='form_EVENTS_STATE_FORM' method='post' class='form form-horizontal'>
            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='%CHANGE_ID%' value='%ID%'/>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='STATE_NAME_id'>_{STATE}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' required name='NAME' value='%NAME%' id='STATE_NAME_id'
                           placeholder='_{STATE}_'/>
                </div>
            </div>
        </form>

    </div>
    <div class='panel-footer text-center'>
        <input type='submit' form='form_EVENTS_STATE_FORM' class='btn btn-primary' name='%SUBMIT_BTN_ACTION%'
               value='%SUBMIT_BTN_NAME%'>
    </div>
</div>

