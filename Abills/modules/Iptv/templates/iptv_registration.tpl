<script language='JavaScript'>
    function autoReload() {
        document.iptv_user_info.add_form.value = '1';
        document.iptv_user_info.TP_ID.value = '';
        document.iptv_user_info.new.value = '$FORM{new}';
        document.iptv_user_info.step.value = '$FORM{step}';
        document.iptv_user_info.submit();
    }
</script>

<link href='/styles/default_adm/css/client.css' rel='stylesheet'>

<form action='$SELF_URL' method=post name='iptv_user_info' class='form-horizontal'>
    <input type=hidden name=TP_IDS value='%TP_IDS%'>
    <input type=hidden name=DOMAIN_ID value=$FORM{DOMAIN_ID}>
    <input type=hidden name=module value=Iptv>

    <div class='box box-theme box-form center-block'>

        <div class='box-header with-border'><h4 class='box-title'>_{REGISTRATION}_</h4></div>
        <div class='box-body'>
            %CHECKED_ADDRESS_MESSAGE%
            <div class='form-group'>
                <label class='control-label col-md-3' for='LANGUAGE'>_{LANGUAGE}_</label>
                <div class='col-md-9'>
                    %SEL_LANGUAGE%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label required col-md-3' for='LOGIN'>_{LOGIN}_</label>
                <div class='col-md-9'>
                    <input id='LOGIN' name='LOGIN' value='%LOGIN%' required placeholder='_{LOGIN}_' class='form-control'
                           type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label required col-md-3' for='FIO'>_{FIO}_</label>
                <div class='col-md-9'>
                    <input id='FIO' name='FIO' value='%FIO%' required placeholder='_{FIO}_' class='form-control'
                           type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label required col-md-3' for='PHONE'>_{PHONE}_</label>
                <div class='col-md-9'>
                    <input id='FIO' name='PHONE' value='%PHONE%' required placeholder='_{PHONE}_' id="PHONE"
                           class='form-control' type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='EMAIL'>E-MAIL</label>
                <div class='col-md-9'>
                    <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='E-mail' class='form-control'
                           type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='SUBSCRIBE'>_{SERVICES}_</label>
                <div class='col-md-9'>
                    %SUBSCRIBE_FORM%
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-md-3' for='TP_ID'>_{TARIF_PLAN}_</label>
                <div class='col-md-9'>
                    %TP_ADD%
                </div>
            </div>

            %ADDRESS_TPL%

            %PAYMENTS%

            <div class='form-group text-center'>
                <label class='control-element col-md-12 ' for='RULES'>_{RULES}_</label>
                <div class='col-md-12'>
                    <textarea ID='RULES' cols=60 rows=8 class='form-control' readonly> %_RULES_% </textarea>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-elenement col-md-7 required text-right' for='ACCEPT_RULES'>_{ACCEPT}_</label>
                <div class='col-md-5'>
                    <input type='checkbox' required name='ACCEPT_RULES' value='1' id="ACCEPT_RULES">
                </div>
            </div>
            %CAPTCHA%
        </div>

        <div class='box-footer text-right'>
            <input type=submit name=reg value='_{REGISTRATION}_' class='btn btn-primary'>
        </div>

    </div>
</FORM>


%MAPS%

