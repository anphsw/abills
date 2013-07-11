<br/><br/>
<br/><br/>
<form action='$SELF_URL' METHOD='POST' NAME=NEW_USER>
<input type=hidden name='index' value='15'>
<input type=hidden name='1.CREATE_BILL' value='1'>
<b>$_LOGIN</b>: <input type=text  name='1.LOGIN' value=\"$FORM{'1.LOGIN'}\">
<b>$_PASSWD</b>: <input type=text  name='2.newpassword' value=\"$FORM{'2.newpassword'}\">
<b>$_DESCRIBE</b>:<input type=text  name='3._describe' value=\"$FORM{'3._describe'}\" size=30><br /><br />

<b>$_FIO</b>: <input type=text  name='3.FIO' value=\"$FORM{'3.FIO'}\" size=50>
<b>$_PHONE</b>: <input type=text  name='3.PHONE' value=\"$FORM{'3.PHONE'}\">

<br><br>
<b>$_CONTRACT_ID</b>: <input type=text  name='3.CONTRACT_ID' value=\"$FORM{'3.CONTRACT_ID'}\">
<b>$_CONTRACT $_DATE</b>:<input class=\"tcalInput\" name=\"3.CONTRACT_DATE\" value=\"$DATE\" id=\"3.CONTRACT_DATE\" rel=\"tcal\" size=\"12\" type=\"text\"> <br/><br/>
<b>$_PASPORT</b>: <input name='3.PASPORT_NUM' value='' type='text'>
<b>$_DATE</b>: <input class='tcalInput' name='3.PASPORT_DATE' value=\"$DATE\" size=\"10\" rel=\"tcal\" id=\"PASPORT_DATE\" type=\"text\">
<b>$_GRANT</b>: <input name='3.PASPORT_GRANT' value='' type='text' size='55'> <br>
<b>$_ADDRESS</b><br>
<b>$_ADDRESS_STREET</b>: %STREET_SEL%
<b>$_ADDRESS_BUILD</b>: <input type=text  name='3.ADDRESS_BUILD' value=\"$FORM{'3.ADDRESS_BUILD'}\" size=3>
<b>$_ADDRESS_FLAT</b>: <input type=text  name='3.ADDRESS_FLAT' value=\"$FORM{'3.ADDRESS_FLAT'}\" size=3>
<br/>
<b>$_TARIF_PLAN</b>: %TP_SEL%  &nbsp;  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<b>$_PAYMENTS</b>:<input type=text  name='5.SUM' value=\"$FORM{'5.SUM'}\" style='height:40px; width:80px; font-color: red; font-size:20px;'><br /><br />


<b>$_COMMENTS</b>:<br/>
<textarea name='3.COMMENTS' cols=80 id='comments'>$FORM{'3.COMMENTS'}</textarea>
<br/><br/>

<b>ФЛ-П</b>: %GROUP_SEL%
<b>$_ACTIVATE</b>:<input class=\"tcalInput\" name=\"1.ACTIVATE\" value=\"$DATE\" id=\"1.ACTIVATE\" rel=\"tcal\" size=\"12\" type=\"text\"> <br/><br/>

<a href='$SELF_URL?index=15&UID=$FORM{UID}&pdf=1&PRINT_CONTRACT=1&print=1' target=_new class=href_buttons>$_PRINT $_CONTRACT $_PAGE 1</a>
<a href='$SELF_URL?index=15&UID=$FORM{UID}&pdf=1&PRINT_CONTRACT=1&print=1' target=_new  class=href_buttons>$_PRINT $_CONTRACT $_PAGE 2</a>
<a href='$SELF_URL?qindex=15&UID=$FORM{UID}&REGISTRATION_INFO=1$FORM{UID}&pdf=1&print=1'  target=_new  class=href_buttons>$_PRINT $_MEMORY_CARD</a>
<input class=big_buttons name=add type=submit value='$_ADD'>

</form>


