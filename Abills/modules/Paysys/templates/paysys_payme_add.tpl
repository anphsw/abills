<form action='%URL%' method='post'>

  <!-- Идентификатор WEB Кассы -->
  <input type="hidden" name="merchant" value="%MERCHANT_ID%"/>
  <!-- Сумма платежа в тийинах -->
  <input type="hidden" name="amount" value="%AMOUNT%"/>
  <!-- Поля Объекта Account -->
  <input type="hidden" name="account[%CHECK_FIELD%]" value="%USER_ID%"/>
  <input type="hidden" name="account[TRANSACTION_ID]" value="%TRANSACTION_ID%"/>
  <!-- ==================== НЕОБЯЗАТЕЛЬНЫЕ ПОЛЯ ====================== -->
  <!-- Язык. Доступные значения: ru|uz|en
       Другие значения игнорируются
       Значение по умолчанию ru -->
  <input type="hidden" name="lang" value="ru"/>

  <!-- Валюта. Доступные значения: 643|840|860|978
       Другие значения игнорируются
       Значение по умолчанию 860
       Коды валют в ISO формате
       643 - RUB
       840 - USD
       860 - UZS
       978 - EUR -->
  <input type="hidden" name="currency" value="860"/>

  <!-- URL возврата после оплаты или отмены платежа.
       Если URL возврата не указан, он берется из заголовка запроса Referer.
       URL возврата может содержать параметры, которые заменяются Paycom при запросе.
       Доступные параметры для callback:
       :transaction - id транзакции или "null" если транзакцию не удалось создать
       :account.{field} - поля объекта Account
       Пример: https://your-service.uz/paycom/:transaction -->
  <!--<input type="hidden" name="callback" value="{url возврата после платежа}"/>-->

  <!-- Таймаут после успешного платежа в миллисекундах.
       Значение по умолчанию 15
       После успешной оплаты, по истечении времени callback_timeout
       производится перенаправление пользователя по url возврата после платежа -->
  <input type="hidden" name="callback_timeout" value="15"/>

  <!-- Выбор платежного инструмента Paycom.
       В Paycom доступна регистрация несколько платежных
       инструментов. Если платёжный инструмент не указан,
       пользователю предоставляется выбор инструмента оплаты.
       Если указать id определённого платежного инструмента -
       пользователь перенаправляется на указанный платежный инструмент. -->
  <!--<input type="hidden" name="payment" value="{payment_id}"/>-->

  <!-- Описание платежа
       Для описания платежа доступны 3 языка: узбекский, русский, английский.
       Для описания платежа на нескольких языках следует использовать
       несколько полей с атрибутом  name="description[{lang}]"
       lang может принимать значения ru|en|uz -->
  <input type="hidden" name="description" value="PaymentDesc Payme"/>

  <!-- Объект детализации платежа
       Поле для детального описания платежа, например, перечисления
       купленных товаров, стоимости доставки, скидки.
       Значение поля (value) — JSON-строка закодированная в BASE64 -->
  <!--<input type="hidden" name="detail" value="{JSON объект детализации в BASE64}"/>-->
  <!-- ================================================================== -->



  <div class='box box-primary '>
    <div class='box-header with-border'><h4>_{BALANCE_RECHARCHE}_</h4></div>

    <div class='box-body'>

      <div class='form-group text-center'>
        <img src='/styles/default_adm/img/paysys_logo/payme-logo.png' style="width: auto; max-height: 200px;">
      </div>

      <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
      </div>

      <div class='form-group'>
        <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>PayMe</label>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
        <label class='control-label col-md-6'> $FORM{SUM} </label>
      </div>
    </div>
    <div class='box-footer'>
      <input class='btn btn-primary' type=submit value=_{PAY}_>
    </div>
  </div>

</form>
