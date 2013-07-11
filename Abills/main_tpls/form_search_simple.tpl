<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='search_form' value='1'>
%HIDDEN_FIELDS%
<TABLE>
<TR><TH colspan='2' class='form_title'>$_SEARCH</TH></TR>
%SEARCH_FORM%
<TR><TD>$_ROWS:</TD><TD><input type='text' name='PAGE_ROWS' value='$PAGE_ROWS'></TD></TR>
</TABLE>
<input type=submit name='search' value='$_SEARCH' class='button'>
</form>
