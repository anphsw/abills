<div class='panel panel-default'>
    <div class='panel-body' id='ADD_CUSTOM_POINT_PANEL_BODY'>
        <form action='$SELF_URL' class='form form-horizontal' id='ADD_CUSTOM_POINT_FORM'>

            <input type='hidden' name='COORDX' value='%COORDX%' />
            <input type='hidden' name='COORDY' value='%COORDY%' />
            <input type='hidden' name='get_index' value='maps_show_custom_point_form' />
            <input type='hidden' name='header' value='2' />
            <input type='hidden' name='add' value='1' />


            <div class='form-group'>
                <label class='control-label col-md-3 required' for='NAME'>_{NAME}_</label>
                <div class='col-md-9'>
                    <input class='form-control' name='NAME' id='NAME' required/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_</label>
                <div class='col-md-9'>
                    <textarea class='form-control' rows='3' name='COMMENTS' id='COMMENTS'></textarea>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3' for='TYPE_ID'>_{TYPE}_</label>
                <div class='col-md-6' id='TYPE_ID_SELECT_WRAPPER'>
                    <select class='form-control' name='TYPE_ID' id='TYPE_ID' required></select>
                </div>
                <div class='col-md-3 btn-group btn-group-sm'>
                    <a href='%TYPES_PAGE_HREF%' class='btn btn-sm btn-default' target='_blank'>
                        <span class='glyphicon glyphicon-list'></span>
                    </a>
                    <button class='btn btn-sm btn-success' id='ADD_CUSTOM_POINT_REFRESH_BUTTON'>
                        <span class='glyphicon glyphicon-refresh'></span>
                    </button>
                </div>
            </div>
        </form>
    </div>

    <div class='panel-footer text-right'>
        <input type='submit' class='btn btn-primary' form='ADD_CUSTOM_POINT_FORM' id='ADD_CUSTOM_POINT_SUBMIT' name='action' value='_{ADD}_'/>
    </div>
</div>

<script>
    var _body = jQuery('#ADD_CUSTOM_POINT_PANEL_BODY');
    var _form = jQuery('#ADD_CUSTOM_POINT_FORM');
    var _type_select_wrapper = _form.find('#TYPE_ID_SELECT_WRAPPER');
    var _refresh_btn = _form.find('#ADD_CUSTOM_POINT_REFRESH_BUTTON');
    var _refresh_btn_icon = _refresh_btn.find('span');

    _form.on('submit', function (e) {
        e.preventDefault();
        var formData = _form.serialize();

        jQuery('#ADD_CUSTOM_POINT_SUBMIT').addClass('disabled');

        jQuery.post(_form.attr('action'), formData, function(data){
           _body.html(data);
            location.reload();
        });
    });

    _refresh_btn.on('click', function (e) {
        e.preventDefault();
        refresh_types();
    });

    refresh_types();

    function refresh_types() {
        _refresh_btn_icon.addClass('fa-spin');

        var url = '?get_index=maps_get_point_types_select&header=2';

        _type_select_wrapper.load(url, function () {
            _refresh_btn_icon.removeClass('fa-spin');
            updateChosen();
        });
    }

</script>