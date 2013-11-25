<table width=600 class=form>
<tr><th colspan=2 bgcolor=$_COLORS[6]>&nbsp;</th></tr>
<tr><th colspan=2>$_NEGATIVE_DEPOSIT
<p>
$_ACTIVATE_NEXT_PERIOD: %TOTAL_DEBET%
</p>
</th></tr>
<tr><td align=center colspan=2>%PAYMENT_BUTTON% %DOCS_BUTTON% %CARDS_BUTTON% %CREDIT_CHG_BUTTON%</td></tr>
<tr><td class=line colspan=2></td></tr>
<tr><td>$_DEPOSIT:</td><td>%DEPOSIT%</td></tr>
<tr><td>$_CREDIT:</td><td>%CREDIT%</td></tr>
</table>




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
