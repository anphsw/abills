<div class='noprint'>
<FORM action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{chg}'>
<input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
<table width='400' class=form>
<tr><td>$_PORT: </td><td><input type='text' name='PORT' value='%PORT%' size=3></td></tr>
<tr><td>$_STATUS: </td><td> %STATUS_SEL%</td></tr>
<tr><td>UPLINK: </td><td><input type='text' name='UPLINK' value='%UPLINK%' size=3></td></tr>
<tr><td>$_DESCRIBE: </td><td><input type='text' name='COMMENTS' value='%COMMENTS%'></td></tr>
<tr><th colspan='2' class=even><input type='submit' name='%ACTION%' value='%ACTION_LNG%'></th></tr>
</table>
</FORM>
</div>
