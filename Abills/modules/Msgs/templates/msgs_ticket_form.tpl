<head>
  <link rel="stylesheet" href="/styles/default_adm/css/bootstrap.min.css">
  <meta charset="utf-8">
</head>

<style type="text/css">
  .border{
    border: 1px solid rgb(221, 221, 221);
    padding: 5px;
  }

</style>
<body>
  <div class="center-block" style="width: 80%">
    <table class="table table-bordered" style="margin-bottom:0px">
      <tr>
        <th class="text-center">Інформація про абонента</th>
      </tr>
    </table>
    <table class="table table-bordered" style="margin-bottom:0px">
      <tr>
        <th style="width: 50%">_{FIO}_/Назва організації</th>
        <td>%FIO%</td>
      </tr>

      <tr>
        <th>_{ADDRESS}_</th>
        <td>%ADDRESS_FULL%</td>
      </tr>

      <tr>
        <th>Домашній телефон</th>
        <td>%HOME_PHONE_1%</td>
      </tr>

      <tr>
        <th>Мобільний телефон</th>
        <td>%CELL_PHONE_1%</td>
      </tr>

      <tr>
        <th>_{LOGIN}_</th>
        <td>%LOGIN%</td>
      </tr>

      <tr>
        <th>_{PASSWD}_</th>
        <td>%PASSWORD%</td>
      </tr>

    </table>

    <!-- Ticket info-->

    <table class="table table-bordered" style="margin-bottom:0px">
      <tr>
        <th class="text-center">Інформація про тікет</th>
      </tr>
    </table>
    <table class="table table-bordered" style="margin-bottom:0px">
      <tr>
        <th>_{SUBJECT}_</th>
        <td>%MSG_SUBJECT%</td>
      </tr>
      <tr>
        <th style="width: 50%">_{CREATED}_</th>
        <td>%MSG_DATE_CREATE%</td>
      </tr>

      <tr>
        <th>_{STATE}_</th>
        <td>%MSG_STATE%</td>
      </tr>

      <tr>
        <th>_{PRIORITY}_</th>
        <td>%MSG_PRIORITY%</td>
      </tr>

      <tr>
        <th>_{CHAPTER}_</th>
        <td>%MSG_CHAPTER_NAME%</td>
      </tr>
    </table>

    <!-- Messege list  -->

    <table class="table table-bordered" style="margin-bottom:0px">
      <tr>
        <th class="text-center">Список повідомленнь</th>
      </tr>
    </table>

    %TABLE%

    <!-- Global info about ticket -->

    <table class="table table-bordered" style="margin-bottom:0px">
      <tr>
        <td >
          <br>
          _{RESPOSIBLE}_: %RESPOSIBLE%
        </td>
      </tr>
    </table>

  </div>

</body>