<form action='$SELF_URL' METHOD='post'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='BUILDS' value='$FORM{BUILDS}'/>
<TABLE class='form'>
<TR><TH class='form_title' colspan='2'>$_ADDRESS_BUILD</TH></TR>
<TR><TD>$_NUM:</TD><TD><input type='text' name='NUMBER' value='%NUMBER%' size=6 /></TD></TR>
<TR><TD>$_ADDRESS_STREET:</TD><TD>%STREET_SEL%</TD></TR>
<TR><TD>$_ENTRANCES:</TD><TD><input type='text' name='ENTRANCES' value='%ENTRANCES%' size=6  /></TD></TR>
<TR><TD>$_FLORS:</TD><TD><input type='text' name='FLORS' value='%FLORS%' size=6 /></TD></TR>
<TR><TD>$_FLATS:</TD><TD><input type='text' name='FLATS' value='%FLATS%' size=6  /></TD></TR>

<TR><TH class='form_title' colspan='2'>-</TH></TR>

<TR><TD>$_CONTRACT:</TD><TD><input type='text' name='CONTRACT_ID' value='%CONTRACT_ID%'/></TD></TR>
<TR><TD>$_CONTRACT $_DATE:</TD><TD><input type='text' name='CONTRACT_DATE' value='%CONTRACT_DATE%'/></TD></TR>
<TR><TD>$_PRICE:</TD><TD><input type='text' name='CONTRACT_PRICE' value='%CONTRACT_PRICE%'/></TD></TR>

<TR><TH class='form_title' colspan='2'>$_COMMENTS</TH></TR>

<TR><TH colspan='2'><textarea cols=60 rows=6 name=COMMENTS>%COMMENTS%</textarea></TH></TR>



<TR><TD>$_MAP:</TD><TD>X: <input type='text' name='MAP_X' value='%MAP_X%' size=6 /> Y: <input type='text' name='MAP_Y' value='%MAP_Y%' size=6/></TD></TR>
<TR><TD>$_ADDED:</TD><TD>%ADDED%</TD></TR>
<TR><TH colspan=2 class=even><input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='button'/></TH></TR>
</TABLE>

</form>
