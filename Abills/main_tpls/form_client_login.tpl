<style>
	.st_icon {
		color: #3c8dbc;
		font-size: 1.2em;
	}

	.input-group {
		margin-bottom: 15px;
	}

	select.normal-width {
		max-width: 100% !important;
	}

	div.fixed {
		position: fixed;
		width: 50%;
		bottom: 10px;
		font-size: 1.5em;
		margin-left: 50px;
	}

	div.wrapper {
		box-shadow: none !important;
		background-color: transparent !important;
	}

	@media screen and (max-width: 768px) {
		div.fixed {
			margin-left: 20px;
		}
	}

	.cookieAcceptBar {
		right: 0;
		text-align: center;
		background-color: #333;
		color: #fff;
		padding: 20px 0;
		z-index: 99999;
		position: fixed;
		width: 100%;
		height: 100px;
		bottom: 0;
		left: 0;
	}

	.cookieAcceptBar a {
		color: #fff;
		text-decoration: none;
		font-weight: bold;
	}

	button .cookieAcceptBarConfirm {
		cursor: pointer;
		border: none;
		background-color: #2387c0;
		color: #fff;
		text-transform: uppercase;
		margin-top: 10px;
		height: 40px;
		line-height: 40px;
		padding: 0 20px;
	}

</style>

<link rel='stylesheet' type='text/css' href='/styles/default_adm/css/social_button.css'>

<!-- Login Form -->
<div class='login-box card card-outline card-primary' style='margin: 7% auto;'>
  <div class='mb-0 login-logo card-header text-center'>
    <b><a href='/' class='h1'><img src=''><span style='color: red;'>A</span>BillS</a></b>
  </div>
  <div class='card-body'>
    <p class='login-box-msg h5 text-muted'>%TITLE%</p>
    <div class='col-xs-12'>
      <div class='info-box bg-yellow' style='display: none;' id='tech_works_block'>
          <span class='info-box-icon'>
            <i class='fa fa-wrench'></i>
          </span>
        <div class='info-box-content'>
          <span class='info-box-number'>%TECH_WORKS_MESSAGE%</span>
        </div>
      </div>
    </div>
    <div class='col-xs-12'>
      %LOGIN_ERROR_MESSAGE%
    </div>

    <form action='$SELF_URL' METHOD='post' name='form_login' id='form_login'>
      <input type='hidden' name='DOMAIN_ID' value='$FORM{DOMAIN_ID}'>
      <input type='hidden' ID='REFERER' name='REFERER' value='$FORM{REFERER}'>
      <input type='hidden' id='HIDDE_COOKIE' name='HIDDE_COOKIE' value='%COOKIE_POLICY_VISIBLE%'>
      <input type='hidden' id='location_x' name='coord_x'>
      <input type='hidden' id='location_y' name='coord_y'>

      <div class='form-group row ml-0 mr-0 has-feedback'>
        %SEL_LANGUAGE%
      </div>

      <div class='row p-0 m-0'>
        <div class='input-group'>
          <input type='text' id='user' name='user' value='%user%' class='form-control' placeholder='_{LOGIN}_'
                 autocomplete='off'>
          <div class='input-group-append'>
            <div class='input-group-text'>
              <span class='input-group-addon fa fa-user'></span>
            </div>
          </div>
        </div>
      </div>

      <div class='row p-0 m-0'>
        <div class='input-group'>
          <input type='password' id='passwd' name='passwd' value='%password%' class='form-control'
                 placeholder='_{PASSWD}_' autocomplete='off'>
          <div class='input-group-append'>
            <div class='input-group-text'>
              <span class='input-group-addon fa fa-lock'></span>
            </div>
          </div>
        </div>
      </div>

      <div class='row p-0 m-0  %G2FA_hidden%'>
        <div class='input-group'>
          <input type='password' id='g2fa' name='g2fa' value="%g2fa%" class='form-control'
                 placeholder='_{CODE}_' autocomplete='off'>
          <div class='input-group-append'>
            <div class='input-group-text'>
              <span class='input-group-addon fa fa-asterisk'></span>
            </div>
          </div>
        </div>
      </div>

      <div class='row p-0 m-0'>
        <button style='font-size: 1rem !important;' type='submit' name='logined'
                class='btn rounded btn-primary btn-block' onclick='set_referrer()'>
          _{ENTER}_
        </button>
      </div>
    </form>

    <a data-visible='%PASSWORD_RECOVERY%' style='float: right' href='/registration.cgi?FORGOT_PASSWD=1'>_{FORGOT_PASSWORD}_</a>
    <a data-visible='%REGISTRATION_ENABLED%' href='/registration.cgi'>_{REGISTRATION}_</a>

    <div class='row row p-0 m-0'>
      <div class='col-md-12'>
        <a href='%FACEBOOK%' class='fb btn' style='%AUTH_FACEBOOK_ID%;'>
          <i class='fa fa-facebook fa-fw'></i> Login with Facebook
        </a>
        <a href='%TWITTER%' class='twitter btn' style='%AUTH_TWITTER_ID%;'>
          <i class='fa fa-twitter fa-fw'></i> Login with Twitter
        </a>
        <a href='%VK%' class='btn' style='background-color: #2787f5; color: white; %AUTH_VK_ID%'>
          <i class='fa fa-vk fa-fw'></i> Login with VK
        </a>
        <a href='%INSTAGRAM%' class='instagram btn' style='color: white; background-color: #C1205C; %AUTH_INSTAGRAM_ID%'>
          <i class='fa fa-instagram fa-fw'></i> Login with Instagram
        </a>
        <a href='%GOOGLE%' class='google btn' style='%AUTH_GOOGLE_ID%;'>
          <i class='fa fa-google fa-fw'></i> Login with Google+
        </a>
      </div>
    </div>
  </div>
