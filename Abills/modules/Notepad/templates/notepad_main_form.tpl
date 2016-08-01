<form class='form-horizontal' action=$SELF_URL name='notepad_form' method=POST>
    <input type=hidden name=index value=$index>
    <input type=hidden name=inventory_main value=1>
    <input type=hidden name=ID value=$FORM{chg}>


    <div class='panel panel-default panel-form'>
        <div class='panel-body'>

            <!-- TAB NAVIGATION -->
            <ul class='nav nav-tabs' role='tablist'>
                <li class='active'>
                    <a href='#time_explicit_tab' role='tab' data-toggle='tab'>_{ONCE}_</a>
                </li>
                <li>
                    <a href='#time_custom_tab' role='tab' data-toggle='tab'>_{PERIODICALLY}_</a>
                </li>
            </ul>

            <hr/>

            <!-- TAB CONTENT -->
            <div class='tab-content'>
                <div class='active tab-pane' id='time_explicit_tab'>

                    <input type='hidden' name='EXPLICIT_TIME' value='1'/>

                    <div class='form-group'>
                        <label class='control-label col-md-2' for='DATE'>_{DATE}_:</label>
                        <div class='col-md-10'>
                            <input class='form-control tcal with-time' type='text' id='DATE' name='DATE' value='%DATE%'
                                   placeholder='%DATE%'/>
                        </div>
                    </div>


                </div>
                <div class='tab-pane' id='time_custom_tab'>

                    <input type='hidden' name='CUSTOM_TIME' value='1'/>


                    <div class='form-group'>
                        <div class='col-md-4'>
                            <input type='text' class='form-control' name='MONTH_DAY' value='%MONTH_DAY%'
                                   data-tooltip='_{ONCE}_ : 1 <br /> _{PERIODICALLY}_ : 1,2,3,6'
                                   data-tooltip-position='left'
                                   placeholder='_{DAY}_' disabled='disabled'/>
                        </div>
                        <div class='col-md-4'>
                            %MONTH_SELECT%
                        </div>
                        <div class='col-md-4'>
                            <input type='text' class='form-control' name='YEAR' value='%YEAR%' placeholder='_{YEAR}_'
                                   disabled='disabled'/>
                        </div>
                    </div>

                    <div class='form-group'>
                        <div class='col-md-7'>
                            <label class='control-label col-md-6'>_{DAY}_ _{WEEK}_</label>
                            <div class='col-md-6'>
                                %WEEK_DAY_SELECT%
                            </div>
                        </div>
                        <div class='col-md-5' data-tooltip='<b>Including holidays </b>'>
                            <label class='control-label col-md-6' for='INCLUDING_HOLIDAYS'>_{HOLIDAY}_</label>
                            <div class='col-md-6'>
                                <input type='checkbox' %HOLIDAYS_CHECKED% data-return='1' class='control-element'
                                       id='INCLUDING_HOLIDAYS'
                                       name='HOLIDAYS' value='1' disabled='disabled'>
                            </div>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='control-label col-md-3'>_{TIME}_</label>
                        <div class='col-md-9'>
                            <div class='col-md-5'>
                                <input class='form-control' type='text' id='HOUR' name='HOUR' placeholder='09'
                                       value='%HOUR%'/>
                            </div>
                            <div class='col-md-1 control-element'>
                                <span>:</span>
                            </div>
                            <div class='col-md-5'>
                                <input class='form-control' type='text' id='MINUTE' name='MINUTE' placeholder='00'
                                       value='%MINUTE%'/>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <hr/>

            <div class='form-group'>
                <label class='control-label col-md-2'>_{STATUS}_:</label>
                <div class='col-md-10'>
                    %STATUS%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-2' for='SUBJECT'>_{SUBJECT}_:</label>
                <div class='col-md-10'>
                    <input class='form-control' type='text' name='SUBJECT' id='SUBJECT' value='%SUBJECT%'/>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-2' for='TEXT'>_{TEXT}_:</label>
                <div class='col-md-10'>
                    <textarea name='TEXT' id='TEXT' rows='4' class='form-control'>%TEXT%</textarea>
                </div>
            </div>

        </div>
        <div class='panel-footer'>
            <input class='btn btn-primary' type='submit' name='%ACTION%' value='%ACTION_LNG%'/>
        </div>
    </div>

</form>

<script>
    function disableInputs(context) {
        var j_context = jQuery(jQuery(context).attr('href'));

        j_context.find('input').prop('disabled', true);
        j_context.find('select').prop('disabled', true);

        updateChosen();
    }

    function enableInputs(context) {
        var j_context = jQuery(jQuery(context).attr('href'));

        j_context.find('input').prop('disabled', false);
        j_context.find('select').prop('disabled', false);

        updateChosen();
    }


    jQuery(function () {
        jQuery('a[data-toggle=\"tab\"]').on('shown.bs.tab', function (e) {
            enableInputs(e.target);
            disableInputs(e.relatedTarget);
        })
    });


</script>