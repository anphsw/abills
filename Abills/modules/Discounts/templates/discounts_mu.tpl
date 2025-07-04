<div class='form-inline ml-auto flex-nowrap'>
    <div class='form-group'>
        <label class='col-md-4 col-form-label text-md-right required'>_{MODULE}_</label>
        <div class='col-md-8'>
            %MODULE_SEL%
        </div>
    </div>

    <div class='form-group'>
        <label class='col-md-4 col-form-label text-md-right required'>_{TYPE}_</label>
        <div class='col-md-8'>
            %TYPE_SEL%
        </div>
    </div>

    <div class='form-group'>
        <label class='col-md-4 col-form-label text-md-right' for='PERCENT'>_{PERCENT}_</label>
        <div class='col-md-8'>
            <input class='form-control' type='number' min='0' max='100' id='PERCENT' name='PERCENT' form='users_list' value='%PERCENT%'>
        </div>
    </div>

    <div class='form-group'>
        <label class='col-md-4 col-form-label text-md-right' for='SUM'>_{SUM}_</label>
        <div class='col-md-8'>
            <input class='form-control' type='text' id='SUM' name='SUM' form='users_list' value='%SUM%'>
        </div>
    </div>

    <div class='form-group'>
        <label class='col-md-4 control-label text-md-right' for='FROM_DATE'>_{FROM}_</label>
        <div class='col-md-8'>
            <input id='FROM_DATE' name='FROM_DATE' value='%FROM_DATE%' form='users_list' placeholder='0000-00-00'
                   class='form-control datepicker' type='text'>
        </div>
    </div>

    <div class='form-group'>
        <label class='col-md-4 control-label text-md-right' for='TO_DATE'>_{TO}_</label>
        <div class='col-md-8'>
            <input id='TO_DATE' name='TO_DATE' value='%TO_DATE%' form='users_list' placeholder='0000-00-00'
                   class='form-control datepicker' type='text'>
        </div>
    </div>

    <div class='form-group'>
        <div class='col-md-8'>
            <textarea class='form-control' name='COMMENTS' id='COMMENTS'
                      placeholder='_{COMMENTS}_' form='users_list'>%COMMENTS%</textarea>
        </div>
    </div>

</div>