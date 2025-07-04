package Sorm::Plugins::Kzt;

=head1 NAME

  Module SORM for Kazakhstan

=head1 DOCS

  Arg:
    START - full uploading from the begining (START=1)
    DATE - date uploading (previous date is by default). Format DATE=YYYY-MM-DD
    DEBUG

  Execute:
  /usr/abills/libexec/billd sorm TYPE=Kzt

  DESCRIBE: Plugin for SORM of Kazakhstan

=head1 VERSION

  VERSION: 1.2
  CREATED: 20240821
  UPDATED: 202506027

=cut

use strict;
use warnings FATAL => 'all';

use Companies;
use Storage;
use Time::Piece;
use Abills::Base qw(date_format);

my ($User, $Company, $Internet, $Storage, $debug);

my $begin_date = '2020-01-01';
my $t = localtime;
my $upload_t = $t - 86400;
my $delimeter = '|';
our $prefix = 'Fix_';
our $mob_header = 0;

my $year  = sprintf("%04d", $t->year());
my $month = sprintf("%02d", $t->mon());
my $day   = sprintf("%02d", $t->mday());
my $hour  = 23;
my $min   = 59;

my $upload_year = sprintf("%04d", $upload_t->year());
my $upload_month = sprintf("%02d", $upload_t->mon());
my $upload_day = sprintf("%02d", $upload_t->mday());
my $upload_date = "$upload_year-$upload_month-$upload_day";

my $sufix = $upload_year . $upload_month . $upload_day . 'T' . $hour . $min . '.csv';
my %reports = ();

#**********************************************************
=head2 new($conf, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $conf, $db, $Admin, $attr) = @_;

  my $self = {
    debug => $attr->{DEBUG} || 0,
    admin => $Admin,
    db    => $db,
    conf  => $conf,
    argv  => $attr
  };

  bless($self, $class);

  $debug = $self->{debug} || 0;

  $self->init();

  return $self;
}

#**********************************************************
=head2 init()

=cut
#**********************************************************
sub init {
  my $self = shift;

  $User = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Company = Companies->new($self->{db}, $self->{admin}, $self->{conf});
  $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  $Storage = Storage->new($self->{db}, $self->{admin}, $self->{conf});

  my $argv = $self->{argv};

  if ($argv->{START}) {
    mkdir($main::var_dir . 'sorm/');
    mkdir($main::var_dir . 'sorm/Kzt');
  }

  if ($argv->{DATE}){
    if ($argv->{DATE} =~ /(\d{4})\-(\d{2})\-(\d{2})/) {
      $upload_date = $argv->{DATE};
      my $sufix_date = $argv->{DATE};
      $sufix_date =~ s/\-//g;
      $sufix = $sufix_date . 'T' . $hour . $min . '.csv';
    }
    else {
      print "Please specify argument DATE in correct format: DATE=YYYY-MM-DD \n";
      return 1;
    }
  }

  if (!$argv->{START}){
    $begin_date = $upload_date;
  }

  print "Upload period: $begin_date/$upload_date\n" if ($debug);

  # ABONENT
  my $users_list = $User->list({
    REGISTRATION_FROM_REGISTRATION_TO => "$begin_date/$upload_date",
    DELETED       => 0,
    REGISTRATION  => '_SHOW',
    DISABLE       => 0,
    COLS_NAME     => 1,
    PAGE_ROWS     => 99999,
  });

  print "Users: $User->{TOTAL}\n" if ($debug > 1);

  _add_header('ABD');

  foreach my $u (@$users_list) {
    $self->ABD_report($u->{uid});
  }

  $self->send();

  return 1;
}

#**********************************************************
=head2 ABD_report() - info about abonent

