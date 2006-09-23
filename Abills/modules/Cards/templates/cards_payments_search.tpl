<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<table width='300'>
<tr><th bgcolor='$_COLORS[0]' colspan='2' align='right'>$_SEARCH</th></tr>
<tr><td>$_SERIAL:</td><td><input type='text' name='SERIA' value='%SERIA%'></td></tr>
<tr><td>$_NUM:</td><td><input type='text' name='NUMBER' value='%NUMBER%'></td></tr>
<tr><td>PIN:</td><td><input type='text' name='PIN' value='%PIN%'></td></tr>
<tr><td>$_DILLERS:</td><td>%DILLERS_SEL%</td></tr>
<tr><td>$_ADMINS:</td><td>%ADMINS_SEL%</td></tr>
<tr><td>$_ADDED:</td><td><input type='text' name='DATE' value='%DATE%'></td></tr>
<tr><td>$_EXPIRE:</td><td><input type='text' name='EXPIRE' value='%EXPIRE%'></td></tr>
<tr><td>$_STATUS:</td><td>%STATUS_SEL%</td></tr>
<tr><td>$_ROWS:</td><td><input type='text' name='PAGE_ROWS' value='%PAGE_ROWS%'></td></tr>
</table>
<input type='submit' name='search' value='$_SEARCH'>
</form>
</div>