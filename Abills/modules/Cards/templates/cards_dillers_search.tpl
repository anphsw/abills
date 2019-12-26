<form action='$SELF_URL' method='POST' class='form-horizontal no-live-select UNIVERSAL_SEARCH_FORM'
      id='SMALL_SEARCH_FORM'>
    <input type='hidden' name='index' value="%INDEX%">
    <input type='hidden' name='sid' value="%SID%">
    <input type='hidden' name='search_form' value="1">
    <div class="form-group">
        <div class='box box-theme box-form'>
            <div class='box-header with-border'>
                <h3 class="box-title">_{SEARCH}_</h3>
                <div class="box-tools pull-right">
                    <button type="button" class="btn btn-box-tool" data-widget="collapse"><i
                            class="fa fa-minus"></i>
                    </button>
                </div>
            </div>
            <div class='box-body'>
                <div class='form-group'>
                    <label class='control-label col-sm-3 col-md-4'>_{SEARCH_PHRASE}_:</label>
                    <div class='col-sm-9 col-md-8'>
                        <input type='text' name='UNIVERSAL_SEARCH' class='form-control UNIVERSAL_SEARCH'
                               placeholder='_{SEARCH_PHRASE}_...' form='SMALL_SEARCH_FORM'>

                    </div>
                </div>
                <input class='btn btn-primary col-md-12 col-sm-12' type='submit'
                       value='_{SEARCH}_'>
            </div>
        </div>
    </div>
</form>