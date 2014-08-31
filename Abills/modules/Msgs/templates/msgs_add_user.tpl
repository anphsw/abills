<form action='$SELF_URL'>
<input type=hidden  name=index value='$index'>
<input type=hidden  name=LOCATION_ID value='%LOCATION_ID%'>
<input type=hidden  name=ADDRESS_FLAT value='%ADDRESS_FLAT%'>
<input type=hidden  name=NOTIFY_FN value='msgs_unreg_requests_list'>
<input type=hidden  name=NOTIFY_ID value='%ID%'>
<input type=hidden  name=add_user value='%ID%'>

<table width=600 class=form>
<tr><td>$_LOGIN:</td><td><input type=text  name=LOGIN value='%LOGIN%'></td></tr>
<tr><td>$_FIO:</td><td><input type=text  name=FIO value='%FIO%'></td></tr>
<tr><td>$_TARIF_PLAN:</td><td>%TP_SEL%</td></tr>
<tr><td>$_GROUP:</td><td>%GID_SEL%</td></tr>
<tr><td>$_PHONE:</td><td><input type=text  name=PHONE value='%PHONE%'></td></tr>
<tr><td>E-MAIL:</td><td><input type=text  name=EMAIL value='%EMAIL%'></td></tr>

<tr><th colspan=2><input type=submit name=add_user_ value='$_ADD'></th></tr>
</table>

</form>