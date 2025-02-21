<div>
  <input type='hidden' name='COMPANY_ID' value='%ID%'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='FIO_REQUIRE' id='FIO_REQUIRE' value='$FORM{FIO_REQUIRE}'>

  <div class='%FORM_ATTR%'>
    %MAIN_USER_TPL%
  </div>
  <div id='form_2' class='card for_sort card-primary card-outline %FORM_ATTR%'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{INFO}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i>
        </button>
      </div>
    </div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-sm-3 col-md-2 text-right control-label' for='NAME'>_{NAME}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input id='NAME' class='form-control' name='NAME' value='%NAME%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-3 col-md-2 text-right control-label' for='REPRESENTATIVE' >_{REPRESENTATIVE}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input class='form-control' id='REPRESENTATIVE' name='REPRESENTATIVE' value='%REPRESENTATIVE%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-3 col-md-2 text-right control-label' for='PHONE'>_{PHONE}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input %PHONE_PATTERN% class='form-control' id='PHONE' name='PHONE' value='%PHONE%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label for='TAX_NUMBER' class='col-sm-3 col-md-2 text-right control-label'>_{TAX_NUMBER}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input class='form-control' id='TAX_NUMBER' placeholder='%TAX_NUMBER%' name='TAX_NUMBER' value='%TAX_NUMBER%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label for='EDRPOU' class='col-sm-3 col-md-2 text-right control-label'>_{EDRPOU}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input class='form-control' id='EDRPOU' placeholder='%EDRPOU%' name='EDRPOU' value='%EDRPOU%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label for='COMMENTS' class='control-label col-sm-3 col-md-2 text-right'>_{COMMENTS}_:</label>
        <div class='col-sm-9 col-md-10'>
          <textarea class='form-control' type='text' id='COMMENTS' placeholder='%COMMENTS%' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>

    </div>

    %ADDRESS_TPL%
    %DOCS_TEMPLATE%

    <!-- Other panel  -->
    <div class='card card-outline card-big-form collapsed-card mb-0 border-top'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{EXTRA_ABBR}_. _{FIELDS}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        %INFO_FIELDS%
      </div>
    </div>
  </div>
</div>

<script>

  let edrpouInput = document.getElementById('EDRPOU');

  edrpouInput.addEventListener('input', function(event) {
    event.preventDefault();

    let edrpouValue = event.target.value.trim();
    if( edrpouValue && edrpouValue.length == 8 ){
      getCompanyData(edrpouValue);
    }
  });

  function getCompanyData(edrpou) {
    sendRequest(`/api.cgi/companies/public-records/${edrpou}`, {}, 'GET').then(result => {
      if (result.company) {
        edrpouInput.dataset.tooltip = result.company.nameShort;
        let comments = result.company.kvedNumber + ' - ' + result.company.kved + '\n' + result.company.address

        let arrDate = result.company.innDate.split('.');
        let day = arrDate[0];
        let month = arrDate[1];
        let year = arrDate[2];
        let newDate = year + '-' + month + '-' + day;

        jQuery('#NAME').val(result.company.nameShort);
        jQuery('#TAX_NUMBER').val(result.company.inn);
        jQuery('#REPRESENTATIVE').val(result.company.director);
        jQuery('#REGISTRATION').val(newDate);
        jQuery('#COMMENTS').val(comments);
      } else {
        console.log(result);
      }
    }).catch(err => {
      console.log(err);
    });
  }
</script>