=cut
#**********************************************************
sub ABD_report {
  my $self = shift;
  my ($uid) = @_;
  $prefix = 'Fix_';

  $User->info($uid);
  if ($User->{errno}) {
    delete $User->{errno};
    return 0;
  }

  $User->pi({ UID => $uid });
  $Company->info($User->{COMPANY_ID});
  if ($Internet->can('user_info')) {
    $Internet->user_info($uid);
  }
  else {
    $Internet->info($uid);
  }

  my $passport = $User->{PASPORT_NUM} || q{};
  $passport =~ s/\s//g if ($User->{PASPORT_NUM});
  my $passport_grant = $User->{PASPORT_GRANT} || q{};
  $passport_grant =~ s/\n//g if ($User->{PASPORT_GRANT});
  $passport_grant =~ s/\r//g if ($User->{PASPORT_GRANT});
  my $passport_date = ($User->{PASPORT_DATE} ne '0000-00-00') ? $User->{PASPORT_DATE} : '';

  my $email = $User->{EMAIL} || q{};
  $email =~ s/^\s+|\s+$//g if ($User->{EMAIL});

  my $internet_tp_name = $Internet->{TP_NAME} || q{};
  my $user_mac = $Internet->{CPE_MAC} ? $Internet->{CPE_MAC} : $Internet->{CID};
  $user_mac =~ s/://g if $Internet->{CPE_MAC};

  my $network_type = 'FTTH';
  my $service_type = 'фиксированный интернет ';
  my $phone = '';
  my $imsi = '';
  my $user_status = '';
  my $install_date = ($User->{ACTIVATE} && $User->{ACTIVATE} ne '0000-00-00') ? date_format($User->{ACTIVATE}, "%d.%m.%Y") : q{};

  my $region_id = _region($User->{ADDRESS_FULL_LOCATION});

  # Mobile subscribers
  if ($self->{conf}->{SORM_IMSI_PREFIX} && $Internet->{CID} && $Internet->{CID} =~ /^$self->{conf}->{SORM_IMSI_PREFIX}/){
    $prefix = 'Mob_';
    $network_type = 'FWA';
    $service_type = 'мобильная связь ';
    $phone = $User->{CELL_PHONE} || $User->{PHONE} || '';
    $imsi = $Internet->{CID};

    if ($User->{DISABLE}){
      $user_status = 'A' if ($User->{DISABLE} == 0);
      $user_status = 'C' if ($User->{DISABLE} == 1);
      $user_status = 'S' if ($User->{DISABLE} > 1);
    }

    my $user_storage = $Storage->storage_installation_list({ UID => $uid, DATE => '_SHOW', COLS_NAME => 1 });
    $install_date = $user_storage->[0]->{date} || '';
    $prefix = 'Mob_';

    if ($mob_header == 0){
      _add_header('ABD');
      $mob_header = 1;
    }
  }


  my @arr = ();

    # ID абонента
  $arr[0] = $uid;
    # ФИО/Наименование организации
  $arr[1] = ($User->{COMPANY_ID} > 0) ? $Company->{NAME} : ($User->{FIO} || q{});
    # Номер телефона абонента (empty)
  $arr[2] = $phone;
    # IMSI
  $arr[3] = $imsi;
    # IMEI (empty)
  $arr[4] = '';
    # Адрес проживания/Адрес регистрации
  $arr[5] = $User->{ADDRESS_FULL_LOCATION} || q{};
    # Номер и дата выдачи документа
  $arr[6] = ($passport) ? "$passport от $passport_date, выдан $passport_grant" : '';
    # Дата рождения
  $arr[7] = ($User->{BIRTH_DATE} && $User->{BIRTH_DATE} ne '0000-00-00') ? date_format($User->{BIRTH_DATE}, "%d.%m.%Y") : q{};
    # ИИН/БИН
  $arr[8] = $User->{TAX_NUMBER} || q{};
    # Тип пользователя 1 - юридическое лицо, 2 - физическое лицо
  $arr[9] = ($User->{COMPANY_ID} > 0) ? 1 : 2;
    # Контактное лицо
  $arr[10] = ($User->{COMPANY_ID} > 0) ? $Company->{REPRESENTATIVE} : ($User->{FIO} || q{});
    # Контактный телефон
  $arr[11] = ($User->{COMPANY_ID} > 0) ? $Company->{PHONE} : $phone;
    # Тип услуги
  $arr[12] = $service_type.$internet_tp_name;
    # Короткий номер  (empty)
  $arr[13] = '';
  $arr[14] = $email;
    # Дата активации абонента (empty)
  $arr[15] = '';
    # Номер SIM-карты (empty)
  $arr[16] = '';
    # Дата смены статуса SIM (empty)
  $arr[17] = '';
    # Статус SIM-карты/Статус абонента
  $arr[18] = $user_status;
    # Дата блокировки SIM (empty)
  $arr[19] = '';
    # Тип сети
  $arr[20] = $network_type;
    # Регион
  $arr[21] = $region_id;
    # Дата и время актуализации информации
  $arr[22] = ($User->{REGISTRATION} && $User->{REGISTRATION} ne '0000-00-00') ? date_format($User->{REGISTRATION}, "%d.%m.%Y") : q{};
    # Адрес регистрации абонентского оборудования
  $arr[23] = $User->{ADDRESS_FULL_LOCATION} || q{};
    # Свидетельство о постановке на учет по НДС (юр лицо)
  $arr[24] = ($User->{COMPANY_ID} > 0) ? $Company->{TAX_NUMBER} : '';
    # Дата заключения договора
  $arr[25] = ($User->{CONTRACT_DATE} && $User->{CONTRACT_DATE} ne '0000-00-00') ? date_format($User->{CONTRACT_DATE}, "%d.%m.%Y") : q{};
    # Адрес установки абонентского оборудования
  $arr[26] = $User->{ADDRESS_FULL_LOCATION} || q{};
    # Статические IP-адреса для выделенных линий, начало диапазона
  $arr[27] = ($Internet->{IP} && $Internet->{IP} ne '0.0.0.0') ? $Internet->{IP} : '';
    # Статические IP-адреса для выделенных линий, конец диапазона
  $arr[28] = ($Internet->{IP} && $Internet->{IP} ne '0.0.0.0') ? $Internet->{IP} : '';
    # Дата и время активации (введения в статус) абонентского оборудования
  $arr[29] = ($User->{ACTIVATE} && $User->{ACTIVATE} ne '0000-00-00') ? date_format($User->{ACTIVATE}, "%d.%m.%Y"): q{};
    # Дата активации SIM абонента (empty)
  $arr[30] = '';
    # Адрес, с которого оплачивается услуга
  $arr[31] = $User->{ADDRESS_FULL_LOCATION} || q{};
    # UserName
  $arr[32] = $User->{LOGIN}|| q{};
    # Номера устройств абонентского оборудования
  $arr[33] = $user_mac;
    # Адрес регистрации абонентского оборудования
  $arr[34] = $User->{ADDRESS_FULL_LOCATION} || q{};
    # Дата установки оборудования
  $arr[35] = $install_date;

  delete($User->{FIO});
  delete($User->{ADDRESS_FULL_LOCATION});
  delete($User->{CELL_PHONE});

  _add_report("ABD", @arr);

  return 1;
}

