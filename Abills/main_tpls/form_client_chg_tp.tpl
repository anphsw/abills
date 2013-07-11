<form action='$SELF_URL' METHOD='POST' name='user'>
<input type=hidden name=sid value='$sid'>
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=m value='%m%'>
<input type=hidden name='index' value='$index'>
<TABLE width=550 class=form>
<tr><th colspan=2 class='title_color' align=right>$_TARIF_PLANS</th></tr>
<TR><TD>$_FROM:</TD><TD class='even'>$user->{TP_ID} %TP_NAME% </TD></TR>
<TR><TD>$_TO:</TD><TD>%TARIF_PLAN_TABLE%</TD></TR>
%PARAMS%

<tr><td colspan=2>%SHEDULE_LIST%</td></tr>
<tr><th class='even' colspan=2>%ACTION%</th></tr>
</TABLE>


<div id='open_popup_block_middle' style='width:400px; height:200px'>
  <a id='close_popup_window'>x</a>
  <div id='popup_window_content'><br/>
    <p>
    
    $_CHANGE<BR>
    
    $_TARIF_PLAN    <br>
    
    $_ACCEPT: <input type=checkbox value='$_HOLD_UP' name='ACCEPT_RULES'> <br>
    </p>
    <input type=submit value='$_SET' name='set'>
  </div>
</div>

</form>
