<script type='text/javascript'>
    function selectLanguage() {
        var sLanguage = '';
        if(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
            sLanguage = jQuery('#language_mobile').val() || '';
        } else {
            sLanguage = jQuery('#language').val() || '';
        }
        var sLocation = '$SELF_URL?DOMAIN_ID=$FORM{DOMAIN_ID}&language=' + sLanguage;
        location.replace(sLocation);
    }
    function set_referrer() {
        document.getElementById('REFERER').value = location.href;
    }
</script>

<FORM action='$SELF_URL' METHOD=POST ID='REGISTRATION' class='form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=DOMAIN_ID value=$FORM{DOMAIN_ID}>
    <input type=hidden name=module value=Msgs>


    <div class='box box-theme box-form center-block'>
        <div class='box-header with-border '>
            <h4 class='box-title'>_{REGISTRATION}_</h4>
        </div>
        <div class='box-body'>

            <div class='form-group'>
                <label class='control-label required col-md-4 col-sm-3' for='LOGIN'>_{LOGIN}_:</label>
                <div class='col-md-8 col-sm-9'>
                        <input id='LOGIN' name='LOGIN' value='%LOGIN%' required='required' title='_{SYMBOLS_REG}_a-Z 0-9' placeholder='_{LOGIN}_'
                           class='form-control'
                           type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label required col-md-4 col-sm-3' for='FIO'>_{FIO}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input id='FIO' name='FIO' value='%FIO%' required='required' placeholder='_{FIO}_'
                           class='form-control'
                           type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label required col-md-4 col-sm-3' for='PHONE'>_{PHONE}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input id='PHONE' name='PHONE' value='%PHONE%' required='required' placeholder='_{PHONE}_'
                           class='form-control'
                           type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3' for='EMAIL'>E-MAIL:</label>
                <div class='col-md-8 col-sm-9'>
                    <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='E-mail' class='form-control'
                           type='text'>
                </div>
            </div>

            <hr/>
            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3' for='CITY'>_{CITY}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input id='CITY' name='CITY' value='%CITY%' placeholder='_{CITY}_' class='form-control' type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3' for='ZIP'>_{ZIP}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input id='ZIP' name='ZIP' value='%ZIP%' placeholder='_{ZIP}_' class='form-control' type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3' for='ADDRESS_STREET'>_{ADDRESS_STREET}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input id='ADDRESS_STREET' name='ADDRESS_STREET' value='%ADDRESS_STREET%'
                           placeholder='_{ADDRESS_STREET}_' class='form-control' type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-4' for='ADDRESS_BUILD'>_{ADDRESS_BUILD}_:</label>
                <div class='col-md-2'>
                    <input id='ADDRESS_BUILD' name='ADDRESS_BUILD' value='%ADDRESS_BUILD%'
                           placeholder='_{ADDRESS_BUILD}_'
                           class='form-control' type='text'>
                </div>

                <label class='control-label col-md-2 pull-left' for='ADDRESS_FLAT'>_{ADDRESS_FLAT}_:</label>
                <div class='col-md-4'>
                    <input type=text name=ADDRESS_FLAT value='%ADDRESS_FLAT%' placeholder='_{ADDRESS_FLAT}_' class='form-control' id='ADDRESS_FLAT'>
                </div>
            </div>

            <hr/>

            %PAYMENTS%

            <div class='form-group'>
                <label class='control-element col-md-12 text-center' for='TP_ID'>_{RULES}_</label>
                <div class='col-md-12'>
                    <textarea cols=60 rows=8 class='form-control' id='TP_ID'></textarea>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label required col-md-6' for='ACCEPT_RULES'>_{ACCEPT}_</label>
                <div class='col-md-2'>
                    <input type='checkbox' required='required' name='ACCEPT_RULES' id='ACCEPT_RULES' value='1'>
                </div>
            </div>

            %CAPTCHA%

        </div>
        <div class='box-footer'>
            <div class='box-footer text-right'>
                <input type='submit' name='reg' value='_{SEND}_' class='btn btn-primary'>
            </div>
        </div>

    </div>

</FORM>
