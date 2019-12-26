<form action='$SELF_URL' method='POST' class='form-horizontal' id='UREPORTS_SEARCH'>
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='search_user_ureports' value='1'>

    <div class='box box-theme box-form'>
        <div class='box-header with-border'>
            <h4 class='box-title'>_{SEARCH}_</h4>
        </div>

        <div class='box-body'>
            <div class='form-group'>
                <label class='col-md-4 col-sm-3 control-label'>_{GROUP}_:</label>
                <div class='col-md-8 col-sm-9'>%GROUP_SEL%</div>
            </div>
            <div class='form-group'>
                <label class='col-md-4 col-sm-3 control-label'>_{DESTINATION}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input type='text' name='DESTINATION' value='%DESTINATION%' class='form-control'>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-4 col-sm-3 control-label'>_{TARIF_PLAN}_ (ID):</label>
                <div class='col-md-8 col-sm-9'>
                    <input type='text' name='TP_ID' value='%TP_ID%' class='form-control'>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-4 col-sm-3 control-label'>_{PHONE}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input type='text' name='PHONE' value='%PHONE%' class='form-control'>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-4 col-sm-3 control-label'>_{STATUS}_:</label>
                <div class='col-md-8 col-sm-9'>%STATUS_SEL%</div>
            </div>
            <input class='btn btn-primary col-md-12 col-sm-12' type='submit' value='_{SEARCH}_'>
        </div>
    </div>
</form>