#**********************************************************
=head2 _add_report($type, @params)

  Arguments:
    $type
    @params

  Results:
   TRUE or FALSE

=cut
#**********************************************************
sub _add_report {
  my ($type, @params) = @_;

  my $string = '';
  foreach my $line (@params) {
    $line //= '';
    $line =~ s/$delimeter//;
    $string .= $line . $delimeter;
  }

  $string =~ s/\r//g;
  $string =~ s/\n//g;
  $string =~ s/\t//g;
  $string =~ s/$delimeter$/\n/;

  _save_report($type, $string);

  return 1;
}

#**********************************************************
=head2 _save_report($type,$content)

  Arguments:
    $type
    $content

  Results:
   TRUE or FALSE

=cut
#**********************************************************
sub _save_report {
  my($type, $content)=@_;

  print "$content\n" if ($debug > 5);

  %reports = (
    ABD  => $main::var_dir.'sorm/Kzt/'.$prefix.$sufix,
  );

  my $filename = $reports{$type};
  open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
  print $fh $content;
  close $fh;

  return 1;
}


#**********************************************************
=head2 _add_header($type)

  Arguments:
    $type

  Results:
   TRUE or FALSE

=cut
#**********************************************************
sub _add_header {
  my ($type) = @_;

  my %headers = (
    ABD  => [
      'ID абонента',
      'ФИО/Наименование организации',
      'Номер телефона абонента',
      'IMSI',
      'IMEI',
      'Адрес проживания/Адрес регистрации',
      'Номер и дата выдачи документа, удостоверяющего личность',
      'Дата рождения',
      'ИИН/БИН',
      'Тип пользователя',
      'Контактное лицо',
      'Контактный телефон',
      'Тип услуги',
      'Короткий номер',
      'e-mail',
      'Дата активации абонента',
      'Номер SIM-карты',
      'Дата смены статуса SIM',
      'Статус SIM-карты/Статус абонента',
      'Дата блокировки SIM',
      'Тип сети',
      'Регион',
      'Дата и время актуализации информации',
      'Адрес регистрации абонентского оборудования ',
      'Свидетельство о постановке на учет по НДС',
      'Дата заключения договора',
      'Адрес установки абонентского оборудования',
      'Статические IP-адреса для выделенных линий, начало диапазона',
      'Статические IP-адреса для выделенных линий, конец диапазона',
      'Дата и время активации (введения в статус) абонентского оборудования',
      'Дата активации SIM абонента',
      'Адрес, с которого оплачивается услуга',
      'UserName',
      'Номера устройств абонентского оборудования',
      'Адрес регистрации абонентского оборудования',
      'Дата установки оборудования',
    ]
  );

  my $string = '';
  foreach (@{$headers{$type}}) {
    $string .= ($_ // '') . $delimeter;
  }
  # $string =~ s/$delimeter$/\n/;

  _save_report($type, $string);

  return 1;
}


#**********************************************************
=head2 send()

=cut
#**********************************************************
sub send {
  my $self = shift;
  %reports = (
    ABD  => $main::var_dir.'sorm/Kzt/'.$prefix.$sufix,
  );

  for my $report (values %reports) {
    if (-e $report) {
      main::_ftp_upload({
        DIR  => $self->{conf}->{SORM_SERVER_DIR} ? $self->{conf}->{SORM_SERVER_DIR} : '/',
        FILE => $report
      });

      unlink $report if ($debug < 3);
    }
  }

  return 1;
}

#**********************************************************
=head2 _region($attr)

   Attr:
     $User

   Return:
     region_id

=cut
#**********************************************************
sub _region {
  my ($address_district) = @_;
  return '' if (!$address_district);

  my $region_id = '';

  $region_id = 1  if ($address_district =~ /Астана/);
  $region_id = 2  if ($address_district =~ /Алматы/);
  $region_id = 3  if ($address_district =~ /Акмолинская/);
  $region_id = 4  if ($address_district =~ /Актюбинская/);
  $region_id = 5  if ($address_district =~ /Алматинская/);
  $region_id = 6  if ($address_district =~ /Атырауская/);
  $region_id = 7  if ($address_district =~ /Западно-Казахстанская/);
  $region_id = 8  if ($address_district =~ /Жамбылская/);
  $region_id = 9  if ($address_district =~ /Карагандинская/);
  $region_id = 10 if ($address_district =~ /Костанайская/);
  $region_id = 11 if ($address_district =~ /Кызылординская/);
  $region_id = 12 if ($address_district =~ /Мангистауская/);
  $region_id = 13 if ($address_district =~ /Южно-Казахстанская/);
  $region_id = 14 if ($address_district =~ /Павлодарская/);
  $region_id = 15 if ($address_district =~ /Северо-Казахстанская/);
  $region_id = 16 if ($address_district =~ /Восточно-Казахстанская/);
  $region_id = 17 if ($address_district =~ /Шымкент/);
  $region_id = 18 if ($address_district =~ /Абай/);
  $region_id = 19 if ($address_district =~ /Жетысу/);
  $region_id = 20 if ($address_district =~ /Улытауская/);

  return $region_id;
}

1;