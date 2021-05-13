<form action='$SELF_URL' method='GET' name='DOCS_SERVICES_INVOICE'>
  <input type='hidden' name='index' value='%index%' />
  <input type='hidden' name='UID' value='%UID%' />
  <input type='hidden' name='DATE' value='%DATE%' />
  <input type='hidden' name='create' value='1' />
  <input type='hidden' name='CUSTOMER' value='%CUSTOME%' />
  <input type='hidden' name='step' value='$FORM{step}' />

  <div class='card card-danger'>
    <div class='card-header'>
      <h3 class='card-title'>%TITLE_INVOICE%</h3>
      <div class='card-tools'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      %SERVICE_INVOICE%
    </div>
  </div>
</form>