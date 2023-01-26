<style>

	.steps-container {
		overflow: hidden;
		margin: 0;
		padding: 0;
		white-space: nowrap;
		border-left: 2px solid;
		border-right: 2px solid;
		width: 100%;
		counter-reset: steps;
	}
	.steps {
		position: relative;
		display: inline-block;
		left: -28px; /* -2px default + 26px offset to hide skewed area on the left side of first element*/
		height: 50px;
		line-height: 50px;
		margin-left: 0;
		margin-right: 0;
		counter-increment: steps;
		cursor: pointer;
		transition: background 1s;
		min-height: 30px;
	}

	.steps:after,
	.steps:before {
		position: absolute;
		content: '';
		left: 0;
		height: 50%;
		width: 100%;
		border-top: 2px solid;
		border-bottom: 2px solid;
		border-left: 3px solid; /* thicker border as skew makes them look thin */
		border-right: 3px solid;
		background: rgba(255, 255, 255, 0.15);
	}

	.steps:before {
		transform: skew(45deg);
		top: 0;
		border-bottom: none;
		transform-origin: top left;
	}

	.steps:after {
		transform: skew(-45deg);
		bottom: 0;
		border-top: none;
		transform-origin: bottom left;
	}

	.steps span{
		display: block;
		padding-left: 40px;
		overflow: hidden;
		text-overflow: ellipsis;
		width: 100%;
		height: 75%;
		vertical-align: middle;
	}

	.steps.active span{
		font-weight: bold;
	}
	.steps.active:nth-child(1n):before,
	.steps.active:nth-child(1n):after {
		background: rgba(0, 123, 255, 0.5);
	}

	.steps.active:nth-child(2n):before,
	.steps.active:nth-child(2n):after {
		background: rgba(23, 162, 184, 0.5);
	}

	.steps.active:nth-child(3n):before,
	.steps.active:nth-child(3n):after {
		background: rgba(40, 167, 69, 0.5);
	}

	.steps.active:nth-child(4n):before,
	.steps.active:nth-child(4n):after {
		background: rgba(220, 53, 69, 0.5);
	}

	.steps.active:nth-child(5n):before,
	.steps.active:nth-child(5n):after {
		background: rgba(255, 193, 7, 0.5);
	}

	.steps.active:nth-child(6n):before,
	.steps.active:nth-child(6n):after {
		background: rgba(52, 58, 64, 0.5);
	}

  %CSS%
</style>

<!-- PROGRESSBAR -->
<div class='card box-primary'>

  <div class='card-body'>
    <div class='row' id='progressTracker'>
      <input type='hidden' name='STEP_NUM' id='progressStatus' value='%CUR_STEP%'/>
      <input type='hidden' name='END_STEP' id='end_step' value='%END_STEP%'/>
      <input type='hidden' name='CUR_STEP' id='cur_step' value='%CUR_STEP%'/>
      <hr/>
      <div class='col-md-12 mb-2'>
        <div class='steps-container' id='step_icon'>
          %STEPS%
        </div>
      </div>
      <hr/>
    </div>
    %STEPS_COMMENTS%
  </div>
</div>

<script>

  function adjustBar() {
    let items = jQuery('.steps').length;
    let elHeight = jQuery('.steps').height() / 2;
    let skewOffset = Math.tan(45 * (Math.PI / 180)) * elHeight;
    let reduction = skewOffset + ((items - 1) * 4);
    let leftOffset = jQuery('.steps').css('left').replace('px', '');
    let factor = leftOffset * (-1) - 2;
    jQuery('.steps').css({
      'width': '-webkit-calc((100% + 4px - ' + reduction + 'px)/' + items + ')',
      'width': 'calc((100% + 4px - ' + reduction + 'px)/' + items + ')'
    });
    jQuery('.steps:first-child, .steps:last-child').css({
      'width': '-webkit-calc((100% + 4px - ' + reduction + 'px)/' + items + ' + ' + factor + 'px)',
      'width': 'calc((100% + 4px - ' + reduction + 'px)/' + items + ' + ' + factor + 'px)'
    });
    jQuery('.steps span').css('padding-left', (skewOffset + 15) + "px");
    jQuery('.steps:first-child span, .steps:last-child span').css({
      'width': '-webkit-calc(100% - ' + factor + 'px)',
      'width': 'calc(100% - ' + factor + 'px)',
    });
  }

  function refreshProgress(element) {
    clearProgress();
    jQuery('#step_icon').children().each(function () {
      if (parseInt(this.id) <= parseInt(element)) {
        jQuery('#' + this.id).addClass('active');
      }
    });
  }

  function clearProgress() {
    jQuery('#step_icon').children().removeClass('active');
  }

  function checkStep(step) {
    let endStep = jQuery('#end_step').val();
    let convertLeadBtn = jQuery('#lead_to_client');

    if (endStep === step) {
      convertLeadBtn.attr('disabled', false).attr('style', 'pointer-events: ;');

      let confirmModal = new AModal();
      confirmModal
        .setBody('<h4 class="modal-title"><div id="confirmModalContent">_{ADD_USER}_?</div></h4>')
        .addButton('_{NO}_', 'confirmModalCancelBtn', 'default')
        .addButton('_{YES}_', 'confirmModalConfirmBtn', 'success')
        .show(function () {
          jQuery('#confirmModalConfirmBtn').on('click', function () {
            confirmModal.hide();
            document.getElementById('lead_to_client').click();
          });

          jQuery('#confirmModalCancelBtn').on('click', function () {
            confirmModal.hide();
          });
        });

    } else {
      convertLeadBtn.attr('disabled', true).attr('style', 'pointer-events: none;');
    }
  }

  adjustBar();
  jQuery(document).ready(function () {
    let currentStep = jQuery('#cur_step').val();
    refreshProgress(currentStep);
    checkStep(currentStep)

    jQuery('.steps-container>.steps').on('click', function () {
      jQuery('#progressStatus').val(this.id);
      refreshProgress(this.id);
      jQuery.get('?qindex=$index&header=2&LEAD_ID=$FORM{LEAD_ID}&CUR_STEP=' + this.id);

      checkStep(this.id);
    });
  });
</script>



