<table width=100% class=form>
<tbody>
<tr>
<td><h5>Информация:</h5></td>
<td><img src='img/visa.jpg'></td>
</tr>
<tr>
<td>Оплата производится с помощью платежного шлюза Московского Индустриального Банка.
Выбирая этот способ оплаты, Вы будете перенаправлены на платежный шлюз банка.
Для совершения оплаты Вам необходимо последовательно ввести информацию о Вашей банковской карте и внимательно проверить введенную информацию.
Эта информация не доступна посторонним лицам. Все данные передаются в зашифрованном виде с применением протокола безопасности SSL.</td>
<td><img src='img/master.gif'></td>
</tbody>
</table>
<br>
<form action=$SELF_URL name='pay_form' method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<input type='hidden' name='MerchantId' value='%merchantid%'>
<input type='hidden' name='OrderID' value='%OrderId%'>
<input type='hidden' name='Version' value='1.0'>
<input type='hidden' name='Amount' value='%sum%'>
<input type='hidden' name='Currency' value='643'>
<input type='hidden' name='Description' value='%desc%'>
<input type='hidden' name='UrlApprove' value='%returnurl%'>
<input type='hidden' name='UrlDecline' value='%returnurl%'>
<input type='hidden' name='CustId' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='ServerURL' value='%form_url%'>
<input type='hidden' name='sid' value='%sid%'>
<input type='hidden' name='minbank_action' value='1'>

<table width=300 class=form>
<tr><th colspan='2' class='form_title'>Московский Индустриальный Банк</th></tr>
<tr>
	<td>ID:</td>
	<td>%OrderId%</td>
</tr>
<tr>
	<td>$_SUM:</td>
	<td>%amount%</td>
</tr>
<tr>
	<td>$_DESCRIBE:</td>
	<td>%desc%</td>
</tr>
<tr>
	<td>&nbsp;</td>
	<td>&nbsp;</td>
</tr>
<tr><th colspan='2' class='even'><input type='submit' value='Пополнить'></th></tr>
</table>

</form>
<br>
<table width=100%>
<tbody>
<tr>
<td>
<h5>Внимание!</h5> На следующем шаге Вы перейдёте на сервер <a href='https://mpi.minbank.ru'>mpi.minbank.ru</a> для заполнения и передачи информации о Вашей платёжной карте.
Эти данные будут переданы по безопасному протоколу (SSL) непосредственно на авторизационный Сервер Банка и являются недоступными для нашей Компании.<br>
<h5>Attention!</h5> At the next step you will be moved to the <a href='https://mpi.minbank.ru'>mpi.minbank.ru</a> server to fill out the form and send your credit card information.
This information will be passed directly to the authorization server by secure protocol (SSL) and will not be accessible for the Company.
</td>
</tbody>
</table>