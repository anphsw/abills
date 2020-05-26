<form action=$SELF_URL?index=$index&splid=%ID% name='suppliers_form' method='post' class='form form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=ID value=%ID%>

    <div class='row'>
        <div class='col-md-6'>
            <div class='box box-theme box-big-form'>
                <div class='box-header with-border'><h4 class='box-title'>_{SUPPLIERS}_ </h4></div>
                <div class='box-body'>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='NAME'>_{NAME}_</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='NAME' name='NAME' type='text' value='%NAME%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='DATE'>_{DATE}_</label>
                        <div class='col-md-9'>
                            <input class='datepicker form-control datepickerActive' id='DATE' name='DATE' type='text'
                                   value='%DATE%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='OKPO'>_{OKPO_EDRPOY}_</label>
                        <div class='col-md-9'>
                            <input class='form-control' pattern='%OKPO_PATTERN%' name='OKPO' type='text' id='OKPO'
                                   value='%OKPO%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='INN'>_{INDIVIDUAL_TAX_NUMBER}_</label>
                        <div class='col-md-9'>
                            <input class='form-control' name='INN' pattern='%INN_PATTERN%' type='text' id='INN'
                                   value='%INN%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='INN_SVID'>_{CERTIFICATE_OF_INDIVIDUAL_TAX_NUMBER}_</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='INN_SVID' name='INN_SVID' type='text' value='%INN_SVID%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <div class='col-md-12'>%ADDRESS_FORM%</div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for="COMMENT">_{COMMENTS}_</label>
                        <div class='col-md-9'>
                            <textarea class='form-control' rows='5' id="COMMENT" name='COMMENT'>%COMMENT%</textarea>
                        </div>
                    </div>

                </div>
            </div>
        </div>
        <div class='col-md-6'>
            <div class='box box-theme box-big-form'>
                <div class='box-header with-border text-center'>
                    <h3 class='box-title'>_{BANK_ESSENTIAL}_</h3>
                    <div class='box-tools pull-right'>
                        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                            <i class='fa fa-minus'></i>
                        </button>
                    </div>
                </div>
                <div class='box-body'>
                    <div class='form-group'>
                        <label class='control-label col-md-3' for='BANK_NAME'>_{NAME_OF_BANK}_</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='BANK_NAME' name='BANK_NAME' type='text'
                                   value='%BANK_NAME%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='MFO'>_{MFO}_</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='MFO' name='MFO' pattern='%MFO_PATTERN%' type='text'
                                   value='%MFO%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='ACCOUNT'>_{ACCOUNT}_</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='ACCOUNT' name='ACCOUNT' type='text' value='%ACCOUNT%'/>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class='col-md-6'>
            <div class='box collapsed-box box-theme box-big-form'>
                <div class='box-header with-border text-center'>
                    <h3 class='box-title'>_{CONTACTS}_</h3>
                    <div class='box-tools pull-right'>
                        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                            <i class='fa fa-plus'></i>
                        </button>
                    </div>
                </div>
                <div class='box-body'>
                    <div class='form-group'>
                        <label class='control-label col-md-3' for='PHONE'>_{PHONE}_ 1:</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='PHONE' name='PHONE' type='text' value='%PHONE%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='PHONE2'>_{PHONE}_ 2:</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='PHONE2' name='PHONE2' type='text' value='%PHONE2%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='FAX'>_{FAX}_:</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='FAX' name='FAX' type='text' value='%FAX%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='URL'>_{WEBSITE}_:</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='URL' name='URL' type='text' value='%URL%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='EMAIL'>E-mail:</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='EMAIL' name='EMAIL' type='text' value='%EMAIL%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='TELEGRAM'>Telegram:</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='TELEGRAM' name='TELEGRAM' type='text' value='%TELEGRAM%'/>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class='col-md-6'>
            <div class='box collapsed-box box-theme box-big-form'>
                <div class='box-header with-border text-center'>
                    <h3 class='box-title'>_{GUIDANCE}_</h3>
                    <div class='box-tools pull-right'>
                        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                            <i class='fa fa-plus'></i>
                        </button>
                    </div>
                </div>
                <div class='box-body'>
                    <div class='form-group'>
                        <label class='control-label col-md-3' for='ACCOUNTANT'>_{POSITION_MANAGER}_:</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='ACCOUNTANT' name='ACCOUNTANT' type='text'
                                   value='%ACCOUNTANT%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='DIRECTOR'>_{MANAGER}_:</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='DIRECTOR' name='DIRECTOR' type='text' value='%DIRECTOR%'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='MANAGMENT'>_{ACCOUNTANT}_:</label>
                        <div class='col-md-9'>
                            <input class='form-control' id='MANAGMENT' name='MANAGMENT' type='text'
                                   value='%MANAGMENT%'/>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class='box-footer'>
        <input type=submit name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
    </div>
</form>