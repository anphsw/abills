

    <div class='card card-secondary'>
        <div class='card-header with-border'>
            <h3 class='card-title'>_{FILTERS}_</h3>
            <div class='card-tools pull-right'>
                <button type='button' class='btn btn-box-tool' data-card-widget='collapse'>
                    <i class='fa fa-minus'></i>
                </button>
            </div>
        </div>
        <div class='card-body'>

            <form action='$SELF_URL' method='GET' name='stats' class='form-inline'>
                <input type='hidden' name='sid' value='%SID%'>
                <input type='hidden' name='index' value='%INDEX%'>
                <input type='hidden' name='ID' value='%ID%'>
                <input type='hidden' name='UID' value='%UID%'>
    <div class='form-group'>

                <label for=''> _{DATE}_: </label>
                %DATE_PICKER%

                <label for=''> _{SPEED}_: </label>
                %DIMENSION%

                <label for='ROWS'> _{ROWS}_: </label>
                <input type='text' ID='ROWS' name='ROWS' size='3' value='%ROWS%' class='form-control'>

                <input type='checkbox' name='ONLINE' value='1' %ONLINE% ID='ONLINE'>
                <label for='ONLINE'> Online </label>
        <input type='submit' ID='show' name='show' value='_{SHOW}_' class='btn btn-primary'>
    </div>
            </form>

        </div>


    </div>
