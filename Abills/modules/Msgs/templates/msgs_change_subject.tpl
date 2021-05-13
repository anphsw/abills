<form action='$SELF_URL' method='post'>
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='chg' value='%ID%'>
    <input type='hidden' name='OLD_SUBJECT' value='%SUBJECT%'>

    <div class='card'>
        <div class='card-header'>_{SUBJECT}_ _{CHANGE}_</div>
        <div class='card-body'>
            <input class='form-control' type='text' name='SUBJECT' value='%SUBJECT%' autofocus>
        </div>
        <div class='card-footer'>
            <input class='btn btn-primary' type='submit' name='CHANGE_SUBJECT' value='_{CHANGE}_'>
        </div>
    </div>
</form>