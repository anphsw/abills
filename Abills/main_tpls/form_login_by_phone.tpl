<div id='LOGIN_BY_PHONE_CONTAINER' class='d-none'>
  <input type='hidden' name='LOGIN_BY_PHONE' value='1'>

  <div class='form-group' id='MESSAGE_BLOCK'></div>

  <div id='LOGIN_BY_PHONE_INPUT_DATA'>
    <div class='row p-0 m-0'>
      <div class='input-group'>
        <input id='PHONE_PATTERN_FIELD' name='PHONE_PATTERN_FIELD' value='' required
               placeholder='_{PHONE}_' class='form-control' data-phone-field='PHONE'
               data-check-phone-pattern='%PHONE_NUMBER_PATTERN%' type='text' autocomplete='off'>
        <input id='PHONE' name='PHONE' value='' class='form-control' type='hidden'>
        <div class='input-group-append'>
          <div class='input-group-text'>
            <span class='input-group-addon fa fa-phone'></span>
          </div>
        </div>
      </div>
    </div>

    <div class='row p-0 m-0 d-none' id='PIN_BLOCK'>
      <div class='input-group'>
        <input type='text' id='PIN_CODE' name='PIN_CODE' value='' class='form-control' placeholder='Pin'
               autocomplete='off'>
        <div class='input-group-append'>
          <div class='input-group-text'>
            <span class='input-group-addon fa fa-key'></span>
          </div>
        </div>
      </div>
    </div>

    <div class='row p-0 m-0'>
      <span class='w-100 text-muted' id='timerShow'></span>
    </div>

    <button class='btn btn-primary d-none' name='CONFIRM_PIN' id='CONFIRM_PIN'>_{CONFIRM}_ PIN</button>
    <button class='btn btn-primary' name='SEND_PIN' id='SEND_PIN'>_{SEND}_</button>
    <button class='btn btn-primary' name='EXIST_PIN' id='EXIST_PIN'>_{ALREADY_HAVE_A_PIN}_</button>
  </div>
  <button class='btn btn-default' name='BACK_TO_LOGIN' id='BACK_TO_LOGIN'>_{BACK_TO_LOGIN_WITH_PASSWORD}_</button>
</div>

