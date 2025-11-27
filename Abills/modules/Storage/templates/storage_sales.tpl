<div class='row'>
  %ITEMS%
</div>

<script>
  jQuery.fn.isValid = function(){
    return this[0].checkValidity()
  }

  function countValidate() {
    let parent = jQuery(this).closest('.card-body');
    let invalid_feedback = parent.find('.invalid-feedback');
    let card = jQuery(this).closest('.item-card');
    let sell_btn = card.find('.sell-btn');
    let reserve_btn = card.find('.reserve-btn');

    if (jQuery(this).isValid()) {
      invalid_feedback.removeClass('d-block');
      jQuery(this).removeClass('is-invalid pr-0');

      sell_btn.removeClass('disabled');
      reserve_btn.removeClass('disabled');
      return;
    }

    invalid_feedback.addClass('d-block');
    jQuery(this).addClass('is-invalid pr-0');
    sell_btn.addClass('disabled');
    reserve_btn.addClass('disabled');
  }

  jQuery(document).on('click', '.qty-increase', function() {
    let input = jQuery(this).closest('.input-group').find('.count');
    let max = parseInt(input.attr('max'));
    let current = parseInt(input.val()) || 1;

    if (current < max) {
      input.val(current + 1).trigger('change');
    }
  });

  jQuery(document).on('click', '.qty-decrease', function() {
    let input = jQuery(this).closest('.input-group').find('.count');
    let min = parseInt(input.attr('min')) || 1;
    let current = parseInt(input.val()) || 1;

    if (current > min) {
      input.val(current - 1).trigger('change');
    }
  });

  jQuery('.count').on('keyup', countValidate);
  jQuery('.count').on('change', countValidate);

  jQuery('.sell-btn').on('click', function(event) {
    let href = jQuery(this).data('url');
    let parent = jQuery(this).closest('.item-card');
    let count = parent.find('.count').val() || 0;
    let article_name = parent.find('.article-name').text() || '';

    cancelEvent(event);
    showCommentsModal(`${jQuery(this).text()} ${article_name}?`, `${href}&COUNT=${count}`, '-', { ajax: '', type : 'allow_empty_message' } )
  });

  jQuery('.reserve-btn').on('click', function(event) {
    let href = jQuery(this).data('url');
    let parent = jQuery(this).closest('.item-card');
    let count = parent.find('.count').val() || 0;
    let article_name = parent.find('.article-name').text() || '';

    cancelEvent(event);
    showCommentsModal(`${jQuery(this).text()} ${article_name}?`, `${href}&COUNT=${count}`, '-', { ajax: '', type : 'allow_empty_message' } )
  });
</script>

<style>
	.image-container {
		height: 180px;
		text-align: center;
		position: relative;
		background: #f8f9fa;
		border-bottom: 1px solid #dee2e6;
	}

	.item-card {
		border: 1px solid #dee2e6;
	}

	.item-image {
		max-height: 100%;
		max-width: 100%;
		width: 100%;
		height: auto;
		position: absolute;
		top: 0;
		bottom: 0;
		left: 0;
		right: 0;
		margin: auto;
		object-fit: scale-down;
		padding: 10px;
	}

	.price-box {
		padding: 10px;
		background: #f8f9fa;
		border-radius: 4px;
	}

	.item-card .card-footer {
		padding: 15px;
	}

	.item-card .card-footer .btn {
		width: 100%;
		margin-bottom: 8px;
	}

	.item-card .card-footer .btn:last-child {
		margin-bottom: 0;
	}

	.input-group .btn {
		padding: 0.375rem 0.75rem;
	}

  .modal-body {
    display: none;
  }

	@media (max-width: 768px) {
		.image-container {
			height: 150px;
		}
	}
</style>