<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <meta http-equiv='X-UA-Compatible' content='IE=edge'>

    <meta HTTP-EQUIV='Cache-Control' content='no-cache,no-cache,no-store,must-revalidate,private, max-age=5'/>
    <meta HTTP-EQUIV='Expires' CONTENT='-1'/>
    <meta HTTP-EQUIV='Pragma' CONTENT='no-cache'/>
    <meta HTTP-EQUIV='Content-Type' CONTENT='text/html; charset=%CHARSET%'/>
    <meta HTTP-EQUIV='Content-Language' content='%CONTENT_LANGUAGE%'/>
    <meta name='Author' content='~AsmodeuS~'/>

    <title>%TITLE%</title>
    <!-- Bootstrap -->
    <link href='/styles/%HTML_STYLE%/css/bootstrap.min.css' rel='stylesheet'>
    <link rel="stylesheet" href="/styles/%HTML_STYLE%/css/font-awesome.min.css">

    <!-- Custom <select> design -->
    <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/chosen.min.css'>
    <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/tcal.css'>
    <!-- Currencies -->
    <link href='/styles/%HTML_STYLE%/css/currencies.css' rel='stylesheet'>


    <!-- Cookies from JavaScript -->
    <script src='/styles/%HTML_STYLE%/js/jquery.min.js'></script>
    <script type='text/javascript' src='/styles/%HTML_STYLE%/js/js.cookies.js'></script>
    <script src='/styles/%HTML_STYLE%/js/bootstrap.min.js'></script>
    <script type='text/javascript' src='/styles/%HTML_STYLE%/js/functions.js'></script>
    <script type='text/javascript' src='/styles/%HTML_STYLE%/js/permanent_data.js'></script>
    <script type='text/javascript' src='/styles/%HTML_STYLE%/js/functions-client.js'></script>
    <script type='text/javascript'>
        getTheme();
    </script>
    <link href='/styles/%HTML_STYLE%/css/client.css' rel='stylesheet'>
    <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/jquery.arcticmodal-0.3.css'>

    <script type='text/javascript' src='/styles/%HTML_STYLE%/js/dynamicForms.js'></script>
    <!-- client specific logic and view-->
    <script type='text/javascript' src='/styles/%HTML_STYLE%/js/keys.js'></script>
    <script type='text/javascript' src='/styles/%HTML_STYLE%/js/QBinfo.js'></script>
    <script type='text/javascript' src='/styles/%HTML_STYLE%/js/events.js'></script>

    <script type='text/javascript' src='/styles/default_adm/js/messageChecker.js'></script>


    <!-- temp -->
    <!--<script src='/styles/%HTML_STYLE%/js/functions.js' type='text/javascript' language='javascript'></script>-->

    <!-- Navigation bar saving show/hide state -->
    <script src='/styles/%HTML_STYLE%/js/navBarCollapse.js' type='text/javascript' language='javascript'></script>


    <script type='text/javascript' src='/styles/%HTML_STYLE%/js/chosen.jquery.min.js'></script>

    <!-- Custom calendar -->
    <script type='text/javascript' src='/styles/%HTML_STYLE%/js/tcal.js'></script>

    <!-- Modal popup windows management -->
    <script type='text/javascript' src='/styles/%HTML_STYLE%/js/modals.js'></script>

    <script>
        var SELF_URL = '$SELF_URL';
        var NO_DESIGN = '$FORM{NO_DESIGN}';
    </script>

</head>
<div id='comments_add' class='modal fade' tabindex='-1' role='dialog'>
    <form id='mForm'>
        <div class='modal-dialog modal-sm'>
            <div class='modal-content'>
                <div id='mHeader' class='modal-header'>
                    <button type='button' class='close' data-dismiss='modal' aria-hidden='true'>&times;</button>
                    <h4 id='mTitle' class='modal-title'></h4>
                </div>
                <div class='modal-body'>
                    <div class='row'>
                        <input type='text' class='form-control' id='mInput' placeholder='_{COMMENTS}_'>
                    </div>
                </div>
                <div class='modal-footer'>
                    <button type='button' class='btn btn-default' data-dismiss='modal'>_{CANCEL}_</button>
                    <button type='submit' class='btn btn-danger danger' id='mButton'>_{EXECUTE}_!</button>
                </div>
            </div>
        </div>
    </form>
    <script>
        var _COMMENTS_PLEASE = '_{COMMENTS_PLEASE}_' || 'Comment please';
        var CHOSEN_PARAMS = {
            no_results_text: '_{NOT_EXIST}_',
            allow_single_deselect: true,
            placeholder_text: '--'
        };

        jQuery(function () {
            var EVENT_PARAMS = {
                portal: 'client',
                link: "/index.cgi?qindex=100002",
                disabled: ('$conf{USER_PORTAL_EVENTS_DISABLED}' === '1'),
                interval: 30000
            };

            AMessageChecker.start(EVENT_PARAMS);
        });


    </script>
</div>