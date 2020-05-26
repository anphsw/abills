<form METHOD=POST class='form-horizontal' name='accident_for_equipment' >
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='chg' value='%chg%'>
    <input type='hidden' name='add' value='%add%'>
    <input type='hidden' name='id_equipment' value='%id_equipment%'>

    <div class='box box-theme box-form'>
        <div class='box-header with-border'>
            <h4 class='box-title'>
                _{ACCIDENT_FOR_EQUIPMENT}_
            </h4>
        </div>
        <div class="box-body">
            <div class="form-group">
                <label class="control-label col-md-4 col-sm-3">_{NAME}_:</label>
                <div class="col-md-8 col-sm-9">
                    <input type='text' name='NAME' value='%NAME%'
                           class='form-control' readonly>
                </div>
            </div>

            <div class="form-group">
                <label class="control-label col-md-4 col-sm-3">_{FROM}_:</label>
                <div class="col-md-8 col-sm-9">
                    <input type='text' class='form-control datepicker' value='%FROM_DATE%' name='FROM_DATE'/>
                </div>
            </div>

            <div class="form-group">
                <label class="control-label col-md-4 col-sm-3">_{TO}_:</label>
                <div class="col-md-8 col-sm-9">
                    <input type='text' class='form-control datepicker' value='%TO_DATE%' name='TO_DATE'/>
                </div>
            </div>

            <div class="form-group">
                <label class="control-label col-md-4 col-sm-3">_{RESPONSIBLE}_:</label>
                <div class="col-md-8 col-sm-9">
                    %RESPONSIBLE%
                </div>
            </div>

            <div class="form-group">
                <label class="control-label col-md-4 col-sm-3">_{STATUS}_:</label>
                <div class="col-md-8 col-sm-9">
                    %STATUS%
                </div>
            </div>

            <div class='col-md-12 col-sm-12'>
                <input type="submit" class="btn btn-primary col-md-12 col-sm-12" name="BUTTON_ACTION" value="%BUTTON_ACTION%">
            </div>
        </div>
    </div>
</form>