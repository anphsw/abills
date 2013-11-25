
<form action=$SELF_URL  name=\"storage_return_comment\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=$FORM{UID}>
<input type=hidden name=return_storage value=$FORM{return_comment}>
<table class=form >
  <tr>
    <td>$_COMMENTS:</td>
    <td><textarea name=\"COMMENTS\">%COMMENTS%</textarea></td>
  </tr>
<tr><th colspan=2 class=even><input type=submit name='%ACTION%' value='%ACTION_LNG%'></th></tr>
</table>

</form>