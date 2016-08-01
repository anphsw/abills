<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=sid value=$sid>
<input type=hidden name=CID value='%DHCP_LEASES_MAC%'>

<table width=600 class=form>
<tr><th colspan=2 class='titel_color'>_{GUEST_MODE}_</th></tr>
<tr><td><b>MAC:</b> %MAC% <b>_{PORT}_:</b> %PORTS%</td><td><input type=submit name=discovery value='_{REGISTRATION}_'></td></tr>
</table>
</form>
