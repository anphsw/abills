<form id='liqpay_form' method='post' action='https://www.liqpay.com/api/checkout' accept-charset='utf-8'>


<!-- <textarea cols=80 rows=20> -->

  %BODY%
  <input type='hidden' name='signature' value='%SIGN%' />
  <input type='hidden' name='language' value='ru' />

<!--
</textarea>
-->

<table width=400 class=form>
<tr><th class='form_title' colspan=2>LiqPAY</th></tr>
<tr><td colspan=2 align=center>
<img src='https://www.liqpay.com/static/img/logo.png'></td></tr>
<tr><th colspan=2 align=center>
<a href='https://secure.privatbank.ua/help/verified_by_visa.html'>
<img src='/img/v-visa.gif' width=140 height=75 border=0></a>
<a href='http://www.mastercard.com/ru/personal/ru/cardholderservices/securecode/mastercard_securecode.html'>
<img src='/img/mastercard-sc.gif' width=140 height=75 border=0>
</a>
</td></tr>

<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
<tr><td>$_BALANCE_RECHARCHE_SUM:</td><td>$FORM{SUM}</td></tr>
<tr><td>$_COMMISSION:</td><td>%COMMISSION_SUM%</td></tr>
<tr><td>$_TOTAL $_SUM:</td><td>$FORM{TOTAL_SUM}</td></tr>
<!-- <tr><td>$_PAY_WAY:</td><td>%PAY_WAY_SEL%</td></tr> -->


<tr>  

<th colspan=2 class=even><input type=submit name=add value='$_PAY'>
</table>
</form>
