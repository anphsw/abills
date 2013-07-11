
<!-- auth -->
<ul id=\"statistic\">
  <li>Всего учетных записей - <a href=\"$SELF_URL?SHOW_REPORT=users_total\" target=\"_blank\">%USER_TOTAL%</a></li>
  <li>Всего заключено договоров(%MOUNTH_STR% %YEAR%) - <a href=\"$SELF_URL?SHOW_REPORT=mounth_contracts_added\" target=\"_blank\">%REGISTRATION_MOUNTH_TOTAL%</a></li>
  <li>Всего разторгнуто договоров(%MOUNTH_STR% %YEAR%) - <a href=\"$SELF_URL?SHOW_REPORT=mounth_contracts_deleted\">%DISCONNECTED%</a></li>
  <li>Всего временно отключившихся(%MOUNTH_STR% %YEAR%) - <a href=\"$SELF_URL?SHOW_REPORT=mounth_disabled_users\">%TEMPORARILY_DISCONNECTED%</a></li>
  <li>Всего должников:<br />
не оплативших текущий месяц - <a href=\"$SELF_URL?SHOW_REPORT=mounth_total_debtors\">%REPORT_DEBETORS%</a> <br />
не оплативших 2 и более месяцев - <a href=\"$SELF_URL?SHOW_REPORT=total_debtors\">%REPORT_DEBETORS2%</a> </li>
</ul>
<form action=\"$SELF_URL\" method=\"get\" name=\"search_form\" >
<input type=hidden name=index value=15>
<input type=hidden name='STATUS' value=1>

<button name='SEARCH' value=1>$_USERS</button>

<br />
<ul id=\"buttons\">
  <li>
<button name=NEW_USER value=1>$_CREATE</button>
  </li>
  <li>
<button name=del value=1>$_DEL</button>
  </li>
  <li>
<button name=change value=1>$_BLOCK</button>
  </li>
  <li>
<button name=change value=2>$_UNBLOCK</button>
  </li>
  
</ul>
<div id=\"search\">
<button type=\"submit\" name=\"SEARCH\" value=1>$_SEARCH</button>
<input type=\"text\" name=\"QUERY\" value=\"\"/>
<select name=\"TYPE\">
  <option value=\"address\">$_ADDRESS</option>
  <option value=\"login\">$_LOGIN</option>
  <option value=\"fio\">$_FIO</option>
  <option value=\"contract_id\">$_CONTRACT_ID</option>
  <option value=\"phone\">$_PHONE</option>
  <option value=\"ip\">IP</option>
</select>
</div>

<br/><p><strong>$_TOTAL:</strong>: %RESULT_TOTAL%</p>	
 %RESULT_TABLE%
</form>

