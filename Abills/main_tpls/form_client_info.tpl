<TABLE width='600' class='form'>
<TR class='even'><TD><b>$_LOGIN:</b></TD><TD><b>%LOGIN%</b> <i>(UID: %UID%)</i></TD></TR>
<TR class='odd'><TD><b>$_DEPOSIT:</b></TD><TD>%DEPOSIT%  &nbsp; %DOCS_ACCOUNT% &nbsp; %PAYSYS_PAYMENTS%</TD></TR>
%EXT_DATA%
%INFO_FIELDS%
<TR class='odd'><TD><b>$_CREDIT:</b> $_DATE: %CREDIT_DATE%</TD><TD>%CREDIT% %CREDIT_CHG_BUTTON%</TD></TR>
<TR class='odd'><TD><b>$_REDUCTION:</b></TD><TD>%REDUCTION% % $_DATE: %REDUCTION_DATE%</TD></TR>
<TR class='odd'><TD><b>$_FIO:</b></TD><TD>%FIO%</TD></TR>
<TR class='odd'><TD><b>$_PHONE:</b></TD><TD>%PHONE%</TD></TR>
<TR class='odd'><TD><b>$_ADDRESS:</b></TD><TD>%ADDRESS_STREET%, %ADDRESS_BUILD%/%ADDRESS_FLAT%</TD></TR>
<TR class='odd'><TD><b>E-mail:</b></TD><TD>%EMAIL%</TD></TR>
<TR class='even'><TD><b>$_CONTRACT:</b></TD><TD>%CONTRACT_ID%%CONTRACT_SUFIX%</TD></TR>
<TR class='even'><TD><b>$_CONTRACT $_DATE:</b></TD><TD>%CONTRACT_DATE%</TD></TR>
<TR class='odd'><TD><b>$_STATUS:</b></TD><TD>%STATUS%</TD></TR>
<TR class='total'><TD colspan='2'>&nbsp;</TD></TR>
<TR class='odd'><TD><b>$_ACTIVATE:</b></TD><TD>%ACTIVATE%</TD></TR>
<TR class='odd'><TD><b>$_EXPIRE:</b></TD><TD>%EXPIRE%</TD></TR>
<TR class='odd'><th colspan='2'>$_PAYMENTS</th></TR>
<TR class='odd'><TD><b>$_DATE:</b></TD><TD>%PAYMENT_DATE%</TD></TR>
<TR class='odd'><TD><b>$_SUM:</b></TD><TD>%PAYMENT_SUM%</TD></TR>
</TABLE>


<div id='open_popup_block_middle' style='width:400px; height:200px'>
  <a id='close_popup_window'>x</a>
  <div id='popup_window_content'><br/>
    <p>

    <form action=$SELF_URL>
    <input type=hidden name='index' value='10'>
    <input type=hidden name='sid' value='$sid'>
    
    <b>$_CHANGE $_CREDIT</b><BR>
    $_SUM: %CREDIT_SUM%
    <br>
    <br>
    $_PRICE: %CREDIT_CHG_PRICE%
    <br>
    <br>
    $_ACCEPT: <input type=checkbox value='$user->{CREDIT_SUM}' name='change_credit'> <br>
    </p>
    <input type=submit value='$_SET' name='set'>
    </form>
  </div>
</div>

