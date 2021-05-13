<link rel='stylesheet' href='/styles/default_adm/css/msgs.css'>
<script src='/styles/default_adm/js/msgs/shedule_table.js'></script>
<script>
    var tasksInfo = {};
</script>

%OPTIONS_SCRIPT%

<div class='card card-primary card-outline center-block'>
    <div class='card-header with-border text-right'>
        <h4 class='card-title'>_{SHEDULE_BOARD}_ (_{HOURS}_)</h4>
    </div>
    <div class='card-body'>
        <div class='text-left'>
            <div class="row" id='new-tasks'></div>
        </div>
        <br/><br/>
        <div>
            <div class='row' id='hour-grid'></div>
        </div>
    </div>
</div>

<div class='col-md-12 col-sm-12'>
    <div class="row">
        <div class='col-md-6 col-sm-6'>
            <div class='card box-primary center-block'>
                <div class='card-header with-border text-right'>
                    <h4 class='card-title'>_{SEARCH}_</h4>
                </div>
                <div class='card-body'>
                    <form class='form form-inline' action=''>
                        <input type='hidden' name='index' value='$index'/>
                        <input type='hidden' name='ID' value='$FORM{ID}'/>
                        <input type='hidden' name='DATE' value='$FORM{DATE}'/>
                        <input type='hidden' name='HOURS' value='1'/>

                        <div class="form-group">
                            <div class="row">
                                <div class="col-sm-12 col-md-6">
                                    <label class='control-label col-md-10 col-sm-12' for='DATE'>_{DATE}_</label>
                                    <div class="input-group">
                                        <input type='text' class='form-control datepicker'
                                            value='$FORM{DATE}' name='DATE'/>
                                    </div>
                                </div>

                                <div class="col-sm-12 col-md-6">
                                    <label class='control-label col-md-8 col-sm-12' for='TASK_STATUS_SELECT'>_{STATUS}_</label>
                                    <div class="input-group">
                                        %TASK_STATUS_SELECT%
                                    </div>
                                </div>
                            </div>
                        </div>
                        <input type='submit' class='btn btn-primary' value='_{SHOW}_'/>
                    </form>
                </div>
            </div>
        </div>

        <div class='col-md-6 col-sm-6'>
            <div class='card box-primary center-block'>
                <div class='card-header with-border text-right'>
                    <h4 class='card-title'>_{SET}_</h4>
                </div>
                <div class='card-body'>
                    <form id='tasksForm' method='POST' action='$SELF_URL'>
                        <div class='row'>
                            <input type='hidden' name='index' value='$index'/>
                            <input type='hidden' id='indexJob' name='indexJob' value='%INDEX_JOB%'/>
                            <input type='hidden' name='jobs' id='jobsNew' />
                            <input type='hidden' name='popped' id='jobsPopped' />
                            <input type='hidden' name='DATE' value='$FORM{DATE}'/>
                            <input type='hidden' name='HOURS' value='1'/>

                            <div class='center-block text-center'>
                                <input type='submit' class='btn btn-primary' id='saveBtn' name='change' value='_{CHANGE}_'>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
function makeResizableDiv() {
    const resizers = document.querySelectorAll('.resizer')

    for (let i = 0; i < resizers.length; i++) {
        const currentResizer = resizers[i]
        currentResizer.addEventListener('mousedown', function(e) {
            e.preventDefault()
            window.addEventListener('mousemove', resize)
            window.addEventListener('mouseup', stopResize)
        })

        let currentResizerTmp = 0;
        function resize(e) {
            if (currentResizer.classList.contains('bottom-right')) {
                currentResizer.style.width = e.pageX - currentResizer.getBoundingClientRect().left + '%'
                currentResizerTmp = e.pageX - currentResizer.getBoundingClientRect().left
            }
        }

        function stopResize() {
            window.removeEventListener('mousemove', resize)

            let a = (100 / 60 * 15)
            let resizeNew = Math.round(currentResizerTmp / a) * a
            currentResizer.style.width = resize + '%'

            let index = jQuery('#indexJob').val()
            let hours = resizeNew
            let id    = currentResizer.id

            let url = `${SELF_URL}?index=${index}&id=${id}&hours=${hours}`

            jQuery.ajax({
                url        : url,
                type       : "get",
                contentType: false,
                cache      : false,
                processData: false,
                success    : function () { }
            });
        }
    }
}

jQuery(document).ready(function() {
    makeResizableDiv()
})

</script>