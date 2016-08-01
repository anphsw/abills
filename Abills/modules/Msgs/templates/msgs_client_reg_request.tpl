<link href='/styles/default_adm/css/client.css' rel='stylesheet'>

<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name=reg_request_form class='form-horizontal'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='ID' value='%ID%'/>
    <input type=hidden name=module value=Msgs>
    <input type=hidden name=REGISTRATION_REQUEST value=1>

    <div class='panel panel-primary panel-form center-block'>
        <div class='panel-heading text-center'><h4>_{REGISTRATION}_</h4></div>

        <div class='panel-body'>

            <div class='row'>
                <div class='col-md-1'></div>
                <div class='col-md-11'>
                    %ADDRESS_TPL%
                </div>
            </div>
            <hr/>

            <div class='form-group'>
                <label class='control-label col-md-3' for='COMPANY_NAME'>_{COMPANY}_</label>
                <div class='col-md-9'>
                    <input type='text' id='COMPANY_NAME' name='COMPANY_NAME' value='%COMPANY_NAME%'
                           placeholder='%COMPANY_NAME%'
                           class='form-control'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label required col-md-3' for='FIO'>_{FIO}_</label>
                <div class='col-md-9'>
                    <input type='text' id='FIO' name='FIO' value='%FIO%' required placeholder='%FIO%'
                           class='form-control'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label required col-md-3' for='PHONE'>_{PHONE}_</label>
                <div class='col-md-9'>
                    <input type='text' id='PHONE' name='PHONE' value='%PHONE%' required='required' placeholder='%PHONE%'
                           class='form-control'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='EMAIL'>E-mail</label>
                <div class='col-md-9'>
                    <input type='text' id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='account@mail.com'
                           class='form-control'>
                </div>
            </div>

            <hr />

            <div class='form-group'>
                <label class='control-label required col-md-3' for='CONNECTION_TIME'>_{CONNECTION_TIME}_</label>
                <div class='col-md-9'>
                    <input type='text' id='CONNECTION_TIME' name='CONNECTION_TIME' required value='%CONNECTION_TIME%'
                           placeholder='%CONNECTION_TIME%' class='form-control tcal with-time'>
                </div>
            </div>

            <!--<div class='form-group'>
                 <label class='control-label col-md-3' for='CHAPTER'>_{CHAPTERS}_</label>
                 <div class='col-md-9'>
                       %CHAPTER_SEL%
                 </div>
            </div>-->

            <div class='form-group'>
                <label class='control-label col-md-3' for='SUBJECT'>_{SUBJECT}_</label>
                <div class='col-md-9'>
                    <input type='text' id='SUBJECT' name='SUBJECT' value='_{REGISTRATION}_' readonly='readonly'
                           placeholder='%SUBJECT%'
                           class='form-control'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-sm-3' for='COMMENTS'>_{COMMENTS}_</label>
                <div class='col-md-9'>
                    <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3' class='form-control'>%COMMENTS%</textarea>
                </div>
            </div>

            <hr />

            %CAPTCHA%

        </div>

        <div class='panel-footer text-right'>
            <input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'/>
        </div>

    </div>
</FORM>


%MAPS%
