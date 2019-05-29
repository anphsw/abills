<div class='box box-theme box-form'>
    <div class='box-body'>

        <form action=$SELF_URL method=post class='form-horizontal'>
            <input type=hidden name=index value=$index>
            <input type=hidden name=ID value='$FORM{chg}'>

            <fieldset>
                <legend>_{SERVICES}_</legend>
                <div class='form-group'>
                    <label class='control-label col-md-3' for='NUM'>_{NUM}_:</label>
                    <div class='col-md-4'>
                        <input id='NUM' name='NUM' value='%ID%' placeholder='%ID%' class='form-control' type='text'
                               disabled>
                    </div>
                    <label class='control-label col-md-5'>_{PLUGIN_VERSION}_: %MODULE_VERSION%</label>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
                    <div class='col-md-9'>
                        <input id='NAME' name='NAME' value='%NAME%' placeholder='_{NAME}_' class='form-control'
                               type='text'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='MODULE'>Plug-in:</label>
                    <div class='col-md-9'>
                        <input id='MODULE' name='MODULE' value='%MODULE%' placeholder='%MODULE%' class='form-control'
                               type='text'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='USER_PORTAL'>_{USER}_ PORTAL:</label>
                    <div class='col-md-9'>
                        %USER_PORTAL_SEL%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='STATUS'>_{DISABLE}_:</label>
                    <div class='col-md-9'>
                        <input id='STATUS' name='STATUS' value='1' %STATUS% type='CHECKBOX'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='URL'>URL:</label>
                    <div class='col-md-9'>
                        <input id='URL' name='URL' value='%URL%' placeholder='%URL%'
                               class='form-control' type='text'>
                    </div>
                </div>

                %EXTRA_PARAMS%

                <div class='form-group'>
                    <label class='control-label col-md-3' for='DEBUG'>DEBUG:</label>
                    <div class='col-md-9'>
                        %DEBUG_SEL%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='LOGIN'>_{LOGIN}_:</label>
                    <div class='col-md-9'>
                        <input id='LOGIN' name='LOGIN' value='%LOGIN%' placeholder='%LOGIN%'
                               class='form-control' type='text'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='PASSWORD'>_{PASSWD}_:</label>
                    <div class='col-md-9'>
                        <input id='PASSWORD' name='PASSWORD' class='form-control' type='password'>
                    </div>
                </div>

                <div class='form-group'>
                    <div class='col-md-12'>
                        <textarea id='COMMENT' name='COMMENT' cols='50' rows='4' class='form-control'
                                  placeholder='_{COMMENTS}_'>%COMMENT%</textarea>
                    </div>
                </div>

                <div class='form-group text-center'>
                    %SERVICE_TEST%
                </div>

                <div class='box-footer'>
                    <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
                </div>
            </fieldset>

        </form>

    </div>
</div>
