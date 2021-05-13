<FORM action='$SELF_URL' METHOD='POST' name='extfin'>
  <input type='hidden' name='index' value='$index'>

  <div class='card card-primary card-outline form-horizontal'>
  <div class='card-header with-border'>_{EXPORT}_ : _{USERS}_</div>
  <div class='card-body'>
    <div class="form-group">
      <div class="row">
        <div class="col-sm-12 col-md-4">
          <label class='col-md-10 control-label'>_{DATE}_ _{FROM}_</label>
          <div class="input-group">
            %FROM_DATE%
          </div>
        </div>

        <div class="col-sm-12 col-md-4">
          <label class='col-md-10 control-label'>_{DATE}_ _{TO}_</label>
          <div class="input-group">
            %TO_DATE%
          </div>
        </div>

        <div class="col-sm-12 col-md-4">
          <label class='col-md-10 control-label'>_{GROUP}_</label>
          <div class="input-group">
            %GROUP_SEL%
          </div>
        </div>
      </div>
    </div>

    <div class="form-group">
      <div class="row">
        <div class="col-sm-12 col-md-4">
          <label class='col-md-10 control-label'>_{REPORT}_ _{TYPE}_</label>
          <div class="input-group">
            %TYPE_SEL%
          </div>
        </div>

        <div class="col-sm-12 col-md-4">
          <label class='col-md-10 control-label'>_{USER}_ _{TYPE}_</label>
          <div class="input-group">
            %USER_TYPE_SEL%
          </div>
        </div>

        <div class="col-sm-12 col-md-4">
          <label class='col-md-10 control-label'>_{ROWS}_</label>
          <div class="input-group">
            <input type=text class='form-control' name=PAGE_ROWS value='$PAGE_ROWS'>
          </div>
        </div>
      </div>
    </div>

    <div class="form-group">
      <div class="row">
        <div class="col-sm-12 col-md-6">
          <label class='col-md-10 control-label'>_{INFO_FIELDS}_(_{COMPANIES}_)</label>
          <div class="input-group">
            %INFO_FIELDS_COMPANIES%
          </div>
        </div>

        <div class="col-sm-12 col-md-6">
          <label class='col-md-10 control-label'>_{INFO_FIELDS}_(_{USERS}_)</label>
          <div class="input-group">
            %INFO_FIELDS%
          </div>
        </div>
      </div>
    </div>

    <!-- <div class='checkbox'>
      <label>
        <input type='checkbox' name=TOTAL_ONLY value=1><strong>_{TOTAL}_</strong>
      </label>
    </div> -->
  </div>
  <div class='card-footer'>
  <input class='btn btn-primary' type=submit name=%ACTION% value=%ACTION_LNG%>
  </div>
  </div>
</FORM>
