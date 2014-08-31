<form action=$SELF_URL METHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=NAS_ID value=$FORM{NAS_ID}>
<input type=hidden name=chg value=$FORM{chg}>
<table class=form>
<tr><th colspan=2 class=form_title>$_EQUIPMENT $_INFO</th><tr>
<tr class=even><td>ID: %NAS_ID%</td><td>$_NAME: %NAS_NAME% (%NAS_IP%) 
<a title='info' class='change rightAlignText' href='$SELF_URL?get_index=form_nas&amp;NAS_ID=%NAS_ID%&full=1'>info</a>
</td>

<tr><td>$_MODEL</td><td>%MODEL_SEL% (%VENDOR% / %TYPE%) %MANAGE_WEB%</td></tr>
<tr><td>System info</td><td><input type=text name=SYSTEM_ID value='%SYSTEM_ID%'></td></tr>
<tr><td>Ports:</td><td><input type=text name=PORTS value='%PORTS%'></td></tr>
<tr><td>Firmware:</td><td><input type=text name=FIRMWARE value='%FIRMWARE%'></td></tr>
<tr><td>$_SERIAL:</td><td><input type=text name=SERIAL value='%SERIAL%'></td></tr>
<tr><td>$_START_UP_DATE:</td><td><input type=text name=START_UP_DATE value='%START_UP_DATE%' ID='START_UP_DATE' size=12 rel='tcal'></td></tr>
<tr><td>$_STATUS:</td><td>%STATUS_SEL%</td></tr>
<tr><th colspan=2 class=form_title>$_COMMENTS</th></tr>
<tr><th colspan=2><textarea name=COMMENTS cols=60 rows=7>%COMMENTS%</textarea></th></tr>
<tr><th colspan=2 class=even><input type=submit name=%ACTION%  value='%ACTION_LNG%'>
<input type=submit name=get_info  value='get_info'>
</th><tr>

</table>
</form>
