<form action=\"$SELF_URL\" name=\"region_view\">
<input type=hidden name=index value=$index>

<table class=form>
<tr>
 <td colspan='2' style='text-align:center;'>$_DISTRICT: %DISTRICTS_TABLE%</td>
 <td><input type=CHECKBOX name=SHOW_USERS %SHOW_USERS% value=1 /> $_USER &nbsp;&nbsp;</td>
 <td colspan='2' style='text-align:center;'>%TYPES% &nbsp;&nbsp;</td>
 <td><input type=CHECKBOX name=SHOW_NAS %SHOW_NAS%   value=1 /> $_NAS &nbsp;&nbsp;</td>
 <th colspan='2' class=even><input type=submit name=SHOW value=$_SHOW /></th></tr>
</table>
