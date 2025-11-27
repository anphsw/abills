<div class='col-md-4 col-xs-6 col-sm-6 mb-3'>
  <div class='card item-card h-100'>
    <div class='image-container'>
      <img class='w-100 item-image' src='%IMAGE_URL%' alt='%ARTICLE_NAME%'>
    </div>
    <div class='card-body pb-0'>
      <h5 class='mb-2 article-name'>%ARTICLE_NAME%</h5>
      <p class='text-muted mb-2'>%ARTICLE_TYPE_NAME%</p>

<!--      <div class='mb-2'>-->
<!--      <span class='text-muted'>_{STORAGE_AVAILABLE}_:</span>-->
<!--      <strong>%MAX_COUNT% %MEASURE_NAME%</strong>-->
<!--    </div>-->

      <div class='price-box mb-3'>
        <h4 class='text-primary mb-0'>_{PRICE}_: %SELL_PRICE% %MONEY_UNIT_NAME%</h4>
      </div>

      <div class='form-group mb-2'>
        <label>_{QUANTITY}_:</label>
        <div class='input-group'>
          <div class='input-group-prepend'>
            <button type='button' class='btn btn-outline-secondary qty-decrease'>
              <i class='fa fa-minus'></i>
            </button>
          </div>
          <input type='number' min='1' max='%MAX_COUNT%'
                 class='form-control count text-center'
                 value='1' required/>
          <div class='input-group-append'>
            <button type='button' class='btn btn-outline-secondary qty-increase'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
      </div>

      <div class='invalid-feedback'>
        _{ENTER_CORRECT_AMOUNT}_<br>
        _{YOU_CANNOT_BUY_MORE_THAN}_ %MAX_COUNT% %MEASURE_NAME%.
      </div>

    </div>
    <div class='card-footer bg-white'>
      %BUY_BTN%
      %RESERVE_BTN%
    </div>
  </div>
</div>

