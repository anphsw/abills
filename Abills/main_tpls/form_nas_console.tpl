<form action=$SELF_URL METHOD=post name=FORM_NAS>
<input type=hidden name='index' value='61'>
<input type=hidden name='NAS_ID' value='%NAS_ID%'>
<input type=hidden name='console' value='1'>
<TABLE class=form>
<TR><th class=form_title colspan=2>$_NAS Console</th></TR>
<TR><TD>ID</TD><TD><b>%NAS_ID%</b><i>%CHANGED%</i></TD></TR>
<TR><TD>$_NAME:</TD><TD>%NAS_NAME%</TD></TR>
<TR><th colspan=2>:$_MANAGE:</th></TR>
<TR><TD>IP:PORT:</TD><TD><input type=text name=NAS_MNG_IP_PORT value='%NAS_MNG_IP_PORT%'></TD></TR>
<TR><TD>$_USER:</TD><TD><input type=text name=NAS_MNG_USER value='%NAS_MNG_USER%'></TD></TR>
<TR><TD>$_PASSWD:</TD><TD><input type=password name=NAS_MNG_PASSWORD value='%NAS_MNG_PASSWORD%'></TD></TR>
<TR><TD>$_TYPE:</TD><TD><select name=type><option value=ssh>ssh</option></select></TD></TR>
<TR><th colspan=2><textarea cols=70 rows=10 name=CMD>%CMD%</textarea></th></TR>
<TR><td class=line colspan=2></td></TR>
<TR><TH colspan=2 class=even><input type=submit name=ACTION value='$_SEND'></TH></TR>
</TABLE>
</form>

