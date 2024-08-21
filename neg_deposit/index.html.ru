<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Недостаточно средств</title>
  <style>
    *, ::after, ::before {
      box-sizing: border-box;
    }
    body {
      background-color: #222;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      font-family: -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,"Noto Sans","Liberation Sans",sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol","Noto Color Emoji";
      font-size: 1rem;
      font-weight: 400;
      line-height: 1.5;
      color: #F0F0F0;
      text-align: left;
    }
    a {
      color: #007bff;
      text-decoration: none;
      background-color: transparent;
    }
    h2 {
      margin-top: 0;
    }
    .container {
      max-width: 600px;
      text-align: center;
    }
    .card {
      position: relative;
      display: -ms-flexbox;
      display: flex;
      -ms-flex-direction: column;
      flex-direction: column;
      min-width: 0;
      word-wrap: break-word;
      background-clip: border-box;
      border-radius: .25rem;
    }
    .card {
      border: none;
      border-radius: 15px;
    }
    .card-body {
      -ms-flex: 1 1 auto;
      flex: 1 1 auto;
      min-height: 1px;
      padding: 1.25rem;
    }
    .card-body {
      padding: 2rem;
    }
    .btn:not(:disabled):not(.disabled) {
	    cursor: pointer;
    }
    .btn {
      display: inline-block;
      font-weight: 400;
      color: #212529;
      text-align: center;
      vertical-align: middle;
      -webkit-user-select: none;
      -moz-user-select: none;
      -ms-user-select: none;
      user-select: none;
      background-color: transparent;
      border: 1px solid transparent;
      padding: .375rem .75rem;
      font-size: 1rem;
      line-height: 1.5;
      border-radius: .25rem;
      transition: color .15s ease-in-out,background-color .15s ease-in-out,border-color .15s ease-in-out,box-shadow .15s ease-in-out;
      font-size: 1.12rem;
      padding: 0.75rem 1.5rem;
      margin: 0.5rem 0;
      width: 100%;
    }
    .btn-primary {
      color: #fff;
      background-color: #007bff;
      border-color: #007bff;
    }
    .btn-secondary {
      color: #fff;
      background-color: #6c757d;
      border-color: #6c757d;
    }
    .btn-info {
      color: #fff;
      background-color: #17a2b8;
      border-color: #17a2b8;
    }
    .container {
      width: 100%;
      padding-right: 15px;
      padding-left: 15px;
      margin-right: auto;
      margin-left: auto;
     }
    button, input, optgroup, select, textarea {
      margin: 0;
      font-family: inherit;
      font-size: inherit;
      line-height: inherit;
    }
    .m-0 {
      margin: 0;
    }
  </style>
</head>
<body>
<script>
  function ReloadPage() {
    location.reload(true);
  }
</script>
<div class="container">
  <div class="card">
    <div class="card-body">
      <!-- You can put your inline svg logo here. -->
      <h2>
        У вас недостаточно средств на счету!
      </h2>
      <div>
        <p>
          Для дальнейшего использования услуги Интернет в полном объеме, пожалуйста, пополните Ваш счет
        </p>
        <p>
          Для работы в режиме минимальной пропускной способности активируйте ограниченный режим
        </p>
      </div>
      <a href="https://YOUR.PORTAL:9443/" class="btn btn-primary">
        <b>Пополнить счёт</b>
      </a>
      <a href="https://YOUR.PORTAL:9443/" class="btn btn-info">Активировать ограниченный режим</a>
      <button type="button" class='btn btn-secondary' onclick="ReloadPage()">Продолжить</button>
    </div>
  </div>
</div>
</body>
</html>
