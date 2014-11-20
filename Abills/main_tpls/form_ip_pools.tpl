<form action='$SELF_URL' METHOD='post'>
<input type='hidden' name='index' value='%INDEX%'/>
<input type='hidden' name='NAS_ID' value='%NAS_ID%'/>
<input type='hidden' name='IP_POOLS' value='1'/>
<input type='hidden' name='chg' value='$FORM{chg}'/>
<TABLE class=form width=400>
<TR><TH COLSPAN='2' class=form_title>IP POOLS</TH></TR>
<TR><TD>$_NAME:</TD><TD><input type='text' name='NAME' value='%NAME%'/></TD></TR>
<TR><TD>FIRST IP:</TD><TD><input type='text' name='IP' value='%IP%'/></TD></TR>
<TR><TD>$_COUNT:</TD><TD><input type='text' name='COUNTS' value='%COUNTS%'/> MASK: %BIT_MASK%</TD></TR>

<TR class=even><TD>IPv6 $_PREFIX:</TD><TD><input type='text' name='IPV6_PREFIX' value='%IPV6_PREFIX%'/> MASK: %IPV6_BIT_MASK%</TD></TR>
<TR><TD>$_PRIORITY:</TD><TD><input type='text' name='PRIORITY' value='%PRIORITY%' size='5'/></TD></TR>
<TR><TD>$_STATIC:</TD><TD><input type='checkbox' name='STATIC' value='1' %STATIC%/></TD></TR>
<TR><TD>$_SPEED:</TD><TD><input type='text' name='SPEED' value='%SPEED%' size='5'/></TD></TR>

<TR><TD>Next Pool:</TD><TD><input type='text' name='NEXT_POOL_ID' value='%NEXT_POOL_ID%'/></TD></TR>

<TR><TH COLSPAN='2' class=even><input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='button'/></TH></TR>
</TABLE>

</form>
