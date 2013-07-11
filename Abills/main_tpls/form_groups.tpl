<form action='$SELF_URL' METHOD='post'>
<input type='hidden' name='index' value='27'/>
<input type='hidden' name='chg' value='%GID%'/>
<TABLE class=form>
<TR><TH colspan=2 class=form_title>$_GROUPS</TH></TR>
<TR><TD>GID:</TD><TD><input type='text' name='GID' value='%GID%'/></TD></TR>
<TR><TD>$_NAME:</TD><TD><input type='text' name='NAME' value='%NAME%'/></TD></TR>
<TR><TD>$_DESCRIBE:</TD><TD><input type='text' name='DESCR' value='%DESCR%'></TD></TR>
<TR><TD>$_ALLOW $_CREDIT</TD><TD><input type='checkbox' name='ALLOW_CREDIT' value='1' %ALLOW_CREDIT%></TD></TR>
<TR><TD>$_DISABLE PAYSYS</TD><TD><input type='checkbox' name='DISABLE_PAYSYS' value='1' %DISABLE_PAYSYS%></TD></TR>
<TR><TD>$_SEPARATE_DOCS:</TD><TD><input type='checkbox' name='SEPARATE_DOCS' value='1' %SEPARATE_DOCS%></TD></TR>
<TR><TH colspan=2 class=even><input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='button'/></TH></TR>
</TABLE>

</form>
