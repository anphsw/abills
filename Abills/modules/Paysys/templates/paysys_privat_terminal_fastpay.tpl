<div class='card card-primary card-outline'>
    <div class='card-header with-border text-center pb-0'>
        <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>
    <div class='card-body pt-0'>
        <div class='text-center m-2'>
            <img src='/styles/default/img/paysys_logo/privat24.png'
                 style='max-width: 320px; max-height: 200px;'
                 alt='P24'>
        </div>
        <div class='form-group text-center'>
            <div class='alert alert-info' role='alert'>
                <h3>_{FAST_PAY}_ ПриватБанку _{QUICK_PAYMENT}_</h3>
            </div>
        </div>
        <div class='form-group text-center'>
            <a href='%LINK%' class='btn btn-primary btn-lg' role='button' id='FASTPAY'>_{PAY_ADD}_</a>
        </div>
    </div>
</div>

<script>
    setTimeout(function () {
        window.location.href = jQuery('#FASTPAY').attr('href');
    }, 3000);
</script>