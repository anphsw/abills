<!-- USERS -->
<tr><td colspan='2'><hr/></td></tr>
<tr><td colspan='2'>
<table border=0>
<tr><td colspan='2'>$_FIO (*):</td><td><input tabindex='3' type='text' name='FIO' value='%FIO%'/></td><td>UID (>, <):</td><td><input tabindex='10' type='text' name='UID' value='%UID%'/></td></tr>
<tr><td colspan='2'>$_CONTRACT_ID (*):</td><td><input tabindex='4' type='text' name='CONTRACT_ID' value='%CONTRACT_ID%'/></td><td>BILL ID (>, <):</td><td><input tabindex='9' type='text' name='BILL_ID' value='%BILL_ID%'/></td></tr>
<tr><td colspan='2'>$_CONTRACT $_TYPE:</td><td>%CONTRACT_SUFIX%</td>
<tr><td colspan='2'>$_CONTRACT $_DATE:</td><td><input type=text name=CONTRACT_DATE value='%CONTRACT_DATE%' ID='CONTRACT_DATE' size=12 rel='tcal'></td>
<tr><td colspan='2'>$_PHONE (>, <, *):</td><td><input tabindex='5' type='text' name='PHONE' value='%PHONE%'/></td><td>$_REGISTRATION (<>):</td><td><input type=text name=REGISTRATION value='%REGISTRATION%' ID='REGISTRATION' size=12 rel='tcal'></td></tr>
<tr><td colspan='2'>$_COMMENTS (*):</td><td><input tabindex='6' type='text' name='COMMENTS' value='%COMMENTS%'/></td><td>$_ACTIVATE (<>):</td><td> <input type=text name=ACTIVATE value='%ACTIVATE%' ID='ACTIVATE' size=12 rel='tcal'> </td></tr>
<tr><td colspan='2'>$_GROUP:</td><td>%GROUPS_SEL%</td><td class='even'>$_EXPIRE (<>):</td><td><input type=text name=EXPIRE value='%EXPIRE%' ID='EXPIRE' size=12 rel='tcal'></td></tr>
<tr><td colspan='2'>$_DEPOSIT (>, <):</td><td><input tabindex='8' type='text' name='DEPOSIT' value='%DEPOSIT%'/></td></tr>

<tr><td rowspan=2>$_CREDIT</td><td>$_SUM (>, <): </td><td><input tabindex='11' type='text' name='CREDIT' value='%CREDIT%'/></td><th>&nbsp;</th></tr>
<tr><td>$_DATE ((>, <) YYYY-MM-DD):</td><td><input type=text name='CREDIT_DATE' value='%CREDIT_DATE%' ID='CREDIT_DATE' rel='tcal' size=12> </td></tr>

<tr><td colspan='2'>$_REDUCTION (<>):</td><td><input  tabindex='13' type='text' name='REDUCTION' value='%REDUCTION%'/></td><th colspan='2' class='title_color'>$_PASPORT</th></tr>

<tr><td rowspan=2>$_PAYMENTS</td><td>$_DATE ((>, <) YYYY-MM-DD):</td><td><input type=text name=PAYMENTS value='%PAYMENTS%' ID='PAYMENTS' size=12 rel='tcal'></td><TD class='even'>$_NUM:</TD><TD><input  tabindex='25' type=text name=PASPORT_NUM value='%PASPORT_NUM%'></TD></tr>
<tr><td>$_DAYS (>, <):</td><td><input  tabindex='15' type='text' name='PAYMENT_DAYS' value='%PAYMENT_DAYS%'/></td><TD class='even'>$_DATE:</TD><TD>
<input type=text name=PASPORT_DATE value='%PASPORT_DATE%' ID='PASPORT_DATE' size=12 rel='tcal'></TD></tr>

<tr><td colspan='2'>E-Mail (*):</td><td><input  tabindex='19' type='text' name='EMAIL' value='%EMAIL%'/></td><TD class='even'>$_GRANT:</TD><TD><input  tabindex='27' type=text name=PASPORT_GRANT value='%PASPORT_GRANT%'></TD></tr>

<tr><td colspan='2'>$_DISABLE:</td><td>$_YES: <input  tabindex='20' type='radio' name='DISABLE' value='1'/> $_NO<input  tabindex='20' type='radio' name='DISABLE' value='0'/></td></tr>
<tr><td colspan='3'>
<table width=100%>
%ADDRESS_FORM%
</table></td></tr>


%INFO_FIELDS%
</table>
</td></tr>
