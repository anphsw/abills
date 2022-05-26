<div class='col-xs-12 col-md-6'>
    <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
            <h3 class="card-title">_{SESSIONS}_</h3>
                <div class='card-tools float-right'>
                    <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                        <i class='fa fa-minus'></i>
                    </button>
                </div>
        </div>
        <div class='card-body'>
            <div class="form-group row">
                <label class="col-sm-4 col-md-4 col-form-label">SUM(>,<)</label>
                <div class="col-sm-8 col-md-8">
                    <input class='form-control' type='text' name='SUM' value='%SUM%'>
                </div>
            </div>

            <div class="form-group row">
                <label class="col-sm-4 col-md-4 col-form-label">IP (>,<)</label>
                <div class="col-sm-8 col-md-8">
                    <input class='form-control' type='text' name='IP' value='%IP%'>
                </div>
            </div>

            <div class="form-group row">
                <label class="col-sm-4 col-md-4 col-form-label">CID</label>
                <div class="col-sm-8 col-md-8">
                    <input class='form-control' type='text' name='CID' value='%CID%'>
                </div>
            </div>

            <div class="form-group row">
                <label class="col-sm-4 col-md-4 col-form-label">NAS</label>
                <div class="col-sm-8 col-md-8">
                    %SEL_NAS%
                </div>
            </div>

            <div class="form-group row">
                <label class="col-sm-4 col-md-4 col-form-label">NAS Port</label>
                <div class="col-sm-8 col-md-8">
                    <input class='form-control' type='text' name='NAS_PORT' value='%NAS_PORT%'>
                </div>
            </div>

            <div class="form-group row">
                <label class="col-sm-4 col-md-4 col-form-label">SESSION_ID</label>
                <div class="col-sm-8 col-md-8">
                    <input class='form-control' type='text' name='ACCT_SESSION_ID' value='%ACCT_SESSION_ID%'>
                </div>
            </div>

            <div class="form-group row">
                <label class="col-sm-4 col-md-4 col-form-label">_{STATUS}_</label>
                <div class="col-sm-8 col-md-8">
                    %TERMINATE_CAUSE_SEL%
                </div>
            </div>

            <div class="form-group row">
                <label class="col-sm-4 col-md-4 col-form-label">_{LAST_ENTRIES}_</label>
                <div class="col-sm-8 col-md-8">
                    <input class='form-control datepicker' type='text' name='LAST_SESSION' value='%LAST_SESSION%'>
                </div>
            </div>
        </div>
    </div>
</div>
