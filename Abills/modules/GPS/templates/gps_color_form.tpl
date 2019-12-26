
<form action=$SELF_URL method=post>
    <input type='hidden' name='index' value=$index>
    <input type='hidden' name='AID' value=%AID%>

    <div class='box box-theme box-form'>
        <div class="box-header"><h4>_{ROUTE_COLOR}_</h4></div>

        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-3 required' for='COLOR'>_{COLOR}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type='color' name='COLOR' id='COLOR' value='%COLOR%'/>
                </div>
            </div>
        </div>

        <div class='box-footer'>
            <button class='btn btn-primary' type='submit' name="change" value="change">
                _{CHANGE}_
            </button>
        </div>
    </div>

</form>