<div class='card card-primary card-outline'>
    <form action='%URL%' method='post'>

        <!-- WEB Checkout ID -->
        <input type='hidden' name='merchant' value='%MERCHANT_ID%'/>
        <!-- Payment amount in tiyin -->
        <input type='hidden' name='amount' value='%AMOUNT%'/>
        <!-- Object Fields Class Account -->
        <input type='hidden' name='account[%CHECK_FIELD%]' value='%USER_ID%'/>
        <input type='hidden' name='account[TRANSACTION_ID]' value='%TRANSACTION_ID%'/>
        <!-- ==================== OPTIONAL FIELDS ====================== -->
        <!-- Language. Available values: ru | uz | en
              Other values are ignored
              Default value ru -->
        <input type='hidden' name='lang' value='ru'/>

        <!-- Currency. Available Values: 643 | 840 | 860 | 978
              Other values are ignored
              The default is 860
              ISO currency codes
              643 - RUB
              840 - USD
              860 - UZS
              978 - EUR -->
        <input type='hidden' name='currency' value='860'/>

        <!-- URL of refund after payment or cancellation of payment.
  If no return URL is specified, it is taken from the Referer request header.
  The return URL can contain parameters that Paycom replaces when requested.
  Available parameters for callback:
  : transaction - transaction id or 'null' if the transaction could not be created
  : account. {field} - fields of the Account object
  Example: https://your-service.uz/paycom/:transaction ->
  <! - <input type = 'hidden' name = 'callback' value = '{return url after payment}' /> -->

        <!-- Timeout after successful payment in milliseconds.
        Default value 15
        After successful payment, after callback_timeout
        the user is redirected to the return url after payment -->
        <input type='hidden' name='callback_timeout' value='15'/>

        <!-- Selecting a payment instrument Paycom.
        Multiple payment registrations are available at Paycom
        tools. If the payment instrument is not specified,
        the user is given a choice of payment instrument.
        If you specify the id of a certain payment instrument -
        the user is redirected to the specified payment instrument. -->
        <!-- <input type = 'hidden' name = 'payment' value = '{payment_id}' /> -->

        <!-- Payment description
  There are 3 languages ​​available to describe the payment: Uzbek, Russian, English.
  To describe the payment in several languages, use
  several fields with attribute name = 'description [{lang}]'
  lang can take the values ​​ru | en | uz -->
        <input type='hidden' name='description' value='PaymentDesc Payme'/>
        <input type='hidden' name='description' value='%DESCRIBE%'/>

        <!-- Payment detail object
        A field for a detailed description of a payment, for example, a transfer
        purchased goods, shipping costs, discounts.
        Field value (value) - JSON-string encoded in BASE64 -->
        <!-- <input type = 'hidden' name = 'detail' value = '{JSON detail object in BASE64}' /> -->
        <!-- ============================================== ==================== -->


        <div class='card-header with-border text-center'>
            <h4>_{BALANCE_RECHARCHE}_</h4>
        </div>

        <div class='card-body'>
            <div class='form-group text-center'>
                <img src='/styles/default_adm/img/paysys_logo/payme-logo.png'
                     style='width: auto; max-height: 200px;'
                     alt='payme'>
            </div>

            <table style='min-width:350px;' width='auto'>
                <tr>
                    <td>_{PAY_SYSTEM}_:</td>
                    <td>Upay</td>
                </tr>
                <tr>
                    <td>_{ORDER}_:</td>
                    <td>$FORM{OPERATION_ID}</td>
                </tr>
                <tr>
                    <td>_{SUM}_:</td>
                    <td>$FORM{SUM}</td>
                </tr>
                <tr>
                    <td>_{DESCRIBE}_:</td>
                    <td>$FORM{DESCRIBE}</td>
                </tr>
            </table>
        </div>
        <div class='card-footer'>
            <input class='btn btn-primary' type=submit value=_{PAY}_>
        </div>

    </form>
</div>
