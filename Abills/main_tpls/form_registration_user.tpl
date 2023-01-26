<style>
  .input-group {
    margin-bottom: 15px;
  }
</style>

<link rel='stylesheet' type='text/css' href='/styles/default/css/social_button.css'>

<div class='login-box card card-outline card-primary' style='margin: 7% auto;'>
  <div class='mb-0 login-logo card-header text-center'>
    <b><a href='/' class='h1'><img src=''><span style='color: red;'>A</span>BillS</a></b>
  </div>
  <div class='card-body'>
    <p class='login-box-msg h5 text-muted'>_{REGISTRATION}_</p>
    <div class='col-xs-12'>
      %ERROR_MESSAGE%
    </div>

    <div id='MAIN_CONTAINER'>
      <form action='$SELF_URL' METHOD='post' name='form_registration' id='form_registration'>
        <input type='hidden' name='PIN_CONFIRM_FORM' value='1'>
        <input type='hidden' name='REFERRER' value='%REFERRER%'>
        <div class='form-group row p-0 m-0'>
          <div class='input-group'>
            <input required type='text' id='LOGIN' name='LOGIN' value='%LOGIN%' class='form-control' placeholder='_{LOGIN}_'
                   autocomplete='off' data-check-for-pattern='%LOGIN_PATTERN%' maxlength='%LOGIN_MAX_LENGTH%'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fa fa-user'></span>
              </div>
            </div>
          </div>
        </div>

        <div class='form-group row p-0 m-0'>
          <div class='input-group'>
            <input required type='text' id='FIO' name='FIO' value='%FIO%' class='form-control' placeholder='_{FIO}_'
                   autocomplete='off'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fas fa-id-card'></span>
              </div>
            </div>
          </div>
        </div>

        <div class='form-group row p-0 m-0'>
          <div class='input-group'>
            <input required type='email' id='EMAIL' name='EMAIL' value='%EMAIL%' class='form-control'
                   placeholder='E-mail' autocomplete='off'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fas fa-envelope'></span>
              </div>
            </div>
          </div>
        </div>

        <div %HIDDEN_PHONE% class='row p-0 m-0'>
          <div class='input-group'>
            <input id='PHONE_PATTERN_FIELD' name='PHONE_PATTERN_FIELD' value='%PHONE_PATTERN_FIELD%' %REQUIRED_PHONE%
                   placeholder='_{PHONE}_' class='form-control' data-phone-field='PHONE'
                   data-check-phone-pattern='%PHONE_NUMBER_PATTERN%' type='text' autocomplete='off'>
            <input id='PHONE' name='PHONE' value='' class='form-control' type='hidden'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fas fa-phone'></span>
              </div>
            </div>
          </div>
        </div>

        <div %HIDDEN_USER_IP% class='row p-0 m-0'>
          <div class='input-group'>
            <input id='USER_IP' name='USER_IP' value='%USER_IP%' class='form-control'
                   placeholder='IP' autocomplete='off'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fas fa-map-marker'></span>
              </div>
            </div>
          </div>
        </div>

        <div %HIDDEN_PASS% class='row p-0 m-0'>
          <div class='input-group'>
            <input %REQUIRED_PASS% type='password' id='newpassword' name='newpassword' value='%newpassword%' class='form-control'
                   placeholder='_{PASSWD}_' autocomplete='off' data-check-for-pattern='%PASSWORD_PATTERN%' minlength='%PASSWORD_MIN_LENGTH%'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fas fa-lock'></span>
              </div>
            </div>
          </div>
        </div>

        <div %HIDDEN_PASS% class='row p-0 m-0'>
          <div class='input-group'>
            <input %REQUIRED_PASS% type='password' id='confirm' name='confirm' value='%confirm%' class='form-control'
                   placeholder='_{CONFIRM_PASSWD}_' autocomplete='off' data-check-for-pattern='%PASSWORD_PATTERN%' minlength='%PASSWORD_MIN_LENGTH%'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fas fa-lock'></span>
              </div>
            </div>
          </div>
        </div>

        <div class='row p-0 m-0'>
          <button style='font-size: 1.1rem !important;' type='submit' name='REGISTRATION' value='1'
            class='btn rounded btn-primary btn-block g-recaptcha'
            onclick='set_referrer()' %CAPTCHA_BTN%
          >
            _{REGISTRATION}_
          </button>
        </div>
      </form>

      <a href='/'>_{AUTH}_</a>
      <a data-visible='%PASSWORD_RECOVERY%' style='display: none; float: right' href='/registration.cgi?FORGOT_PASSWD=1'>_{FORGOT_PASSWORD}_</a>
      <br/>

      <div class='row row p-0 m-0'>
        <div class='col-md-12'>
          <a href='%GOOGLE%' class='google btn' style='%AUTH_GOOGLE_ID%;'>
            <img src='/styles/default/img/social/google.png' style='max-width: 15px;margin-right: 2px' alt='google'> _{SIGN_UP_WITH}_ Google
          </a>
          <a href='%FACEBOOK%' class='fb btn' style='%AUTH_FACEBOOK_ID%;'>
            <i class='fab fa-facebook fa-fw'></i> _{SIGN_UP_WITH}_ Facebook
          </a>
          <a href='%APPLE%' class='apple btn' style='%AUTH_APPLE_ID%;'>
            <i class='fab fa-apple fa-fw'></i> _{SIGN_UP_WITH}_ Apple
          </a>
        </div>
      </div>
    </div>
  </div>
</div>

%CAPTCHA%
