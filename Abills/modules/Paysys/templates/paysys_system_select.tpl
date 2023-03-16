<div class='m-2 logo-container'>
  <input type='radio' id='%PAY_SYSTEM%' value='%PAY_SYSTEM%' name='PAYMENT_SYSTEM' required hidden %CHECKED%>
  <label role='button' for='%PAY_SYSTEM%' class='d-flex justify-content-center card card-primary h-100'>
    <div class='form-group row d-flex justify-content-center'>
      <div class='card-body'>
        <img class='img-fluid' src='%PAY_SYSTEM_LC%' alt='%PAY_SYSTEM_NAME%'>
      </div>
      <div class='%HIDDEN%'>
        <h4>%PAY_SYSTEM_NAME%</h4>
      </div>
    </div>
  </label>
</div>

<style>
  input[type='radio']:checked + label {
    transform: scale(1.01, 1.01);
    box-shadow: 4px 4px 2px #AAAAAA;
    z-index: 100;
  }

  input[type='radio']:hover + label {
    transform: scale(1.05, 1.05);
    box-shadow: 5px 5px 3px #AAAAAA;
    z-index: 101;
  }

  label {
    border-radius: 5px;
  }

  .logo-container {
    max-width: 12rem;
  }
</style>
