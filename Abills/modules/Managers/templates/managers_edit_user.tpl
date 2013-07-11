<br/><br/>
<br/><br/>
<form action='$SELF_URL' METHOD='POST' NAME=NEW_USER>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=%UID%>

<b>$_LOGIN</b>: <input type=text  name='LOGIN' value='%ID%'>
<b>$_PASSWD</b>: <input type=text  name=PASSWD value='%PASSWORD%'>

<b>$_DESCRIBE</b>:<input type=text  name='_describe' value='%_describe%' size=30><br /><br />

<b>$_FIO</b>: <input type=text  name='FIO' value='%FIO%' size=50>
<b>$_PHONE</b>: <input type=text  name='PHONE' value='%PHONE%'>
<br><br>

<b>$_CONTRACT_ID</b>: <input type=text  name=CONTRACT_ID value='%CONTRACT_ID%'>
<b>$_CONTRACT $_DATE</b>:<input class='tcalInput' name='CONTRACT_DATE' value='%CONTRACT_DATE%' id='CONTRACT_DATE' rel='tcal' size='12' type='text'> <br/><br/>
<b>$_PASPORT</b>: <input name='PASPORT_NUM' value='%PASPORT_NUM%' type='text'>
<b>$_DATE</b>: <input class='tcalInput' name='PASPORT_DATE' value='%PASPORT_DATE%' size='10' rel='tcal' id='PASPORT_DATE' type='text'>
<b>$_GRANT</b>: <input name='PASPORT_GRANT' value='%PASPORT_GRANT%' type='text' size='55'> <br/><br/>
<b>$_ADDRESS</b><br>
<b>$_ADDRESS_STREET</b>: %STREET_SEL%
<b>$_ADDRESS_BUILD</b>: <input type=text  name=ADDRESS_BUILD value='%ADDRESS_BUILD%' size=3> <b>$_ADDRESS_FLAT</b>: <input type=text  name=ADDRESS_FLAT value='%ADDRESS_FLAT%' size=3>
<br> 
<b>$_TARIF_PLAN</b>: %TP_NAME%<br/><br/>

<b>$_COMMENTS</b>:<br/>
<textarea name=COMMENTS cols=80 id=comments>%COMMENTS%</textarea>
<br/><br/>
<table width=100% class='table_border'>
<tr>
<th>$_DEPOSIT(грн.)</th>
<th>$_BALANCE_RECHARCHE</th>
<th>$_PAYMENTS (<a href='$SELF_URL?index=2&UID=%UID%'>$_DETAIL</a>)</th>
</tr>
<tr>
<td>
	<b style='font-size:20px;'>%DEPOSIT%</b>
</td>
<td style='text-align: left; padding:20px; width:240px;'>
	<input type=text name=SUM value='0.00' size=10><input name=payment_add type=submit value='$_ADD'><br/><br/>
	<b>$_CREDIT:</b>:<br/><input type=text  name=CREDIT value='%CREDIT%' size=10><button style='margin:0px;'>$_PRINT</button><br/><br/>
	<b>$_COMMENTS:</b>:<br/> <textarea name=PAYMENT_COMMENT cols=20 id=comments>%PAYMENT_COMMENT%</textarea><br/><br/>
</td>
<td valign='top'>
%PAYMENT_LIST%
</td>
</tr>
</table>
<br />

<b>$_SHEDULE_CHANGE с</b><span>  </span> <input class='tcalInput' name='SHEDULE_BLOCK_DATE' value='$NEXT_MONTH' id='SHEDULE_BLOCK' rel='tcal' size='12' type='text'> <b>$_PERIOD </b>
<select style='margin:0px 10px;' name=BLOCK_PERIOD>
	<option>1</option>  
	<option>2</option>
	<option>3</option>
	<option>4</option>
	<option>5</option>
	<option>6</option>
	<option>7</option>
	<option>8</option>
	<option>9</option>
	<option>10</option>
	<option>11</option>
	<option>12</option>	
</select>
<b> $_MONTH</b>
<button type=submit style='margin-left:40px;' name=shedule_block value=1>$_SHEDULE</button>
<br />

<b>$_SHEDULE $_CHANGE_TP </b> 
%TP_SEL%
<b>с</b><input class='tcalInput' name='SHEDULE_TP_DATE' value='$NEXT_MONTH' id='SHEDULE_TP_DATE' rel='tcal' size='12' type='text'> 
<button type=submit style='margin-left:40px;' name=shedule_tp value=1>$_SHEDULE</button><br><br>

%SHEDULE%

%HISTORY%


<b>$_ADD_STATIC_IP</b> <input type=text name=IP value='%IP%' style='margin:0px 10px;'> 
<hr>
<center>
<input type=submit name=change value='$_SAVE'><br><br>
</form>
