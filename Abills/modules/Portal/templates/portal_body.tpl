<!DOCTYPE html>
<html>
<head>
    <meta http-equiv='Content-Type' content='text/html; charset=utf-8'/>
    <link href='/styles/default_adm/css/font-awesome.min.css' rel='stylesheet'>
    <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/bootstrap.min.css'>
    <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/bootstrap-theme.min.css'>
    <script src='/styles/%HTML_STYLE%/js/jquery.min.js'></script>
    <script src='/styles/%HTML_STYLE%/js/bootstrap.min.js'></script>
    <script type='text/javascript'>
      function selectLanguage() {
          var sLanguage = jQuery('#language').val() || '';
          var sLocation = '$SELF_URL?DOMAIN_ID=$FORM{DOMAIN_ID}&language=' + sLanguage;
          document.location.replace(sLocation);
      }
      function set_referrer() {
          document.getElementById('REFERER').value = location.href;
      }
    </script>
    <script>
    \$(document).ready(function(){
      // Show the Modal on load
      if('%WRONG_PASSWD_CHECK%' == 1){
        console.log('HELLO WORLD');
        \$('#login_form').modal('show');
      }
    });
    </script>

    <title>$conf{WEB_TITLE} - Portal</title>


    <style>
        .brand-logo {
            padding: 2px;
            margin-right: 4em;
        }

        .login-button {
            margin: 5px 5px;
        }

        .modal-header-primary {
            color: #fff;
            padding: 9px 15px;
            border-bottom: 1px solid #eee;
            background-color: #428bca;
            border-top-left-radius: 5px;
            border-top-right-radius: 5px;
        }
    </style>
</head>
<body>
<div id='login_form' class='modal fade' role='dialog'>
    <form method='post' class='form form-horizontal' id='form_login'
          action='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi'>

        <div class='modal-dialog'>
            <div class='modal-content'>

                <div class='modal-header modal-header-primary text-center'>
                    <button type='button' class='close' data-dismiss='modal' aria-label='Close'>
                        <span aria-hidden='true'>&times;</span>
                    </button>
                    <label class='control-label'><h3>_{SIGN_IN}_</h3></label>
                </div>
                <div class='row'>
                    <div class='modal-body'>
                        <div class='col-md-12 text-center'>%WRONG_PASSWD%</div>
                        <div class='col-md-12 '>

                            <div class='form-group'>
                            <label class='control-label col-md-3' for='user'>_{LANGUAGE}_</label>

                            <div class='col-md-9'>
                             %SEL_LANGUAGE%
                            </div>
                            </div>
                            <div class='form-group'>
                                <label class='col-md-3 control-label' for='user'>_{LOGIN}_</label>
                                <div class='col-md-9'>
                                    <input class='form-control' id='user' name='user'
                                           onfocus='this.value=\"\"' type='text'/>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='col-md-3 control-label' for='passwd'>_{PASSWD}_</label>
                                <div class='col-md-9'>
                                    <input class='form-control' id='passwd' name='passwd'
                                           onfocus='this.value=\"\"' type='password'/>
                                </div>

                            </div>
                        </div>
                        <div class='form-group text-center'>
                            <link rel='stylesheet' href='/styles/default_adm/css/client_social_icons.css'>
                            <ul class='social-network social-circle'>
                             %SOCIAL_AUTH_BLOCK%
                            </ul>
                        </div>
                    </div>
                </div>
                <div class='modal-footer'>
                    <a href='registration.cgi?FORGOT_PASSWD=1' target='_blank'>_{FORGOT_PASSWORD}_?</a>
                    <input type='submit' class='btn btn-primary' value='_{ENTER}_'/>
                </div>

            </div>
        </div>

    </form>
</div>

<div class='container'>
    <div id='topPan'>

        <nav class='navbar navbar-default'>
            <div class='navbar-header'>
                <div id='ImgPan'>
                    <a href='$SELF_URL'>
                        <!-- #TODO: custom logo image-->
                        <img src='/styles/default_adm/img/portal/abills_logo_tp.png'
                             class='brand-logo navbar-brand' title='_{ON_MAIN_PAGE}_'
                             alt='_{ON_MAIN_PAGE}_'
                             width='79' height='46'
                        />
                    </a>
                </div>

            </div>
            <ul class='nav navbar-nav'>
                %MENU%
            </ul>

            <div class='pull-right'>
                <!-- <a class='btn btn-primary btn-lg' href='registration.cgi?' target='_blank'>_{REGISTRATION}_</a> -->%REGISTRATION%
                <button class='btn btn-info btn-lg login-button' data-toggle='modal' data-target='#login_form'>
                    _{USER_PORTAL}_
                </button>
            </div>
        </nav>

    </div>

    <div id='bodyPan'>
        %CONTENT%
    </div>

    <div id='bodyMiddlePan'>
    </div>

    <div id='footermainPan'>
        <div id='footerPan'>
        </div>
    </div>

</div>

</body>
</html>
