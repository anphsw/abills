<form action='$SELF_URL' METHOD='POST' ENCTYPE='multipart/form-data' id='CARDS_ADD'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg}>
<table class=form>
<tr><th class=form_title>Reports Wizard</th></tr>
<tr><td>$_NAME</td></tr>
<tr><td><input type=text name=NAME value='%NAME%' size=75></td></tr>
<tr><td>$_COMMENTS</td></tr>
<tr><td><textarea name=COMMENTS rows=4 cols=75>%COMMENTS%</textarea></td></tr>
<tr><td>$_QUERY: $_MAIN</td></tr>
<tr><td><textarea name=QUERY rows=12 cols=75>%QUERY%</textarea></td></tr>
<tr><td>$_QUERY: $_TOTAL</td></tr>
<tr><td><textarea name=QUERY_TOTAL rows=8 cols=75>%QUERY_TOTAL%</textarea></td></tr>
<tr><td>$_FIELDS</td></tr>
<tr><td><textarea name=FIELDS rows=5 cols=75>%FIELDS%</textarea></td></tr>
<tr><td>$_IMPORT: <input name=IMPORT id=IMPORT type=file></td></tr>
<tr><th><input type=submit name=%ACTION% value='%LNG_ACTION%'</th></tr>
</table>


</FORM>