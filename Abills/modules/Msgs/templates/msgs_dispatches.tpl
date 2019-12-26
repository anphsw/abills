<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='UID' value='$FORM{UID}'/>
    <input type='hidden' name='ID' value='%ID%'/>

    %DISPATCHES%
</FORM>

<style>
    .style_box {
        font-weight: 900;
        color: #ffffff;
        white-space: nowrap;
        letter-spacing: .1em;
        text-shadow: -1px 0 blue, 0 1px blue, 1px 0 blue, 0 -1px blue;
    }

    .pad {
        border-radius: 5px;
    }
</style>

<script>
    function modal_view(id, index_chg) {
        var str_request = '';
        if (id) {
            str_request = '&chg=' + id + '&not_msgs=1';
        }
        else {
            str_request = '&add_form=1&not_msgs=1';
        }
        jQuery.post('$SELF_URL', 'qindex=' + index_chg + '&header=2' + str_request, function (data) {

            var add_contact_form = new AModal();
            add_contact_form
                .setId('add1_contact_modal')
                .isForm(true)
                // .setHeader('_{DISPATCH}_ #' + id)
                .setBody(data)
                .setLarge(true)
                .show(function (modal) {

                });

            initSelect2();
        });
    }
</script>