<form name=COMPRA method=POST action='$conf{PAYSYS_REDSYS_URL}' class='form form-horizontal'>

  <input type=hidden name="Ds_SignatureVersion" value="HMAC_SHA256_V1">

  <input type=hidden name="Ds_MerchantParameters" value="%PARAMS%">

  <input type=hidden name="Ds_Signature" value="%SIGN%">


  <div class='panel panel-primary'>

    <div class='panel-heading text-center'>RedSys </div>
    <div class='panel-body'>

      <div class='form-group'>

          <label class='col-md-6 control-label'>_{ORDER}_:</label>

        <label class='col-md-6 control-label' style='text-align:left'>$FORM{OPERATION_ID}</label>

      </div>

      <div class='form-group'>

          <label class='col-md-6 control-label'>_{SUM}_:</label>

        <label class='col-md-6 control-label' style='text-align:left'>$FORM{SUM}</label>

      </div>


      <div class='form-group'>

          <label class='col-md-6 control-label'>_{DESCRIBE}_:</label>

        <label class='col-md-6 control-label' style='text-align:left'>$FORM{DESCRIBE}</label>

      </div>


    </div>

    <div class='panel-footer text-center'>

        <input class='btn btn-primary' type='submit' value=_{PAY}_>
    
    </div>
  
  </div>

</form>
