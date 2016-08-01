%QUICK_CMD%

<form action=$SELF_URL METHOD=post name=FORM_NAS class='form-horizontal'>
    <input type=hidden name='index' value='$index'>
    <input type=hidden name='NAS_ID' value='%NAS_ID%'>
    <input type=hidden name='console' value='1'>
    <legend>Console</legend>
    <fieldset>

        <div class='form-group'>
            <label class='col-sm-offset-2 col-sm-8'>_{MANAGE}_</label>

            <label class='control-label col-md-6' for='NAS_MNG_IP_PORT'>IP:PORT</label>
            <div class='col-md-2'>
                <input id='NAS_MNG_IP_PORT' name='NAS_MNG_IP_PORT' value='%NAS_MNG_IP_PORT%'
                       placeholder='%NAS_MNG_IP_PORT%' class='form-control' type='text'>
            </div>

            <label class='control-label col-md-6' for='NAS_MNG_USER'>_{USER}_</label>
            <div class='col-md-2'>
                <input id='NAS_MNG_USER' name='NAS_MNG_USER' value='%NAS_MNG_USER%' placeholder='%NAS_MNG_USER%'
                       class='form-control' type='text'>
            </div>


            <label class='control-label col-md-6' for='NAS_MNG_PASSWORD'>_{PASSWD}_</label>
            <div class='col-md-2'>
                <input id='NAS_MNG_PASSWORD' name='NAS_MNG_PASSWORD' value='%NAS_MNG_PASSWORD%'
                       placeholder='%NAS_MNG_PASSWORD%' class='form-control' type='password'>
            </div>
        </div>

        <div class='form-group'>
            <label class='control-label col-md-6' for='type'>_{TYPE}_</label>
            <div class='col-md-2'>
              %TYPE_SEL%
            </div>
        </div>

        <div class='form-group'>
            <div class='col-sm-offset-4 col-sm-4'>
                <textarea class='form-control' id='CMD' name='CMD' rows='3'>%CMD%</textarea>
            </div>

            <div class='col-sm-offset-2 col-sm-8'>
                <input type='submit' class='btn btn-primary' name='ACTION' value='_{SEND}_'>
            </div>
        </div>

    </fieldset>
</form>

<script>
    jQuery(function () {
        var removeBtns = jQuery('.removeIpBtn');

        function removeAddress(context) {
            var cont = jQuery(context);

            var command = "ip firewall address-list remove numbers=" + cont.attr('data-address-number');

            var params = {
                qindex: '$index',
                console : 1,
                full : 1,
                header : 2,
                ACTION : 1,
                NAS_ID: '$FORM{NAS_ID}',
                CMD : command
            };

            cont.find('.glyphicon').addClass('fa-spin');

            jQuery.get(SELF_URL, params, function () {
               cont.parent().parent().hide();
            });

        }

        removeBtns.on('click', function () {
            removeAddress(this);
        })
    })
</script>

