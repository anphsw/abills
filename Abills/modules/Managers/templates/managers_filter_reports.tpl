<br>
<br>
	<form action='$SELF_URL' METHOD='post' name=FILTER_REPORT>
	<select name=SHOW_REPORT>
		<option value='users_total'>Всего учетных записей</option>
		<option value='mounth_contracts_added'>Всего заключено договоров(Апрель 2012) </option>
		<option value='mounth_contracts_deleted'>Всего разторгнуто договоров(Апрель 2012)</option>
		<option value='mounth_disabled_users'>Всего временно отключившихся(Апрель 2012)</option>
		<option value='mounth_total_debtors'>не оплативших текущий месяц</option>
		<option value='total_debtors'>не оплативших 2 и более месяцев</option>
	</select>
	<button type=submit>$_SHOW</button>
	</form>
