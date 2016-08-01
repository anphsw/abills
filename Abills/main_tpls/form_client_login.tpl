<script>
  function selectLanguage() {
    var sLanguage = jQuery('#language').val() || '';
    var sLocation = '$SELF_URL?DOMAIN_ID=$FORM{DOMAIN_ID}&language=' + sLanguage;
    location.replace(sLocation);
  }

  function set_referrer() {
    document.getElementById('REFERER').value = location.href;
  }

  /* Geolocation */
  jQuery(function () {
    var GEOLOCATION_ACTIVE = '$conf{CLIENT_LOGIN_GEOLOCATION}' || false;

    if (GEOLOCATION_ACTIVE) {
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


    // Night mode for login screen
    var NIGHT_MODE_ON = '$conf{CLIENT_LOGIN_NIGHTMODE}' || false;

    if (NIGHT_MODE_ON) {
      var D = new Date(), Hour = D.getHours();
      if (Hour >= 18) {
        var div       = document.createElement('div');
        div.className = "modal-backdrop";
        document.body.appendChild(div);
        jQuery('.center-block').addClass('modal-content');
      }
      else {
        console.log('Something goes wrong');
      }
    }
  });

</script>
<style>
    body {
        background-size:cover;
        background: url(%BACK_IMG%) no-repeat fixed;
    }
    .container {
        padding-top: 4em;
    }

    #language {
        max-width: inherit !important;
    }

    #login_panel {
        width: 80%;
        margin-top: 5vh;
        border-radius: 15px;
        z-index:9999;
    }

    #login_btn {
        height: 100%;
        width: 100%;
        border-radius: 0 0 15px 15px;
    }

    .panel-heading {
        border-top-left-radius: 15px;
        border-top-right-radius: 15px;
    }

    .panel-footer {
        padding: 0;
        border-radius: 15px;
    }

    .modal-backdrop{
        opacity:0.7;
        z-index:100;
    }

</style>

<form action='$SELF_URL' METHOD='post' name='form_login' id='form_login' class='form form-horizontal'>
    <input type='hidden' name='DOMAIN_ID' value='$FORM{DOMAIN_ID}'>
    <input type='hidden' ID='REFERER' name='REFERER' value='$FORM{REFERER}'>
    <input type='hidden' id='location_x' name='coord_x'>
    <input type='hidden' id='location_y' name='coord_y'>

    <div class='col-md-push-3 col-xs-12 col-sm-12 col-md-6 col-lg-6'>
        <div class='panel panel-info center-block' id='login_panel'>
            <div class='panel-heading text-center'>
                <h4> %TITLE% </h4>
            </div>
            <div class='panel-body'>
                <div class='form-group'>
                    <label class='control-label col-md-4'>_{LANGUAGE}_:</label>

                    <div class='col-md-8'>
                        %SEL_LANGUAGE%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-4' for='user'>_{USER}_:</label>

                    <div class='col-md-8'>
                        <div class='input-group'>
                            <span class='input-group-addon'><span class='glyphicon glyphicon-user'></span></span>
                            <input id='user' name='user' value='%user%' placeholder='_{USER}_' class='form-control'
                                   type='text'>
                        </div>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-4' for='passwd'>_{PASSWD}_:</label>

                    <div class='col-md-8'>
                        <div class='input-group'>
                            <span class='input-group-addon'><span class='glyphicon glyphicon-lock'></span></span>
                            <input id='passwd' name='passwd' value='%password%' placeholder='_{PASSWD}_'
                                   class='form-control' type='password'>
                        </div>
                    </div>
                </div>
            </div>

            <div class='panel-footer text-center'>
                <input class='btn btn-lg btn-success' id='login_btn' type='submit' name='logined' value='_{ENTER}_'
                       onclick='set_referrer()'>
            </div>

        </div>
        <!--Block for social networks buttons-->
        <div class='form-group text-center'>
          <link rel='stylesheet' href='/styles/default_adm/css/client_social_icons.css'>
          <ul class='social-network social-circle'>
            %SOCIAL_AUTH_BLOCK%
          </ul>
        </div>
    </div>


</form>