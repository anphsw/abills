<div class="col-xs-12 col-md-6">
    <div class='box box-theme box-big-form'>
        <div class='box-header with-border'>
            <h3 class='box-title'>_{MESSAGES}_</h3>
            <div class='box-tools pull-right'>
                <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                    <i class='fa fa-minus'></i>
                </button>
            </div>
        </div>
        <div class='box-body'>

            <div class='form-group'>
                <label class='control-label col-md-3' for='MSG_ID'>ID:</label>
                <div class='col-md-3'>
                    <input id='MSG_ID' name='MSG_ID' value='%MSG_ID%' placeholder='%MSG_ID%' class='form-control'
                           type='text'>
                </div>

                <label class='control-label col-md-4' for='INNER_MSG'>_{PRIVATE}_:</label>
                <div class='col-md-1'>
                    <input type=checkbox id="INNER_MSG" name='INNER_MSG' value=1 %INNER_MSG%>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='CHAPTER_ID'>_{CHAPTERS}_:</label>
                <div class='col-md-9'>
                    %CHAPTER_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='SUBJECT'>_{SUBJECT}_:</label>
                <div class='col-md-9'>
                    <input id='SUBJECT' name='SUBJECT' value='%SUBJECT%' placeholder='%SUBJECT%' class='form-control'
                           type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='MESSAGE'>_{MESSAGE}_:</label>
                <div class='col-md-9'>
                    <input id='MESSAGE' name='MESSAGE' value='%MESSAGE%' placeholder='%MESSAGE%' class='form-control'
                           type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='STATE'>_{STATE}_:</label>
                <div class='col-md-9'>
                    %STATE_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='PRIORITY'>_{PRIORITY}_:</label>
                <div class='col-md-9'>
                    %PRIORITY_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{CLOSED}_ _{PERIOD}_:</label>
                <div class='col-md-4'>
                    <input id='CLOSE_FROM_DATE' name='CLOSE_FROM_DATE' value='%CLOSE_FROM_DATE%'
                           placeholder='%CLOSE_FROM_DATE%' class='form-control datepicker' type='text'>
                </div>
                <label class='control-label col-md-1'>-</label>
                <div class='col-md-4'>
                    <input id='CLOSE_TO_DATE' name='CLOSE_TO_DATE' value='%CLOSE_TO_DATE%' placeholder='%CLOSE_TO_DATE%'
                           class='form-control datepicker' type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='MSGS_TAGS'>_{MSGS_TAGS}_:</label>
                <div class='col-md-9'>
                    %MSGS_TAGS_SEL%
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-md-3'>_{EXECUTION}_:</label>
                <div class='col-md-4'>
                    <input id='PLAN_FROM_DATE' name='PLAN_FROM_DATE' value='%PLAN_FROM_DATE%'
                           placeholder='%PLAN_FROM_DATE%' class='form-control datepicker' type='text'>
                </div>
                <label class='control-label col-md-1'>-</label>
                <div class='col-md-4'>
                    <input id='PLAN_TO_DATE' name='PLAN_TO_DATE' value='%PLAN_TO_DATE%' placeholder='%PLAN_TO_DATE%'
                           class='form-control datepicker' type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='RESPOSIBLE'>_{RESPOSIBLE}_:</label>
                <div class='col-md-9'>
                    %RESPOSIBLE_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='ADMIN'>_{ADMIN}_:</label>
                <div class='col-md-9'>
                    %ADMIN_SEL%
                </div>
            </div>
        </div>
    </div>
</div>

