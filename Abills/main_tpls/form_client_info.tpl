<TABLE width='600' class='form'>
<TR class='even'><TD><strong>$_LOGIN:</strong></TD><TD><strong>%LOGIN%</strong> <i>(UID: %UID%)</i></TD></TR>
<TR class='odd'><TD><strong>$_DEPOSIT:</strong></TD><TD>%DEPOSIT%  &nbsp; %DOCS_ACCOUNT% &nbsp; %PAYSYS_PAYMENTS%</TD></TR>
%EXT_DATA%
%INFO_FIELDS%
<TR class='odd'><TD><strong>$_CREDIT:</strong> $_DATE: %CREDIT_DATE%</TD><TD>%CREDIT% %CREDIT_CHG_BUTTON%</TD></TR>
<TR class='odd'><TD><strong>$_REDUCTION:</strong></TD><TD>%REDUCTION% % $_DATE: %REDUCTION_DATE%</TD></TR>
<TR class='odd'><TD><strong>$_FIO:</strong></TD><TD>%FIO%</TD></TR>
<TR class='odd'><TD><strong>$_PHONE:</strong></TD><TD>%PHONE%</TD></TR>
<TR class='odd'><TD><strong>$_ADDRESS:</strong></TD><TD>%ADDRESS_STREET%, %ADDRESS_BUILD%/%ADDRESS_FLAT%</TD></TR>
<TR class='odd'><TD><strong>E-mail:</strong></TD><TD>%EMAIL%</TD></TR>
<TR class='even'><TD><strong>$_CONTRACT:</strong></TD><TD>%CONTRACT_ID%%CONTRACT_SUFIX% <a class='link_button' target='new' href='$SELF_URL?qindex=10&UID=%UID%&PRINT_CONTRACT=%CONTRACT_ID%&sid=$sid&pdf=$conf{DOCS_PDF_PRINT}' title='$_PRINT'>$_PRINT</a>
<TR class='even'><TD><strong>$_CONTRACT $_DATE:</strong></TD><TD>%CONTRACT_DATE%</TD></TR>
<TR class='odd'><TD><strong>$_STATUS:</strong></TD><TD>%STATUS%</TD></TR>
<TR class='total'><TD colspan='2'>&nbsp;</TD></TR>
<TR class='odd'><TD><strong>$_ACTIVATE:</strong></TD><TD>%ACTIVATE%</TD></TR>
<TR class='odd'><TD><strong>$_EXPIRE:</strong></TD><TD>%EXPIRE%</TD></TR>
<TR class='odd'><th colspan='2'>$_PAYMENTS</th></TR>
<TR class='odd'><TD><strong>$_DATE:</strong></TD><TD>%PAYMENT_DATE%</TD></TR>
<TR class='odd'><TD><strong>$_SUM:</strong></TD><TD>%PAYMENT_SUM%</TD></TR>
</TABLE>


<div id='open_popup_block_middle' style='width:400px; height:200px'>
  <a id='close_popup_window'>x</a>
  <div id='popup_window_content'><br/>
    <p>

    <form action=$SELF_URL>
    <input type=hidden name='index' value='10'>
    <input type=hidden name='sid' value='$sid'>
    
    <strong>$_CHANGE $_CREDIT</strong><BR>
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

