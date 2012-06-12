<br/><br/>
<br/><br/>
<form action='$SELF_URL' METHOD='POST' NAME=NEW_USER>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=%UID%>

<b>$_LOGIN:</b>: <input type=text  name='LOGIN' value='%ID%'>
<b>$_PASSWD:</b>: <input type=text  name=PASSWD value='%PASSWD%'>
<b>$_PHONE</b>: <input type=text  name=PHONE value='%PHONE%'>
<!-- <b>$_COMMENTS</b>: <input type=text name=COMMENTS value='%COMMENTS%'> --> <br/><br/> 
<b>$_FIO</b>: <input type=text  name='FIO' value='%FIO%' size=50>
<b>$_CONTRACT_ID</b>: <input type=text  name=CONTRACT_ID value='%CONTRACT_ID%'>
<b>$_CONTRACT $_DATE</b>:<input class=\"tcalInput\" name=\"3.CONTRACT_DATE\" value=\"%CONTRACT_DATE%\" id=\"3.CONTRACT_DATE\" rel=\"tcal\" size=\"12\" type=\"text\"> <br/><br/>
<b>$_ADDRESS_STREET</b>: <input type=text  name='ADDRESS_STREET' value='%ADDRESS_STREET%'>
<b>$_ADDRESS_BUILD</b>: <input type=text  name=BUILD value='%BUILD%'> <b>$_ADDRESS_FLAT</b>: <input type=text  name=ADDRESS_FLAT value='%ADDRESS_FLAT%'> 
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

<b>$_SHEDULE $_HOLD_UP с </b><span>  </span> <input class=\"tcalInput\" name=\"SHEDULE_BLOCK\" value=\"$DATE\" id=\"SHEDULE_BLOCK\" rel=\"tcal\" size=\"12\" type=\"text\"> <b>$_PERIOD </b>
<select style='margin:0px 10px;'>
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
<button type=submit style='margin-left:40px;'>$_SHEDULE</button>
<br />

<b>$_SHEDULE $_CHANGE_TP </b> 
%TP_SEL%
<b>с</b><input class=\"tcalInput\" name=\"SHEDULE_BLOCK\" value=\"$DATE\" id=\"SHEDULE_BLOCK\" rel=\"tcal\" size=\"12\" type=\"text\"> 
<button type=submit style='margin-left:40px;'>$_SHEDULE</button><br><br>
<b>$_ADD_STATIC_IP</b> <input type=text name=IP value='%IP%' style='margin:0px 10px;'> 
<hr>
<center>
<input type=submit name=change value='$_SAVE'><br><br>

