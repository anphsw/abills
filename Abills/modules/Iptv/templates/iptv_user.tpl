<div class='noprint'>
<form action=$SELF_URL method=post>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=TP_IDS value='%TP_IDS%'>
<input type=hidden name='step' value='$FORM{step}'>
<table width=450 class=form>
<tr><td>$_TARIF_PLAN:</td><td valign=middle>[%TP_NUM%]<b> %TP_NAME% </b> %CHANGE_TP_BUTTON%</td></tr>
<tr><td>Filter-ID:</td><td><input type=text name=FILTER_ID value='%FILTER_ID%'></td></tr>
<tr><td>PIN:</td><td><input type=text name=PIN value='%PIN%'></td></tr>
<tr><td>CID (Modem) ($_DELISMITER ;):</td><td><input type=text name=CID value='%CID%'> %SEND_MESSAGE%</td></tr>
<tr><td>VoD:</td><td><input type=checkbox name=VOD value=1 %VOD%></td></tr>
<tr><td>DvCrypt ID:</td><td><input type=input name=DVCRYPT_ID value='%DVCRYPT_ID%'></td></tr>
<tr><td>$_STATUS:</td><td>%STATUS_SEL%</td></tr>
%IPTV_MODEMS%
<TR><TD>$_EXPIRE:</TD><TD><input type=text name=IPTV_EXPIRE value='%IPTV_EXPIRE%' ID='IPTV_EXPIRE' size=12 rel='tcal'>	
<tr><th colspan=2 class=even>
%BACK_BUTTON%
<input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>
</form>
</div>
