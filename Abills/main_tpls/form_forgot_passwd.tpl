<div class='login_form_border'>
<div class='kabinet-styled_table-wrap box_shadow border_rad'>

<FORM action='$SELF_URL' METHOD=POST>
<input type=hidden name=FORGOT_PASSWD value=1>
<TABLE width='400' class='form'>
<tr><th class=form_title colspan='2'>$_PASSWORD_RECOVERY</th></tr>
<tr><th align='left'>$_LOGIN:</th><td> <input type=text name=LOGIN value='' size=30> </td></tr>
<tr><th align='left'>E-Mail:</th><td> <input type=text name=EMAIL value='' size=30> </td></tr>
%EXTRA_PARAMS%
<tr><th align='center' colspan='2'><input type=submit name='SEND' value=$_SEND></th></tr>
</table>
</FORM>

</div>
</div>
