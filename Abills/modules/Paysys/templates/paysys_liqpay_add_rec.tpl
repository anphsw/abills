<div class='card card-primary card-outline'>
    <form id='liqpay_form' method='post' action='$SELF_URL' accept-charset='utf-8'>
        <input type='hidden' name='index' value='%index%'>
        <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>
        <input type='hidden' name='PAYMENT_SYSTEM' value='%PAYMENT_SYSTEM%'>
        <input type='hidden' name='DESCRIBE' value='%DESCRIBE%'>
        <input type='hidden' name='SUM' value='%SUM%'>
        <input type='hidden' name='TOTAL_SUM' value='%TOTAL_SUM%'>
        <input type='hidden' name='PHONE' value='%PHONE%'>
        <input type='hidden' name='SUBSCRIBE_FORM' value='1'>
        <input type='hidden' name='SUBSCRIBE_DATE_START' value='%SUBSCRIBE_DATE_START%'>
        %BODY%
        <div class='card-header with-border text-center pb-0'>
            <h4>_{BALANCE_RECHARCHE}_</h4>
        </div>
        <div class='card-body pt-0'>
            <div class='text-center'>
                <img src='https://static.tildacdn.com/tild6661-6134-4564-b761-306638373830/liqpaypngpagespeedce.png'
                     style='max-width: 320px; max-height: 200px;'
                     alt='LiqPay'>
            </div>

            <ul class='list-group list-group-unbordered mb-3'>
                <li class='list-group-item'>
                    <b>_{SUBSCRIBE_LIQPAY}_</b>
                </li>
                <li class='list-group-item'>
                    <b>_{SUBSCRIBE_DETAILS}_</b>
                    <div class='float-right'>
                        <a class='btn btn-warning' href='https://www.liqpay.ua/ru'>_{READ_HERE}_</a>
                    </div>
                </li>
                <li class='list-group-item'>
                    <b>_{SUBSCRIBE_LIQPAY}_</b>
                    <div class='float-right'>
                        <input type='checkbox'
                               %SUBSCRIBE%
                               data-return='1'
                               id='checkbox'
                               name='SUBSCRIBE'
                               value='1'/>
                    </div>
                </li>
            </ul>
            <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
        </div>
    </form>
</div>