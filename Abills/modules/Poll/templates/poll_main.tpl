<div class='row'>
    <div class='form-group'>
        <div class='col-md-12'>
            <ul class="nav nav-tabs nav-justified">
                <li class="nav-item %LI_ACTIVE_2%">
                    <a href='$SELF_URL?index=$index&new=1&processed=1&status=0' class='btn btn-default'
                       role='button'>_{NEW}_</a>
                </li>
                <li class="nav-item %LI_ACTIVE_3%">
                    <a href='$SELF_URL?index=$index&processed=2&status=1' class='btn btn-default'
                       role='button'>_{PROCESSED}_</a>
                </li>
                <li class="nav-item %LI_ACTIVE_4%">
                    <a href='$SELF_URL?index=$index&archive=1&status=2' class='btn btn-default'
                       role='button'>_{ARCHIVE}_</a>
                </li>
                <li class="nav-item %LI_ACTIVE_1%">
                    <a href='$SELF_URL?index=$index&all=1' class='btn btn-default'
                       role='button'>_{ALL}_</a>
                </li>
            </ul>
        </div>
        <div class='form-group'>
            %CONTENT%
        </div>
    </div>
</div>