<script>

  jQuery('#LOGIN_BY_PHONE').on('click', function (e) {
    e.preventDefault();

    jQuery('#MAIN_CONTAINER').addClass('d-none');
    jQuery('#LOGIN_BY_PHONE_CONTAINER').removeClass('d-none');
  })

  jQuery('#BACK_TO_LOGIN').on('click', function () {
    jQuery('#MAIN_CONTAINER').removeClass('d-none');
    jQuery('#LOGIN_BY_PHONE_CONTAINER').addClass('d-none');
  })

  let event = document.createEvent('Event');
  event.initEvent('input', true, true);
  document.getElementById('PHONE').dispatchEvent(event);

  // TODO: make dynamic load of lang keys or use errmsg from server when will be added
  let loginPhoneMessages = {
    USED_ALL_PIN_ATTEMPTS: '_{USED_ALL_PIN_ATTEMPTS}_',
    CODE_IS_INVALID: '_{CODE_IS_INVALID}_',
    USER_NOT_FOUND: '_{USER_NOT_FOUND}_',
    CODE_EXPIRED: '_{CODE_EXPIRED}_',
    EXCEEDED_SMS_LIMIT: '_{EXCEEDED_SMS_LIMIT}_',
    ERR_SEND_SMS: '_{ERR_SEND_SMS}_',
  };

  let canSendPin = true;
  let uid = 0;
  let authCode = 0;
  let startTimeSeconds = 120;
  let timeSeconds = startTimeSeconds;
  let phone = '--';

  jQuery('#SEND_PIN').on('click', sendPin);

  jQuery('#EXIST_PIN').on('click', function (e) {
    jQuery('#MESSAGE_BLOCK').html('');
    jQuery('#PIN_CODE').val('');
    jQuery('#timerShow').html('');
    e.preventDefault();

    canSendPin = false;
    phone = jQuery('#PHONE').val().replace(/\D/g, '');
    sendRequest(`/api.cgi/user/login/`, { phone, pinAlreadyExists: 1 }, 'POST').then(result => {
      if (!result?.errno) {
        jQuery('#PIN_BLOCK').removeClass('d-none');
        jQuery('#CONFIRM_PIN').removeClass('d-none');
        jQuery('#EXIST_PIN').addClass('d-none');
      } else {
        jQuery('#MESSAGE_BLOCK').html(jQuery(`<div class='alert alert-danger'>${loginPhoneMessages[result?.errstr] || result?.errstr}</div>`));
      }
      canSendPin = true;
    });
  });

  jQuery('#CONFIRM_PIN').on('click', function (e) {
    e.preventDefault();

    sendRequest(`/api.cgi/user/login/`, {
      authCode,
      pinCode: jQuery('#PIN_CODE').val() || '--',
    }, 'POST').then(result => {
      if (result?.users) {
        loginButtons(result.users);
      } else if (result?.sid) {
        window.location.replace(`/index.cgi?sid=${result?.sid}`);
      } else {
        jQuery('#MESSAGE_BLOCK').html(jQuery(`<div class='alert alert-danger'>${loginPhoneMessages[result?.errstr] || result?.errstr}</div>`));
      }
    });
  });

  function loginButtons(users) {
    let loginsContainer = document.getElementById('MESSAGE_BLOCK');

    let message = document.createElement('div');
    message.classList.add('alert');
    message.classList.add('alert-info');
    message.innerText = '_{FOUND_SEVERAL_USERS}_';
    loginsContainer.appendChild(message);

    users.forEach(user => {
      let button = document.createElement('button');
      button.textContent = user?.login;
      button.classList.add('btn');
      button.classList.add('btn-primary');

      button.addEventListener('click', (e) => {
        e.preventDefault();

        sendRequest(`/api.cgi/user/login/`, {
          authCode,
          pinCode: jQuery('#PIN_CODE').val() || '--',
          uid: user?.uid || '--'
        }, 'POST').then(result => {
          if (result?.sid) {
            window.location.replace(`/index.cgi?sid=${result?.sid}`);
          } else {
            jQuery('#MESSAGE_BLOCK').html(jQuery(`<div class='alert alert-danger'>${loginPhoneMessages[result?.errstr] || result?.errstr}</div>`));
          }
        });
      })

      loginsContainer.appendChild(button);
    });

    document.getElementById('LOGIN_BY_PHONE_INPUT_DATA').classList.add('d-none');
  }

  function sendPin(e) {
    jQuery('#MESSAGE_BLOCK').html('');
    jQuery('#PIN_CODE').val('');
    jQuery('#timerShow').html('');
    e.preventDefault();

    if (!canSendPin) return;
    phone = jQuery('#PHONE').val().replace(/\D/g, '') || '--';

    sendRequest(`/api.cgi/user/login/`, { phone }, 'POST').then(result => {
      if (!result?.errno) {
        let timer = setInterval(function () {
          let seconds = timeSeconds % 60
          let minutes = timeSeconds / 60 % 60
          if (timeSeconds <= 0) {
            clearInterval(timer);
            jQuery('#timerShow').html(jQuery(`<button class='btn btn-xs btn-default' id='SEND_PIN_AGAIN'>_{SEND_AGAIN}_</button>`));
            canSendPin = true;
            timeSeconds = startTimeSeconds;
            jQuery('#SEND_PIN_AGAIN').on('click', sendPin);
          } else {
            jQuery('#timerShow').html(`_{SEND_AGAIN}_... ${('0' + Math.trunc(minutes)).slice(-2)}:${('0' + seconds).slice(-2)}`);
          }
          --timeSeconds;
        }, 1000)

        uid = result?.authCode;
        authCode = result?.authCode;
        jQuery('#PIN_BLOCK').removeClass('d-none');
        jQuery('#CONFIRM_PIN').removeClass('d-none');
        jQuery('#SEND_PIN').addClass('d-none');
        canSendPin = false;
      } else {
        jQuery('#MESSAGE_BLOCK').html(jQuery(`<div class='alert alert-danger'>${loginPhoneMessages[result?.errstr] || result?.errstr}</div>`));
      }
    });
  }
</script>
