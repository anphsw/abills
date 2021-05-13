<script src='/styles/default_adm/js/modules/portal.js'></script>

<form action=$SELF_URL name='portal_form' method=POST class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=ID value=%ID%>

  <div class='row'>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'><h4 class='card-title'>%TITLE_NAME%</h4></div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{DATE_PUBLICATE}_:</label>
            <div class='col-md-9'>
              <input class='form-control datepicker' placeholder='0000-00-00' name='DATE' value='%DATE%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{DATE_END_PUBLICATE}_:</label>
            <div class='col-md-9'>
              <input class='form-control datepicker' placeholder='0000-00-00' name='END_DATE' value='%END_DATE%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{MENU}_:</label>
            <div class='col-md-9'>%PORTAL_MENU_ID%</div>
          </div>

          <div class='form-row'><label class='col-md-12 bg-primary'>_{CONTENT}_</label></div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{TITLE}_:</label>
            <div class='col-md-9'>
              <input class='form-control' name='TITLE' type='text' value='%TITLE%' size=90 align=%ALIGN%/>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{SHORT_DESCRIPTION}_:</label>
            <div class='col-md-9'>
              <textarea class='form-control' name='SHORT_DESCRIPTION' cols=90 rows=5>%SHORT_DESCRIPTION%</textarea>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{TEXT}_:</label>
            <div class='col-md-9'>
              <textarea class='form-control' name='CONTENT' cols=90 rows=15 id='news-text'>%CONTENT%</textarea>
              <div class='form-group row' style="margin-top: 5px;">
                <div class='col-md-12' id='editor-controls'>
                  <button type='button' class='btn btn-xs btn-primary' title='Жирный' data-tag='b'>_{BOLD}_</button>
                  <button type='button' class='btn btn-xs btn-primary' title='Курсив' data-tag='i'>_{ITALICS}_</button>
                  <button type='button' class='btn btn-xs btn-primary' title='Подчеркнутый' data-tag='u'>
                    _{UNDERLINED}_
                  </button>
                  <button type='button' class='btn btn-xs btn-primary' title='Жирный' data-tag='link'>_{LINK}_</button>
                </div>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{SHOW}_:</label>
            <div class='col-md-9'>
              <div class='row'>
                <div class='col-md-4'>
                  <div class="custom-control custom-radio">
                    <input class="custom-control-input" type="radio" id="STATUS" name="STATUS" %SHOWED%>
                    <label for="STATUS" class="custom-control-label">_{SHOW}_</label>
                  </div>
                </div>
                <div class='col-md-4'>
                  <div class="custom-control custom-checkbox">
                    <input class="custom-control-input" type="checkbox" id="ON_MAIN_PAGE" name="ON_MAIN_PAGE"
                           value='1' %ON_MAIN_PAGE_CHECKED%>
                    <label for="ON_MAIN_PAGE" class="custom-control-label">_{ON_MAIN_PAGE}_</label>
                  </div>
                </div>
                <div class='col-md-4'>
                  <div class="custom-control custom-radio">
                    <input class="custom-control-input" type="radio" id="STATUS_OFF" name="STATUS" %HIDDEN%>
                    <label for="STATUS_OFF" class="custom-control-label">_{HIDE}_</label>
                  </div>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>


    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'><h4 class='card-title'>_{USER_CONF}_</h4></div>
        <div class='card-body'>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{USER_PORTAL}_:</label>
            <div class='col-md-9'>
              <div class='row'>
                <div class='col-md-6'>
                  <div class="custom-control custom-radio">
                    <input class="custom-control-input" type="radio" id="ARCHIVE" name="ARCHIVE" %SHOWED_ARCHIVE%>
                    <label for="ARCHIVE" class="custom-control-label">_{SHOW}_</label>
                  </div>
                </div>
                <div class='col-md-6'>
                  <div class="custom-control custom-radio">
                    <input class="custom-control-input" type="radio" id="HIDE_ARCHIVE" name="ARCHIVE" %HIDDEN_ARCHIVE%>
                    <label for="HIDE_ARCHIVE" class="custom-control-label">_{TO_ARCHIVE}_</label>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{IMPORTANCE}_:</label>
            <div class='col-md-9'>
              %IMPORTANCE_STATUS%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{GROUPS}_:</label>
            <div class='col-md-9'>
              %GROUPS%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{TAGS}_:</label>
            <div class='col-md-9'>
              %TAGS%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{DOMAINS}_:</label>
            <div class='col-md-9'>
              %DOMAIN_ID%
            </div>
          </div>

          %ADRESS_FORM%

          <div class="form-group custom-control custom-checkbox">
            <input class="custom-control-input" type="checkbox" id="RESET" name="RESET"
                   value='1' %RESET%>
            <label for="RESET" class="custom-control-label">_{RESET_ADDRESS}_</label>
          </div>

        </div>


        <div class='card-footer'>
          <input class='btn btn-primary' type=submit name=%ACTION% value=%ACTION_LNG%>
        </div>

      </div>
    </div>
  </div>
</form>
