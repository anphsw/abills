<form method='POST' action='%SELF_URL%' class='form-horizontal'>
    <input type='hidden' name='index' value='%index%'>
    <input type='hidden' name='chg' value='%chg%'>
    <input type='hidden' name='ID' value='%ID%'>
    <input type='hidden' name='UID' value='%UID%'>
    <div class='card card-primary card-outline'>
        <div class='card-header with-border'><h4>_{ADD}_ _{DEVICE}_</h4></div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='control-label col-md-3 required' for='UNIQ'>UNIQ: </label>
                <div class='col-md-9'>
                    <input required='' type='text' class='form-control' id='UNIQ' name='UNIQ' value='%UNIQ%'/>
                </div>
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name='customer_add_device' value='_{ADD}_'>
        </div>
    </div>
</form>