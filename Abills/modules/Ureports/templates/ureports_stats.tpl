<form id='stats' class='form form-horizontal form-main' action=$SELF_URL method='POST'>
    <input type='hidden' name='sid' value='%SID%'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='UIDS' value='%UIDS%'>
    <input type='hidden' name='UID' value='%UID%'>

    <div class='box box-theme'>
        <div class='box-header with-border'>
            <h3 class="box-title">_{FILTERS}_</h3>
            <div class="box-tools pull-right">
                <button type="button" class='btn btn-box-tool' data-widget="collapse">
                    <i class="fa fa-minus"></i>
                </button>
            </div>
        </div>
        <div class='box-body'>
            <div class="form-group">
                <label class="col-md-4 col-sm-3 control-label">_{PERIOD}_:</label>
                <div class="col-md-8 col-sm-9">
                    %PERIOD%
                </div>
            </div>

            <div class="form-group">
                <label class="col-md-4 col-sm-3 control-label">_{ROWS}_:</label>
                <div class="col-md-8 col-sm-9">
                    <input type="text" name="rows" value="25" size="4" class="form-control">
                </div>
            </div>
        </div>

        <div class='box-footer'>
            <input type='submit' name='show' value='_{SHOW}_' class='btn btn-primary btn-block' form="stats"/>
        </div>
    </div>
</form>