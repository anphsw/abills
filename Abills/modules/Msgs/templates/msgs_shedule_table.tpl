<link rel='stylesheet' href='/styles/default_adm/css/msgs.css'>
<script src='/styles/default_adm/js/msgs/shedule_table.js'></script>
<script>
    var tasksInfo = {};
</script>

%OPTIONS_SCRIPT%

<div class='box box-primary center-block'>
    <div class='box-header with-border text-right'>
        <h4 class='box-title'>_{SHEDULE_BOARD}_</h4>
    </div>
    <div class='box-body'>
        <div class='row text-left' style='padding-left: 1%; padding-right: 1%;'>
            <div id='new-tasks'></div>
        </div>
        <div class='row' style='padding-left: 1%; padding-right: 1%;'>
            <div id='hour-grid'></div>
        </div>
          
    </div>
</div>

<div class='col-md-12 col-sm-12'>
    <div class='col-md-6 col-sm-6'>
        <div class='box box-primary center-block'>
            <div class='box-header with-border text-right'>
                <h4 class='box-title'>_{SEARCH}_</h4>
            </div>
            <div class='box-body'>
                <form class='form form-inline' action=''>
                    <input type='hidden' name='index' value='$index'/>
                    <input type='hidden' name='ID' value='$FORM{ID}'/>
                    <input type='hidden' name='DATE' value='$FORM{DATE}'/>

                    <div class="form-group">
                        <label class='control-label col-md-4 col-sm-3' for='DATE'>_{DATE}_: </label>
                        <div class="col-md-8 col-sm-9">
                            <input type='text' class='form-control datepicker' 
                                value='$FORM{DATE}' name='DATE'/>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class='control-label col-md-4 col-sm-3' for='TASK_STATUS_SELECT'>_{STATUS}_: </label>
                        <div class="col-md-8 col-sm-9">
                            %TASK_STATUS_SELECT%
                        </div>
                    </div>

                    <input type='submit' class='btn btn-primary' value='_{SHOW}_'/>
                </form>
            </div>
        </div>
    </div>

    <div class='col-md-6 col-sm-6'>
        <div class='box box-primary center-block'>
            <div class='box-header with-border text-right'>
                <h4 class='box-title'>_{SET}_</h4>
            </div>
            <div class='box-body'>
                <form id='tasksForm' method='POST' action='$SELF_URL'>
                    <div class='row'>
                        <input type='hidden' name='index' value='$index'/>
                        <input type='hidden' name='jobs' id='jobsNew' />
                        <input type='hidden' name='popped' id='jobsPopped' />
                        <input type='hidden' name='DATE' value='$FORM{DATE}'/>

                        <div class='center-block text-center'>
                            <button class='btn btn-default' type='reset' id='cancelBtn'>_{CANCEL}_</button>
                            <input type='submit' class='btn btn-primary' id='saveBtn' name='change' value='_{CHANGE}_'>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<style>
    div#hour-grid > table {
        border: 1px solid silver;
    }

    div#hour-grid > table > tr > td {
        width: 110px;
        height: 30px;
    }
</style>

