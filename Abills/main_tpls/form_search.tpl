%SEL_TYPE%


<form action='$SELF_URL' METHOD='GET' name='form_search' id='form_search' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='search_form' value='1'>

    <fieldset>

        <button class='btn btn-primary btn-block' type='submit' name='search' value=1>
            <i class='glyphicon glyphicon-search'></i> _{SEARCH}_
        </button>

        <div class='row' style='z-index: 999'>
            <div class='col-xs-12 col-sm-6 col-md-6'>
                <div class='panel panel-default'>
                    <div class='panel-heading'>
                        _{USER}_
                    </div>

                    <div class='panel-body'>

                        <div class='form-group'>
                            <label class='control-label col-md-3' for='LOGIN'>_{LOGIN}_ (*,)</label>

                            <div class='col-md-4'>
                                <input id='LOGIN' name='LOGIN' value='%LOGIN%' placeholder='%LOGIN%'
                                       class='form-control' type='text'>
                            </div>

                            <label class='control-label col-md-2' for='PAGE_ROWS'>_{ROWS}_</label>

                            <div class='col-md-3'>
                                <input id='PAGE_ROWS' name='PAGE_ROWS' value='%PAGE_ROWS%' placeholder='$PAGE_ROWS'
                                       class='form-control' type='text'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3' for='FROM_DATE'>_{PERIOD}_</label>

                            <div class='col-md-4'>
                                %FROM_DATE%
                            </div>
                            <div class='col-md-1'> -
                            </div>
                            <div class='col-md-4'>
                                %TO_DATE%
                            </div>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3' for='TAGS'>_{TAGS}_</label>
                            <div class='col-md-8'>
                                %TAGS_SEL%
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class='col-xs-12 col-sm-6 col-md-6' style='padding-left: 0'>
                %ADDRESS_FORM%
            </div>

        </div>

        <div class='col-md-12' id='search_form'>

            <table>

                %SEARCH_FORM%

            </table>
        </div>

        <button class='btn btn-primary btn-block' type='submit' name='search' value=1>
            <i class='glyphicon glyphicon-search'></i> _{SEARCH}_
        </button>

    </fieldset>
</form>

