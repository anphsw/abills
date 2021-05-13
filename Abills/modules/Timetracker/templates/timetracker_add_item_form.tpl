<div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'><h4 class='card-title'>%TITLE%</h4></div>
    <div class='card-body'>
        <form name='%FORM_NAME%' id='form_%FORM_NAME%' method='GET' class='form form-horizontal'>
            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='ID' value='%ID%'/>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='ELEMENT_ID'>_{ELEMENT}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' required name='ELEMENT' id='ELEMENT_ID' value='%ELEMENT%'/>
                </div>
            </div>
            <div class='checkbox text-center'>
                <label>
                    <input type='checkbox' name='PRIORITY' value='1' id='checkbox_priority' value='%PRIORITY%'/>
                    <strong>_{FOCUS_FACTOR}_</strong>
                </label>
            </div>
        </form>
    </div>
    <div class='card-footer'>
        <input type='submit' form='form_%FORM_NAME%' class='btn btn-primary' name='%ACTION%' value="%BTN%">
    </div>
</div>