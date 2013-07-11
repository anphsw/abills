<form action='$SELF_URL'  METHOD='POST'>
<input type='hidden' name='index' value='$index'>
%HIDDDEN_INPUT%
<table width=450 class='form'> 
<tr><td>$_PASSWD:</td><td><input type='password' id='text_pma_pw' name='newpassword' title='$_PASSWD' onchange=\"pred_password.value = 'userdefined';\" /></td></tr>
<tr><td>$_CONFIRM_PASSWD:</td><td><input type='password' name='confirm' id='text_pma_pw2' title='$_CONFIRM' onchange=\"pred_password.value = 'userdefined';\" /></td></tr>
<tr><td>  <a href='#' class='link_button' onclick=\"suggestPassword('%PW_CHARS%', '%PW_LENGTH%')\" />$_GENERED_PARRWORD</a>
          <a href='#' class='link_button' onclick=\"suggestPasswordCopy(this.form)\" />Copy</a>
</td><td><input type='text' name='generated_pw' id='generated_pw' /></td></tr>
</td><th colspan=2 class=even>%BACK_BUTTON% <input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>

</form>
