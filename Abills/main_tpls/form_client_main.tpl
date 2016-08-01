<div class='hidden-xs hidden-sm'>
    <div class='status-line-top'>
        <ul class='nav-justified'>
            <li><label class='control-label'>_{DATE}_:</label> %DATE% %TIME%</li>
            <li><label class='control-label'>_{USER}_:</label> %LOGIN%</li>
            <li><label class='control-label'>IP:</label> %IP%</li>
            <li><label class='control-label'>_{STATE}_:</label> %STATE% <!-- %STATE_CODE% --></li>
        </ul>
    </div>
</div>
<div class='menu-toggle'>
    <a onclick='toggleNavBar()'><span class='glyphicon glyphicon-th-list'></span></a>

    <a role='button' data-toggle='modal' href='#themeSwitcher'>
        <span class='glyphicon glyphicon-eye-open'></span>
    </a>
</div>
<div id='primary' class='bg-primary' style='display: none'></div>

<div class='modal fade' id='themeSwitcher'>
    <div class='modal-dialog' style='z-index : 1041'>
        <div class='modal-content'>
            <div class='modal-header'>
                <button type='button' class='close' data-dismiss='modal' aria-label='Close'><span
                        aria-hidden='true'>&times;</span></button>
            </div>
            <div class='modal-body'>
                <div id='themes-list'>
                    %FORM_COLORS%
                </div>
            </div>
            <div class='modal-footer'>
                <button type='button' class='btn btn-default' data-dismiss='modal'>Close</button>
            </div>
        </div>
        <!-- /.modal-content -->
    </div>
    <!-- /.modal-dialog -->
</div><!-- /.modal -->

<div id='wrapper'>

    <div class='row'>
        <!-- menu -->
        <div id='sidebar-wrapper' class='hidden-print'>
            %MENU%
            <script>showhideMenu();</script>
        </div>
    </div>

    <div id='page-content-wrapper'>
        <div class='hidden-md hidden-lg' style='margin-bottom:3em;'>
            <div class='well'>
                <div class='row'>
                    <div class='col-xs-12 col-sm-6'>
                        <label class='control-label text-muted'>_{DATE}_:</label>
                        <label>%DATE% %TIME%</label>
                    </div>
                    <div class='col-xs-12 col-sm-6'>
                        <label class='control-label text-muted'>_{USER}_:</label>
                        <label>%LOGIN%</label>
                    </div>

                </div>
                <div class='row'>
                    <div class='col-xs-12 col-sm-6'>
                        <label class='control-label text-muted'>IP:</label>
                        <label>%IP%</label>
                    </div>
                    <div class='col-xs-12 col-sm-6'>
                        <label class='control-label text-muted'>_{STATE}_:</label>
                        <label>%STATE%</label> <!-- %STATE_CODE% -->
                    </div>
                </div>
            </div>
        </div>
        %BODY%
    </div>

</div>


