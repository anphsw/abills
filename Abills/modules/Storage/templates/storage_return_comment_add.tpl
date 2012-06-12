<br />
<form action=$SELF_URL  name=\"storage_return_comment\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=$FORM{UID}>
<input type=hidden name=return_storage value=$FORM{return_comment}>
<table border=\"0\" >
  <tr>
    <td>$_COMMENTS:</td>
    <td><textarea name=\"COMMENTS\">%COMMENTS%</textarea></td>
  </tr>
</table>
<input type=submit name='%ACTION%' value='%ACTION_LNG%'>
</form>