<style>
  /*Night mode styles*/
  .modal-backdrop {
    opacity: 0.7;
  }

  /*Removing black backround*/
  div.wrapper {
    box-shadow: none !important;
    background-color: transparent !important;
  }

  .login-wrapper {
    margin-top: 1em;
  }

  @media (min-device-height: 400px) {
    .login-wrapper {
      margin-top: 2em;
    }
  }

  div.input-group > span.input-group-addon.glyphicon {
    top : 0;
  }

  #social_network_block {
    margin-top: 20px;
  }

  #form_login #input_wrapper{
    padding: 20px 30px 20px
  }

</style>


<nav class='navbar navbar-static-top' role='navigation'>
  <ul class='nav navbar-nav navbar-right'>
    <li data-visible='%REGISTRATION_ENABLED%'>
      <a href='/registration.cgi'>_{REGISTRATION}_</a>
    </li>
    <li data-visible='%HAS_REGISTRATION_PAGE%'>
      <a href='/registration.cgi?FORGOT_PASSWD=1'>_{FORGOT_PASSWORD}_</a>
    </li>
  </ul>
</nav>

</header>
<div class='login-wrapper'>
  <div class='row'>
    <div class='col-md-6 col-md-offset-3 text-center'>
      %LOGIN_ERROR_MESSAGE%
    </div>
  </div>

  <div class='row'>
    <div class='col-md-6 col-md-offset-3'>
      <div class='info-box bg-yellow' style='display: none;' id='tech_works_block'>
        <span class='info-box-icon'><i class='fa fa-wrench'></i></span>
        <!--line height to center text vertical-->
        <div class='info-box-content' style='line-height: 80px'>
          <!--<span class='info-box-text'>_{TECH_WORKS_ARE_RUNNING_NOW}_</span>-->
          <span class='info-box-number text-center'>%TECH_WORKS_MESSAGE%</span>
        </div><!-- /.info-box-content -->
      </div><!-- /.info-box -->
    </div>
  </div>

  <div class='row'>

    <form action='$SELF_URL' METHOD='post' name='form_login' id='form_login' class='form form-horizontal'>
      <input type='hidden' name='DOMAIN_ID' value='$FORM{DOMAIN_ID}'>
      <input type='hidden' ID='REFERER' name='REFERER' value='$FORM{REFERER}'>
      <input type='hidden' id='location_x' name='coord_x'>
      <input type='hidden' id='location_y' name='coord_y'>

      <div class='col-xs-12 col-md-4 col-md-offset-4 col-lg-4 col-lg-offset-4'>

        <div class='box box-body' id='input_wrapper'>

          <div class='form-group has-feedback'>
            <div class='input-group'>
              <span class='input-group-addon glyphicon glyphicon-globe'></span>
              %SEL_LANGUAGE%
            </div>
          </div>

          <div class='form-group'>
            <div class='input-group'>
              <span class='input-group-addon glyphicon glyphicon-user'></span>
              <input type='text' id='user' name='user' value='%user%' class='form-control' placeholder='_{LOGIN}_'>
            </div>
          </div>

          <div class='form-group'>
            <div class='input-group'>
              <span class='input-group-addon glyphicon glyphicon-lock'></span>
              <input type='password' id='passwd' name='passwd' value='%password%' class='form-control'
                     placeholder='_{PASSWD}_'>
            </div>
          </div>

          <div class='row'>
            <!-- /.col -->

            <button type='submit' name='logined' class='btn btn-success btn-block btn-flat form-control'
                    onclick='set_referrer()'>_{ENTER}_
            </button>

            <!-- /.col -->
          </div>

        </div>


      </div>
    </form>

  </div>
  <div class='row'>
    <!--Block for social networks buttons-->
    <div class='col-md-6 col-md-offset-3 text-center' id='social_network_block'>
      <link rel='stylesheet' href='/styles/default_adm/css/client_social_icons.css'>
      <ul class='social-network social-circle'>
        %SOCIAL_AUTH_BLOCK%
      </ul>
    </div>
  </div>
</div>

<script>

  /* Geolocation */
  jQuery(function () {
    jQuery('#language').on('change', selectLanguage);

    if ('$conf{CLIENT_LOGIN_GEOLOCATION}') {
      var loginBtn = jQuery('#login_btn');

      /* Disable login button */
      loginBtn.addClass('disabled');

      /* Enable button in 3 seconds in any case (If navigation has error) */
      setTimeout(enableButton, 3000);

      getLocation(enableButton);

      function enableButton() {
        loginBtn.removeClass('disabled');
      }
    }
    else {
      console.log('Geolocation is disabled');
    }

    if ('$conf{CLIENT_LOGIN_NIGHTMODE}') {
      var D = new Date(), Hour = D.getHours();
      if (Hour >= 18) {
        var div          = document.createElement('div');
        div.className    = 'modal-backdrop';
        div.style.zIndex = -2;

        jQuery('body').prepend(div);
        jQuery('.wrapper').addClass('modal-content');
      }
      else {
        console.log('Night mode is enabled, but it\'s not evening ( Hour < 18)');
      }
    }

    if ('%TECH_WORKS_BLOCK_VISIBLE%' === '1') {
      jQuery('#tech_works_block').css('display', 'block');
    }

  });

</script>