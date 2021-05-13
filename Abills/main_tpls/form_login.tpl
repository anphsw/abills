<script type='text/javascript'>
  function selectLanguage() {
    var sLanguage = '';
    if (/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
      sLanguage = jQuery('#language_mobile').val() || '';
    } else {
      sLanguage = jQuery('#language').val() || '';
    }

    var sLocation = '$SELF_URL?DOMAIN_ID=$FORM{DOMAIN_ID}&language=' + sLanguage;
    document.location.replace(sLocation);
  }

  function set_referrer() {
    document.getElementById('REFERER').value = location.href;
  }

  jQuery(function () {
    if ('%TECH_WORKS_BLOCK_VISIBLE%' === '1') {
      jQuery('#tech_works_block').css('display', 'block');
    }

    if (/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
      jQuery('#language_mobile').on('change', selectLanguage);
    } else {
      jQuery('#language').on('change', selectLanguage);
    }
  }())
</script>
<style>
	.wrapper {
		overflow: visible;
	}
</style>

<div class='d-flex flex-sm-row flex-md-row-reverse bg-light pl-2 mb-3 border-bottom'>
  <div class='pt-3 bd-highlight'>
    <h1 class='h1 font-weight-bolder'>
      <span style='color: red;'>A</span>BillS
      <small class='text-muted' style='font-size: 65%'>%TITLE%</small>
      &nbsp;
    </h1>
  </div>
</div>

<div class='container'>
  <div class='row p-0 m-0 justify-content-center'>
    <div class='col-md-6 col-md-offset-3'>
      %ERROR_MSG%
    </div>
  </div>

  <div class='row p-0 m-0 justify-content-center'>
    <div class='col-md-6 col-md-offset-3'>
      <div class='info-box bg-yellow' style='display: none;' id='tech_works_block'>
        <span class='info-box-icon'><i class='fa fa-wrench'></i></span>
        <div class='info-box-content' style='line-height: 80px'>
          <span class='info-box-number text-center'>%TECH_WORKS_MESSAGE%</span>
        </div>
      </div>
    </div>
  </div>

  <div class='row p-0 m-0 justify-content-center'>
    <div class='pr-0 col-xs-12 col-sm-6 col-md-4'>
      <form action='$SELF_URL' METHOD='post' name='frm' id='form_login' class='form-horizontal'>

        <input type=hidden name=DOMAIN_ID value='$FORM{DOMAIN_ID}'>
        <input type=hidden ID=REFERER name=REFERER value='$FORM{REFERER}'>
        <input type='hidden' id='AUTH_G2FA' name='AUTH_G2FA' value='1'>
        <input type='hidden' name='G2FA_SUCCESS' value='%G2FA_SUCCESS%'>
        <input type='hidden' name='LOGIN' value='1'/>

        <div class='form-group row has-feedback'>
          <div class='input-group'>
            <span class='input-group-addon glyphicon glyphicon-globe'></span>
            %SEL_LANGUAGE%
          </div>
        </div>

        <div class='form-group row'>
          <div class='input-group'>
            <div class='input-group-prepend'>
              <div class='input-group-text'>
                <span class='fa fa-user'></span>
              </div>
            </div>
            <input type='text' id='user' name='user' value='%user%' class='form-control' placeholder='_{LOGIN}_'>
          </div>
        </div>

        <div class='form-group row'>
          <div class='input-group'>
            <div class='input-group-prepend'>
              <div class='input-group-text'>
                <span class='fa fa-lock'></span>
              </div>
            </div>
            <input type='password' id='passwd' name='passwd' value='%password%' class='form-control'
                   placeholder='_{PASSWD}_'>
          </div>
        </div>

        <div class='form-group row'>
          <button style='font-size: 1rem !important;' type='submit' name='logined'
                  class='btn rounded btn-success btn-block btn-flat form-control'
                  onclick='set_referrer()'>_{ENTER}_
          </button>
        </div>
        <div class='row'>
          %PSWD_BTN%
        </div>

      </form>
    </div>
  </div>

</div>

<script type='text/javascript'>
  jQuery('#form_login').on('submit', function () {
    var userLogin = jQuery('#user').val();
    if (typeof (Storage) !== "undefined") {
      localStorage.setItem("lastLogin", userLogin);
    }
  });

  jQuery(function () {
    jQuery('#user').val(localStorage.getItem("lastLogin"));
  }())
</script>
