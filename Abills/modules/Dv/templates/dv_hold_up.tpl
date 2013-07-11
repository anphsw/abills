<div id=form_holdup>
<form action=$SELF_URL METHOD=GET name=holdup>
<input type=hidden name=index value=$index>
<input type=hidden name=sid value=$sid>
<input type=hidden name=UID value=$FORM{UID}>

<TABLE width=600 class=form>
<tr><th colspan=4 class=table_title align=right>$_HOLD_UP</th></tr>
<tr><th colspan=4>&nbsp;</th></tr>
<tr><td>$_FROM:</td><td>%DATE_FROM%</td>
<td>$_TO:</td><td>%DATE_TO%</td>
</tr>

<tr><th colspan=4>&nbsp;</th></tr>
<tr><th colspan=4><input type=submit value='$_HOLD_UP' name='hold_up_window' id='hold_up_window'></th></tr>
</table>


<div id='open_popup_block_middle' style='width:400px; height:200px'>
  <a id='close_popup_window'>x</a>
  <div id='popup_window_content'><br/>
    <p>
    
    <b>$_HOLD_UP</b><BR>
    
    %DAY_FEES%<br>   
    
    $_ACCEPT: <input type=checkbox value='1' name='ACCEPT_RULES'> <br>
    </p>
    <input type=submit value='$_HOLD_UP' name='add'>
  </div>
</div>


</form>
</div>
