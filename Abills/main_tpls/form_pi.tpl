<style>
  #_main {
    min-height: 250px;
  }

  #_address {
    min-height: 250px;
  }

  #_comment {
    min-height: 150px;
  }
</style>

<form class='form-horizontal' action='$SELF_URL' name='users_pi' METHOD='POST' ENCTYPE='multipart/form-data'>

  <input type='hidden' name='index' value='$index'>
  %MAIN_USER_TPL%
  <input type=hidden name=UID value='%UID%'>

  <!-- General panel -->
  <div class='panel panel-default '>
    <div class='panel-body'>
      <legend>_{USER_INFO}_</legend>

      <!-- Main info panel -->
      <div class='row'>
        <div class='col-md-6'>
          <div class='panel panel-default panel-form'>
            <div class='panel-heading'>
              <a data-toggle='collapse' data-parent='#accordion' href='#_main'>_{MAIN}_</a>
            </div>
            <div id='_main' class='panel-body panel-collapse collapse in' height=100px>
              <div class='form-group'>
                <label class='control-label col-md-2' for='FIO'>_{FIO}_</label>
                <div class='col-md-10'>
                  <textarea name='FIO' class='form-control' rows='1' id='FIO'>%FIO%</textarea>
                </div>
              </div>

              %ACCEPT_RULES_FORM%

              <div class='form-group'>
                <label class='col-md-2 control-label' for='PHONE'>_{PHONE}_</label>
                <div class='col-md-10'>
                  <input id='PHONE' name='PHONE' value='%PHONE%' placeholder='%PHONE%'
                         class='form-control' type='text'>
                </div>
              </div>

              <div class='form-group'>
                <label class='control-label col-md-3' for='EMAIL'>E-mail (;)</label>
                <div class='col-md-9'>
                  <div class='input-group'>
                    <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%'
                           class='form-control' type='text'>
                    <span class='input-group-addon'>
                    <a href='$SELF_URL?UID=$FORM{UID}&get_index=msgs_admin&add_form=1&SEND_TYPE=1&header=1&full=1'
                       class='glyphicon glyphicon-envelope'></a>
                    </span>
                  </div>
                </div>
              </div>

              <div class='form-group'>
                <label class='control-label col-md-3' for='CONTRACT_ID'>_{CONTRACT_ID}_</label>
                <div class='col-sm-4'>
                  <div class='input-group'>
                    <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%'
                           placeholder='%CONTRACT_ID%' class='form-control' type='text'>
                    <div class='input-group-btn'>
                      <button type='button' class='btn btn-default dropdown-toggle'
                              data-toggle='dropdown'
                              aria-expanded='false'><span class='caret'></span></button>
                      <ul class='dropdown-menu dropdown-menu-right' role='menu'>
                        <li><span class='input-group-addon'>%PRINT_CONTRACT%</span></li>
                        <li><span class='input-group-addon'><a
                            href='$SELF_URL?qindex=15&UID=$FORM{UID}&PRINT_CONTRACT=%CONTRACT_ID%&SEND_EMAIL=1&pdf=1'
                            class='glyphicon glyphicon-envelope' target=_new>
                        </a></span></li>
                      </ul>
                    </div>
                  </div>
                  %CONTRACT_SUFIX%
                </div>
                <label class='control-label col-md-1' for='CONTRACT_DATE'>_{DATE}_</label>
                <div class='col-md-4'>
                  <input id='CONTRACT_DATE' type='text' name='CONTRACT_DATE'
                         value='%CONTRACT_DATE%' class='tcal form-control'>
                </div>
              </div>

              %CONTRACT_TYPE%
            </div>
          </div>
        </div>

        <!-- Address panel -->
        <div class='col-md-6'>
          <div class='panel panel-default panel-form'>
            <div class='panel-heading'>
              <a data-toggle='collapse' data-parent='#accordion' href='#_address'>_{ADDRESS}_</a>
            </div>

            <div id='_address' class='panel-body panel-collapse collapse in'>
              %ADDRESS_TPL%
            </div>
          </div>
        </div>
      </div>
      <!-- Pasport panel -->
      <div class='row'>
        <div class='col-md-6'>
          <div class='panel panel-default panel-form'>
            <div class='panel-heading'>
              <a data-toggle='collapse' data-parent='#accordion' href='#_pasport'>_{PASPORT}_</a>
            </div>
            <div id='_pasport' class='panel-body panel-collapse collapse in'>
              <div class='form-group'>
                <!-- <label class='col-md-12 bg-primary'>_{PASPORT}_</label> -->
                <label class='control-label col-md-2' for='PASPORT_NUM'>_{NUM}_</label>
                <div class='col-sm-4'>
                  <input id='PASPORT_NUM' name='PASPORT_NUM' value='%PASPORT_NUM%'
                         placeholder='%PASPORT_NUM%'
                         class='form-control' type='text'>
                </div>

                <label class='control-label col-md-2' for='PASPORT_DATE'>_{DATE}_</label>
                <div class='col-sm-4'>
                  <input id='PASPORT_DATE' type='text' name='PASPORT_DATE' value='%PASPORT_DATE%'
                         class='tcal form-control'>
                </div>
              </div>
              <div class='form-group'>
                <label class='control-label col-md-2' for='PASPORT_GRANT'>_{GRANT}_</label>
                <div class='col-md-10'>
                    <textarea class='form-control' id='PASPORT_GRANT' name='PASPORT_GRANT'
                              rows='2'>%PASPORT_GRANT%</textarea>
                </div>
              </div>
            </div>
          </div>
        </div>


        <!-- comment panel -->
        <div class='col-md-6'>
          <div class='panel panel-default panel-form'>
            <div class='panel-heading'>
              <a data-toggle='collapse' data-parent='#accordion' href='#_comment'>_{COMMENTS}_</a>
            </div>
            <div id='_comment' class='panel-body panel-collapse collapse in'>
              <div class='form-group'>
                <label class='control-label col-sm-3' for='COMMENTS'>_{COMMENTS}_</label>
                <div class='col-md-9'>
                   <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- info fields + contacts panel -->
      <div class='row'>
        <div class='col-md-6'>
          <div class='panel panel-default panel-form'>
            <div class='panel-heading'>
              <a data-toggle='collapse' data-parent='#accordion' href='#_other'>_{OTHER}_</a>
            </div>
            <div id='_other' class='panel-body panel-collapse collapse in'>
              %INFO_FIELDS%
            </div>
          </div>
        </div>

        <div class='col-md-6' style='display: %SHOW_PRETTY_USER_CONTACTS%'>
          <div class='panel panel-default panel-form'>
            <div class='panel-heading'>
              <a data-toggle='collapse' data-parent='#accordion' href='#contacts_content'>_{CONTACTS}_</a>
            </div>
            <div id='contacts_content' class='panel-body panel-collapse collapse in'>
              %CONTACTS%
            </div>
          </div>
        </div>
      </div>

    </div>
    <div class='panel-footer'>
      <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>


  </div>

</form>

