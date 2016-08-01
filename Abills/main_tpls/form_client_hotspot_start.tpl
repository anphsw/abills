<!DOCTYPE html>
<html lang='ru'>
<head>
  %REFRESH%
  <META HTTP-EQUIV='Cache-Control' content='no-cache,no-cache,no-store,must-revalidate'/>
  <META HTTP-EQUIV='Expires' CONTENT='-1'/>
  <META HTTP-EQUIV='Pragma' CONTENT='no-cache'/>
  <META HTTP-EQUIV='Content-Type' CONTENT='text/html; charset=%CHARSET%'/>
  <META name='Author' content='~AsmodeuS~'/>
  <META HTTP-EQUIV='content-language' content='%CONTENT_LANGUAGE%'/>

  <meta name="viewport" content="width=device-width, initial-scale=1">

  <!-- Bootstrap -->
  <link href='/styles/default_adm/css/bootstrap.min.css' rel='stylesheet'>
  <link href='/styles/default_adm/colors/Bootstrap3.css' rel='stylesheet'>

  <script src='/styles/default_adm/js/jquery.min.js'></script>
  <script src='/styles/default_adm/js/bootstrap.min.js'></script>
</head>
<body>
<script type='text/javascript'>
  jQuery(function () {
    jQuery('#dropdown_language').find('ul li').on('click', function () {
      var lang_ = jQuery(this).find('img').attr('alt') || 'russian';
      selectLanguage(lang_);
    });
  });

  function selectLanguage(language) {
    location.replace('$SELF_URL?NAS_ID=&DOMAIN_ID=&language=' + language);
  }

  function getFlagItem(langName) {
    return '<li><img src=\'/styles/default_adm/img/flags/' + langName + '.png\'  alt=\'' + langName + '\' /> ' + getShorted(langName).toUpperCase() + ' </li>';
  }

  function getShorted(langName) {
    return langName[0] + langName[1];
  }

  var langs_array = ('%LANGS_ARRAY%').split(', ');
  var language_current = '%LANG_CURRENT%' || '';

  var lang_list = '';
  for (var i = 0; i < langs_array.length; i = i + 2) {
    lang_list += getFlagItem(langs_array[i].trim());
  }

  //language_current is printed in start.cgi
  lang_active = '<img src=\'/styles/default_adm/img/flags/' + language_current + '.png\'  alt=\'' + language_current + '\' />';
</script>


<style>
  #dropdown_language ul {
    width: 60px;
    min-width: 60px !important;
    max-width: 60px !important;

    margin-left: -30px;
  }

  #dropdown_language ul li {
    display: inline-block;
    width: 70px;
    min-width: 70px !important;
    max-width: 70px !important;

    padding: 5px 10px;
  }

  .top-margin {
    margin-top: 5px;

  }

  .inline {
    padding-top: 5px;
    padding-bottom: auto;
  }

  .panel-heading {
    font-size: 10px;
    color: red;
  }


</style>

<div class='container'>


  <div class='row'>
    <div class='center-block'>
      <div class='panel panel-form panel-default' style='text-align:center'>
        <div class='panel-heading'>
          <div class='row '>
            <div class='col-md-1 col-xs-2 col-sm-1 col-lg-1'>
            </div>
            <div class='col-md-10 col-xs-8 col-sm-10 col-lg-10'>
              <h3 style='margin:0px' class='brand brand-primary'>
                <b>
                  <font color=red>A</font>BillSpot Start page
                </b>
              </h3>
            </div>
            <div class='col-md-1 col-xs-2 col-sm-1 col-lg-1' align='left'>
              <ul class='nav nav-pills'>
                <li class='dropdown' id='dropdown_language'>
                  <a class='dropdown-toggle' data-toggle='dropdown' data-target='#dropdown_language'>
                    <script>document.write(lang_active);</script>
                  </a>
                  <ul class='dropdown-menu'>
                    <script>document.write(lang_list);</script>
                  </ul>
                </li>
              </ul>
            </div><!-- end of col-md-1 -->
          </div> <!-- end of row -->
        </div> <!-- end of panel-heading -->
        <div class='panel-body'>
          <!-- <p>Domain ID: %DOMAIN_ID% Domain name: %DOMAIN_NAME%</p> -->
          <div class='row center-block'>
            <a class='btn btn-success btn-lg' href='%LOGIN_URL%'>_{LOGIN_IN_TO_HOTSPOT}_</a>
            <a class='btn btn-default top-margin' href='$SELF_URL?GUEST_ACCOUNT=1&DOMAIN_ID=%DOMAIN_ID%%PAGE_QS%'>_{GUEST_ACCOUNT}_</a>
          </div>
          %ADDRESS_STREET% %ADDRESS_BUILD% %ADDRESS_FLAT%
        </div> <!-- END OF PANEL-BODY -->
      </div> <!-- END OF PANEL -->
    </div>
  </div>

  <div class='row'>
    <div class='center-block'>
      <div class='panel panel-default' style='text-align:center'>
        <div class='panel-heading'>
          <h3 style='margin:0'> _{ICARDS}_ _{INFO}_ </h3>
        </div>
        <div class='panel-body'>

          <div class='row'>
            <div class='col-hidden-xs col-sm-3 col-md-3 col-lg-3'></div>
            <div class='col-xs-12 col-sm-12 col-md-6 col-lg-6'>
              <form action=$SELF_URL>
                <input type=hidden name=DOMAIN_ID value=%DOMAIN_ID%>
                <input type=hidden name=NAS_ID value=%NAS_ID%>
                <input type=hidden name=language value=$FORM{language}>

                <div class='col-xs-12 col-sm-1 col-md-1 col-lg-1 '>
                  <label for='PIN' style='margin-top: 10px'>PIN:</label>
                </div>


                <div class=' col-xs-12 col-sm-8 col-md-8 col-lg-8'>
                  <input class='form-control top-margin' type='text' name=PIN id='PIN' value=''>
                </div>


                <div class=' col-xs-12 col-sm-3 col-md-3 col-lg-3'>
                  <input class='form-input btn btn-default top-margin' type='submit' value='_{INFO}_'>
                </div>

              </form>
            </div>
            <div class='col-hidden-xs col-sm-3 col-md-3 col-lg-3'></div>
          </div>

        </div>
      </div>
    </div>
  </div>

  <div class='row'>
    <div class='panel panel-default'>
      <div class='panel-heading' style='text-align:center'>
        <h3 style='margin:0'>_{ICARDS}_</h3>
      </div>
      <div class='panel-body'>

        %CARDS_TYPE%

      </div>
    </div>
  </div>

  %SELL_POINTS%

</div> <!--END OF CONTAINER-->
</body>
</html>
