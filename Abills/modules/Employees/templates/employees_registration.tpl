<script type='text/javascript'>
    function selectLanguage() {
        var sLanguage = jQuery('#language').val() || '';
        var sLocation = '$SELF_URL?DOMAIN_ID=$FORM{DOMAIN_ID}&language=' + sLanguage;
        location.replace(sLocation);
    }

    function set_referrer() {
        document.getElementById('REFERER').value = location.href;
    }
</script>

<form action=$SELF_URL METHOD=POST class='form-horizontal'>
    <input type='hidden' name='module' value='Employees'>
    <div class='box box-theme box-form'>
        <!-- head -->
        <div class='box-header with-border'><h4 class='box-title'>_{EMPLOYEE_PROFILE}_</h4></div>
        <!-- body -->
        <div class='box-body'>

            <div class='form-group'>
                <label class='col-md-4 col-sm-3 control-element'>_{FIO}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input required type='text' class='form-control' name='FIO' placeholder="_{FIO}_" value='%FIO%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-4 col-sm-3 control-element'>_{BIRTHDAY}_:</label>
                <div class='col-md-8 col-sm-3'>
                    %DATE%
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-4 col-sm-3 control-element'>_{PHONE}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input required type='text' class='form-control' name='PHONE' placeholder="_{PHONE}_" value='%PHONE%'>
                </div>
            </div>

            <div class='form-group center-block'>
                <label class='col-md-4 col-sm-3 control-element'>_{MAIL_BOX}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input required type='email' class='form-control' placeholder="_{MAIL_BOX}_" name='MAIL' value='%MAIL%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-4 col-sm-3 control-element'>_{POSITION}_:</label>
                <div class='col-md-8 col-sm-9'>
                    %POSITIONS%
                </div>
            </div>


        </div>
        <!-- footer -->
        <div class='box-footer text-right'>
            <input type='submit' class='btn btn-primary' name='NEXT_BUTTON'
                   value='_{NEXT}_'>
        </div>
</form>
