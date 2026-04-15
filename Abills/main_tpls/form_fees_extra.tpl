<div class='card card-outline collapsed-card mb-0 border-top'>
    <div class='card-header with-border'>
        <h3 class='card-title'>_{EXTRA}_</h3>
        <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
            </button>
        </div>
    </div>
    <div class='card-body'>
        <div class='form-group row'>
            <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='START_DATE'>_{START}_:</label>
            <div class='col-sm-10 col-md-9'>
                <input id='START_DATE' type='date' name='START_DATE' value='%START_DATE%' class='form-control'>
            </div>
        </div>

        <div class='form-group row'>
            <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='END_DATE'>_{END}_:</label>
            <div class='col-sm-10 col-md-9'>
                <input id='END_DATE' type='date' name='END_DATE' value='%END_DATE%' class='form-control' >
            </div>
        </div>

        <div class='form-group row'>
            <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='MODULE'>_{MODULE}_:</label>
            <div class='col-sm-10 col-md-9'>
                %MODULE_SEL%
            </div>
        </div>

        <div class='form-group row'>
            <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='TP_ID'>_{TARIF_PLAN}_ (TP_ID):</label>
            <div class='col-sm-10 col-md-9'>
                <input id='TP_ID' type='number' name='TP_ID' value='%TP_ID%' class='form-control'>
            </div>
        </div>

        <div class='form-group row'>
            <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='COUNT'>_{COUNT}_:</label>
            <div class='col-sm-10 col-md-9'>
                <input id='COUNT' type='number' name='COUNT' value='%COUNT%' class='form-control' min='0'>
            </div>
        </div>

        <div class='form-group row'>
            <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='UNITS'>_{UNITS}_:</label>
            <div class='col-sm-10 col-md-9'>
                %UNITS_SEL%
            </div>
        </div>

        <div class='form-group row'>
            <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='DISCOUNT'>_{DISCOUNT}_:</label>
            <div class='col-sm-10 col-md-9'>
                <input id='DISCOUNT' name='DISCOUNT' value='%DISCOUNT%'
                       type='number' min='0' max='100' step='0.01' class='form-control'>
            </div>
        </div>

    </div>
</div>