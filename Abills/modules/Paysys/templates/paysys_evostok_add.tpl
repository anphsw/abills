<form id=pay name=pay method='POST' action='$SELF_URL'>

<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
<input type='hidden' name='INTERACT' value='1'>
<input type='hidden' name='OPERATION_ID' value='$FORM{OPERATION_ID}'>
<input type='hidden' name='UID' value='1'>
<input type='hidden' name='SUM' value='$FORM{SUM}'>
<input type='hidden' name='pre' value='1'>

<table width=400 class=form>

<tr><th colspan='2' class='form_title'>E-vostok</th></tr>
<tr><td>$_SERVICE:</td><td>%SERVICE_SEL%</td></tr>
<tr><td>$_PHONE:</td><td>+<input type='text' name='subno' placeholder='7903xxxxxxx' value='%subno%'></td></tr>
<tr><th colspan='2' class='even'><input type='submit' name='add' value='$_SEND'></th></tr>
</table>

</form>