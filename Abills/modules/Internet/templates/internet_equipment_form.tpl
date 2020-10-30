<div id='form_4' class='box box-theme box-big-form for_sort'>
    <div class='box-header with-border'>
        <h3 class='box-title'>_{EQUIPMENT}_</h3>
        <div class='box-tools pull-right'>
            <button type='button' class='btn btn-box-tool' data-widget='collapse'><i
                    class='fa fa-minus'></i>
            </button>
        </div>
    </div>
    <div class='box-body' id='equipment_info'>
        <div id='status-loading-content'>
            <div class='text-center'>
                <span class='fa fa-spinner fa-spin fa-2x'></span>
            </div>
        </div>
    </div>
</div>

<script>
    let nasId = '%NAS_ID%';
    let port = '%PORT%';
    let vlan = '%VLAN%';
    let uid = '%UID%';
    let id = '%ID%';

    let url = '$SELF_URL?header=2&get_index=equipment_get_info' + '&NAS_ID=' + nasId + '&PORT=' + port + '&VLAN=' +
        vlan + '&UID=' + uid + '&ID=' + id;
    fetch(url)
        .then(function (response) {
            if (!response.ok)
                throw Error(response.statusText);

            return response;
        })
        .then(function (response) {
            return response.text();
        })
        .then(result => {
            jQuery('#equipment_info').append(result);
            jQuery('#status-loading-content').hide();
        });
</script>
