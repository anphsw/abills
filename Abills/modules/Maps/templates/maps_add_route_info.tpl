<form action=$SELF_URL ID=mapForm name=adress class='form-inline'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=COORDX value=%COORDX%>
    <input type=hidden name=COORDY value=%COORDY%>
    <input type=hidden name=POINTS value=%POINTS%>

    <div class='panel panel-default'>
<div class='panel-heading'>
 <h3>_{ROUTES}_</h3>
</div>
        <div class='panel-body'>
            <div class='form-group'>
<div class='col-md-12'>
                %ROUTE_ID%
</div>
            </div>
        </div>
        <div class='panel-footer text-center'>
            <input type='submit' name=add_route_info value=_{ADD}_ class='btn btn-primary'>
        </div>
    </div>


</form>