</div>

<!-- Accept cookie -->
<div id='cookieAcceptBar' class='cookieAcceptBar' style='display: none;'>
  _{COOKIE_AGREEMENTS}_
  <a href='%COOKIE_URL_DOC%' target='_blank'>_{COOKIE_URL}_</a>
  <br>
  <button id='cookieAcceptBarConfirm' class='btn btn-success' onclick='hideBanner()'>_{SUCCESS}_</button>
</div>

<script>

  /* Geolocation */
  jQuery(function () {
    if (/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
      jQuery('#language_mobile').on('change', selectLanguage);
    } else {
      jQuery('#language').on('change', selectLanguage);
    }

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
    } else {
      console.log('Geolocation is disabled');
    }

    if ('$conf{CLIENT_LOGIN_NIGHTMODE}') {
      var D = new Date(), Hour = D.getHours();
      if (Hour >= 18) {
        var div = document.createElement('div');
        div.className = 'modal-backdrop';
        div.style.zIndex = -2;

        jQuery('body').prepend(div);
        jQuery('.wrapper').addClass('modal-content');
      } else {
        console.log('Night mode is enabled, but it\'s not evening ( Hour < 18)');
      }
    }

    if ('%TECH_WORKS_BLOCK_VISIBLE%' === '1') {
      jQuery('#tech_works_block').css('display', 'block');
    }

  }());

  jQuery(document).on('ready', function () {
    var successCookie = localStorage.getItem('successCookie');

    if (successCookie != '1') {
      jQuery('#cookieAcceptBar').show();

      var checkVisibleCookie = jQuery('#HIDDE_COOKIE').val();
      jQuery('#cookieAcceptBar').css('display', checkVisibleCookie)
    }
  });

  function hideBanner() {
    var banner = document.getElementById('cookieAcceptBar');

    if (banner.style.display === "none") {
      banner.style.display = "block";
    } else {
      banner.style.display = "none";
      localStorage.setItem('successCookie', 1);
    }
  }

</script>