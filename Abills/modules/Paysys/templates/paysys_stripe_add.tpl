<center>
<div class='panel panel-default'>
<div class='panel-body'>

<form action='$SEL_URL' method='POST'>
<input type=hidden name=OPERATION_ID value='$FORM{OPERATION_ID}'>
<input type=hidden name=PAYMENT_SYSTEM value='$FORM{PAYMENT_SYSTEM}'>
<input type=hidden name=TP_ID value='$FORM{TP_ID}'>
<input type=hidden name=PHONE value='$FORM{PHONE}'>
<input type=hidden name=index value='$index'>

<table style='min-width:350px;' width=auto class=form>
<tr><th colspan=2 bgcolor=#EEEEEE class=form_title>Stripe</th></tr>
<tr><td>$_ORDER:</td><td>$FORM{OPERATION_ID}</td></tr>
<tr><td>$_SUM:</td><td>$FORM{SUM}</td></tr>
<tr><td>$_DESCRIBE:</td><td>%LOGIN% $FORM{DESCRIBE}</td></tr>
</table>

  <script
    src='https://checkout.stripe.com/checkout.js' class='stripe-button'
    data-key='$conf{PAYSYS_STRIPE_PUBLISH_KEY}'
    data-amount='%AMOUNT%'
    data-name='$conf{WEB_TITLE}'
    data-description='2 widgets ($FORM{SUM})'
    data-image='/128x128.png'>
  </script>
</form>

</div>
</div>
</center>