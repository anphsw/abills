<br>
<form id='stalker_tp_add' action='$SELF_URL' method='POST'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name=ID value='$FORM{stalker_tp_chg}'>
  <table align='center'>
    <tbody>
      <tr>
        <td width='100'>$_EXTERNAL_ID</td>
        <td><input name='EXTERNAL_ID' value='%EXTERNAL_ID%' type='text'></td>
      </tr>
      <tr>
        <td>$_NAME</td>
        <td><input name='NAME' value='%NAME%' type='text'></td>
      </tr>
 <!--    <tr>
        <td>По умолчанию</td>
        <td><input name='user_default' value='1' type='checkbox'></td>
     </tr>
 -->     
      <tr>
        <td><input type=submit name='%STALKER_ACTION%' value='%STALKER_LNG_ACTION%'></td>
      </tr>
    </tbody>
  </table>
</form>                