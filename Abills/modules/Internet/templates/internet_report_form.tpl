<form name='report_panel' id='report_panel' method='get' class='form-inline'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'/>

    <div class='navbar navbar-expand-lg'>
        <div class='container-fluid'>
            <label class='control-label' for='FILTER'>_{FILTERS}_: </label>
            <input type='text' name='FILTER' value='%FILTER%' class='form-control' id='FILTER'>

            <label class='control-label' for='FILTER_FIELD'>_{FIELDS}_: </label>
            %FIELDS_SEL%

            <label class='control-label' for='REFRESH'>_{REFRESH}_ (sec): </label>
            <input type='text' name='REFRESH' value='0' size='4' class='form-control' id='REFRESH'>

            <input type='SUBMIT' name='SHOW' value='_{SHOW}_' class='btn btn-primary' id='SHOW'>
        </div>

    </div>
</form>