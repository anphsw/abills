package Sorm::Fenix;
use strict;
use warnings FATAL => 'all';

use Companies;
use Time::Piece;
use Abills::Misc qw/translate_list in_array/;
use Abon;

my ($User, $Company, $Internet, $Payments, $Nas, $Abon);

my $t = localtime;

my $month = sprintf("%02d", $t->mon());
my $year = sprintf("%04d", $t->year());
my $day = sprintf("%02d", $t->mday());
my $hour = sprintf("%02d", $t->hour());
my $min = sprintf("%02d", $t->min());

my $sufix = $year . $month . $day . "_" . $hour . $min . ".txt";
my %reports = (
  ABONENT               => "$main::var_dir/sorm/Fenix/ABONENT_" . $sufix,
  ABONENT_IDENT         => "$main::var_dir/sorm/Fenix/ABONENT_IDENT_" . $sufix,
  ABONENT_SRV           => "$main::var_dir/sorm/Fenix/ABONENT_SRV_" . $sufix,
  ABONENT_ADDR          => "$main::var_dir/sorm/Fenix/ABONENT_ADDR_" . $sufix,
  PAYMENT               => "$main::var_dir/sorm/Fenix/PAYMENT_" . $sufix,
  PAY_TYPE              => "$main::var_dir/sorm/Fenix/PAY_TYPE_" . $sufix,
  DOC_TYPE              => "$main::var_dir/sorm/Fenix/DOC_TYPE_" . $sufix,
  IP_PLAN               => "$main::var_dir/sorm/Fenix/IP_PLAN_" . $sufix,
  GATEWAY               => "$main::var_dir/sorm/Fenix/GATEWAY_" . $sufix,
  SUPPLEMENTARY_SERVICE => "$main::var_dir/sorm/Fenix/SUPPLEMENTARY_SERVICE_" . $sufix

);

#**********************************************************
=head2 new($conf, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $conf, $db, $Admin, $attr) = @_;

  my $self = {
    DEBUG => $attr->{DEBUG} || 0,
    ADMIN => $Admin,
    DB    => $db,
    conf  => $conf,
    argv  => $attr
  };

  bless($self, $class);

  $self->init();

  return $self;
}

#**********************************************************
=head2 init()

=cut
#**********************************************************
sub init {
  my $self = shift;

  $User = Users->new($self->{DB}, $self->{ADMIN}, $self->{conf});
  $Company = Companies->new($self->{DB}, $self->{ADMIN}, $self->{conf});
  $Internet = Internet->new($self->{DB}, $self->{ADMIN}, $self->{conf});
  $Payments = Finance->payments($self->{DB}, $self->{ADMIN}, $self->{conf});
  $Nas = Nas->new($self->{DB}, $self->{ADMIN}, $self->{conf});
  $Abon = Abon->new($self->{DB}, $self->{ADMIN}, $self->{conf});

  my $argv = $self->{argv};

  if ($argv->{START}) {
    mkdir($main::var_dir . '/sorm/');
    mkdir($main::var_dir . '/sorm/Fenix');

    my $users_list = $User->list({
      COLS_NAME => 1,
      PAGE_ROWS => 99999,
      DELETED   => 0,
      DISABLE   => 0,
    });

    _add_header("ABONENT");
    _add_header("ABONENT_IDENT");
    _add_header("ABONENT_SRV");
    _add_header("ABONENT_ADDR");
    foreach my $u (@$users_list) {
      $self->ABONENT_report($u->{uid});
      $self->ABONENT_IDENT_report($u->{uid});
      $self->ABONENT_SRV_report($u->{uid});
      $self->ABONENT_ADDR_report($u->{uid});
    }

    my $payments = $Payments->list({
      COLS_NAME => 1,
      PAGE_ROWS => 99999,
      ID        => '_SHOW'
    });

    _add_header("PAYMENT");
    foreach my $p (@$payments) {
      $self->PAYMENT_report($p->{id});
    }

    $self->PAY_TYPE_report();
    $self->DOC_TYPE_report();
    $self->IP_PLAN_report();
    $self->GATEWAY_report();
    if(in_array('Abon', \@main::MODULES)) {
      $self->SUPPLEMENTARY_SERVICE_report();
    }

    $self->send();
  }

  return 1;
}

#**********************************************************
=head2 ABONENT_report()

=cut
#**********************************************************
sub ABONENT_report {
  my $self = shift;
  my ($uid) = @_;

  $User->info($uid);
  if ($User->{errno}) {
    delete $User->{errno};
    return 0;
  }

  my @arr;

  $User->pi({ UID => $uid });

  my ($family, $name, $surname) = ($User->{FIO}, $User->{FIO2}, $User->{FIO3});
  ($family, $name, $surname) = split ' ', $User->{FIO} if(!$name || !$surname);

  my $sorm_id = $self->{conf}->{SORM_ISP_ID};

  $arr[0] = $uid;                                                                                                           #ID
  $arr[1] = $sorm_id;                                                                                                       #REGION ID
  $arr[2] = main::_date_format($User->{REGISTRATION}) . ' 12:00:00';                                                        #CONTRACT_DATE
  $arr[3] = $User->{CONTRACT_ID} || $User->{LOGIN};                                                                         #CONTRACT
  $arr[4] = $User->{INVOICE_NUM} || $User->{CONTRACT_ID} || $User->{LOGIN} || '';                                                                                     #ACCOUNT
  $arr[5] = main::_date_format($User->{REGISTRATION}) . ' 12:00:00';                                                        # дата активации основной услуги
  $arr[6] = '01.01.2025';
  #ФИЗ. Лицо
  if (!$User->{COMPANY_ID}) {
    $arr[7] = 42;

    if ($name && $surname && $family) {
      $arr[8] = 0;       # тип ФИО (0-структурировано, 1 - одной строкой)
      $arr[9] = $family;   # фамилия
      $arr[10] = $name;    # имя
      $arr[11] = $surname; # отчество
      $arr[12] = "";       # ФИО строкой
    }
    else {
      $arr[8] = 1; # тип ФИО (0-структурировано, 1 - одной строкой)
      @arr[9 .. 11] = ("") x 3;
      $arr[12] = $User->{FIO}; # ФИО строкой
    }

    $arr[13] = $User->{BIRTH_DATE};

    my ($passport_ser, $passport_num) = $User->{PASPORT_NUM} =~ m/(.*)\s(\d+)/;
    $passport_ser =~ s/\s//g if ($passport_ser);
    $User->{PASPORT_GRANT} =~ s/\n//g;
    $User->{PASPORT_GRANT} =~ s/\r//g;
    $arr[14] = 0;

    if ($passport_ser && $passport_num && $User->{PASPORT_GRANT}) {
      $arr[15] = '0';                                                                      # тип паспортных данных (0-структурировано, 1-одной строкой)
      $arr[16] = $passport_ser;                                                            # серия паспорта
      $arr[17] = $passport_num;                                                            # номер паспорта
      $arr[18] = $User->{PASPORT_GRANT} . " " . main::_date_format($User->{PASPORT_DATE}); # кем и когда выдан
      $arr[19] = "";                                                                       # паспортные данные строкой
    }
    else {
      $arr[15] = '1';                                                                               # тип паспортных данных (0-структурировано, 1-одной строкой)
      @arr[16 .. 18] = ("") x 3;                                                                    # кем и когда выдан
      $arr[19] = $User->{PASPORT_NUM} . " " . $User->{PASPORT_GRANT} . " " . $User->{PASPORT_DATE}; # паспортные данные строкой
    }

    @arr[20 .. 25] = ("") x 6; #MAGICK
  }
  else {
    $arr[7] = 43;
    @arr[8 .. 19] = ("") x 12;

    $Company->info($User->{COMPANY_ID});
    $arr[20] = $Company->{BANK_NAME};      # банк абонента
    $arr[21] = $Company->{BANK_ACCOUNT};   # номер счета абонента
    $arr[22] = $Company->{NAME};           # abonent-jur-fullname  наименование компании
    $arr[23] = $Company->{TAX_NUMBER};     # abonent-jur-inn ИНН
    $arr[24] = $Company->{REPRESENTATIVE}; # контактное лицо
    $arr[25] = $Company->{PHONE};          # контактный телефон
  }

  $arr[26] = $User->{DISABLE} ? 1 : 0;
  $arr[27] = main::_date_format($User->{REGISTRATION}) . ' 12:00:00';                                                        # дата активации основной услуги
  $arr[28] = ($User->{EXPIRE} ne '0000-00-00' && $User->{EXPIRE} lt $main::DATE) ? main::_date_format($User->{EXPIRE}) : ""; # дата отключения основной услуги
  $arr[29] = 4;
  $arr[30] = 1;

  _add_report("ABONENT", @arr);

  return 1;
}

#**********************************************************
=head2 ABONENT_IDENT_report()

=cut
#**********************************************************
sub ABONENT_IDENT_report {
  my $self = shift;
  my ($uid) = @_;

  $User->info($uid);
  if ($User->{errno}) {
    delete $User->{errno};
    return 0;
  }

  $User->pi({ UID => $uid });
  $Internet->user_info($uid);

  my @arr;

  my $sorm_id = $self->{conf}->{SORM_ISP_ID};
  $arr[0] = $uid;     #ID
  $arr[1] = $sorm_id; #REGION ID
  $arr[2] = 5;
  $arr[3] = $User->{PHONE};
  @arr[4 .. 9] = ("") x 6;
  $arr[10] = $Internet->{CID} ? 0 : '';
  $arr[11] = $Internet->{CID};
  @arr[12 .. 13] = ("") x 2;
  $arr[14] = $User->{LOGIN};
  $arr[15] = $User->{EMAIL};
  @arr[16 .. 19] = ("") x 4;

  my $ip = q{};
  my $bitmask = q{};

  if ($User->{_GIVE_NETWORK}) {
    ($ip, $bitmask) = split(/\//, $User->{_GIVE_NETWORK}, 2);
    $arr[20] = 0;
  }
  elsif ($Internet->{IP} && $Internet->{IP} ne '0.0.0.0') {
    $ip = $Internet->{IP};
    if ($Internet->{NETMASK}) {
      $bitmask = $Internet->{NETMASK};
    }
    $arr[20] = 0;
  }

  $arr[21] = $ip ? sprintf("0x%X", ip2int($ip)) : "";      # static IP
  $arr[22] = "";       # Static ipv6
  $arr[23] = $bitmask ? sprintf("0x%X", ip2int($bitmask)) : ""; # Mask
  $arr[24] = "";
  $arr[25] = main::_date_format($User->{REGISTRATION}) . ' 12:00:00';                                                        # дата активации основной услуги
  $arr[26] = ($User->{EXPIRE} ne '0000-00-00' && $User->{EXPIRE} lt $main::DATE) ? main::_date_format($User->{EXPIRE}) : ""; # дата отключения основной услуги
  @arr[27 .. 40] = ("") x 14;

  _add_report("ABONENT_IDENT", @arr);

  return 1;

}

#**********************************************************
=head2 ABONENT_SRV_report()

=cut
#**********************************************************
sub ABONENT_SRV_report {
  my $self = shift;
  my ($uid) = @_;

  $User->info($uid);
  if ($User->{errno}) {
    delete $User->{errno};
    return 0;
  }

  $User->pi({ UID => $uid });
  $Internet->user_info($uid);

  my @arr;

  my $sorm_id = $self->{conf}->{SORM_ISP_ID};
  $arr[0] = $uid;     #ID
  $arr[1] = $sorm_id; #REGION ID
  $arr[2] = 41;
  $arr[3] = main::_date_format($User->{REGISTRATION}) . ' 12:00:00';                                                        # дата активации основной услуги
  $arr[4] = ($User->{EXPIRE} ne '0000-00-00' && $User->{EXPIRE} lt $main::DATE) ? main::_date_format($User->{EXPIRE}) : ""; # дата отключения основной услуги
  $arr[5] = "";

  _add_report("ABONENT_SRV", @arr);

  return 1;
}

#**********************************************************
=head2 ABONENT_ADDR_report()

=cut
#**********************************************************
sub ABONENT_ADDR_report {
  my $self = shift;
  my ($uid) = @_;

  $User->info($uid);
  if ($User->{errno}) {
    delete $User->{errno};
    return 0;
  }

  $User->pi({ UID => $uid });
  $Internet->user_info($uid);

  my @arr;
  my $sorm_id = $self->{conf}->{SORM_ISP_ID};
  $arr[0] = $uid;     #ID
  $arr[1] = $sorm_id; #REGION ID
  $arr[2] = 0;
  $arr[3] = 1;
  @arr[4 .. 12] = ("") x 9;
  $self->{conf}->{BUILD_DELIMITER} = ', ' if (!defined($self->{conf}->{BUILD_DELIMITER}));
  $arr[13] = ($User->{CITY} && $User->{ADDRESS_FULL})
    ? "$User->{CITY}$self->{conf}->{BUILD_DELIMITER}$User->{ADDRESS_FULL}" : "";
  $arr[14] = main::_date_format($User->{REGISTRATION}) . ' 12:00:00';                                                        # дата активации основной услуги
  $arr[15] = ($User->{EXPIRE} ne '0000-00-00' && $User->{EXPIRE} lt $main::DATE) ? main::_date_format($User->{EXPIRE}) : ""; # дата отключения основной услуги

  _add_report("ABONENT_ADDR", @arr);

  return 1;
}

#**********************************************************
=head2 PAYMENT_report()

=cut
#**********************************************************
sub PAYMENT_report {
  my $self = shift;
  my ($id) = @_;

  my $payment = $Payments->list({
    COLS_NAME => 1,
    DATETIME  => '_SHOW',
    SUM       => '_SHOW',
    UID       => '_SHOW',
    ID        => $id,
  });

  $payment = $payment->[0];
  my $uid = $payment->{uid};
  $User->info($uid);
  if ($User->{errno}) {
    delete $User->{errno};
    return 0;
  }

  $User->pi({ UID => $uid });

  my @arr;
  my $sorm_id = $self->{conf}->{SORM_ISP_ID};
  $arr[0] = $sorm_id; #REGION ID
  $arr[1] = 86;
  $arr[2] = 282;
  $arr[3] = $payment->{datetime};
  $arr[4] = $payment->{sum};
  $arr[5] = "";
  $arr[6] = $User->{PHONE};
  $arr[7] = $User->{CONTRACT_ID} || $User->{LOGIN};
  $arr[8] = $uid;
  @arr[9 .. 38] = ("") x 30;

  _add_report("PAYMENT", @arr);

  return 1;
}

#**********************************************************
=head2 SUPPLEMENTARY_SERVICE_report()

=cut
#**********************************************************
sub SUPPLEMENTARY_SERVICE_report(){
  my $self = shift;

  _add_header("SUPPLEMENTARY_SERVICE");

  my $list = $Abon->tariff_list({ COLS_NAME => 1 });

  foreach (@$list) {
    my @arr;

    $arr[0] = $_->{tp_id};
    $arr[1] = $_->{tp_name};
    $arr[2] = "01.01.2010 21:00:00";
    $arr[3] = "30.12.2024 21:00:00";
    $arr[4] =  $_->{tp_name};
    $arr[5] = $self->{conf}->{SORM_ISP_ID};

    _add_report("SUPPLEMENTARY_SERVICE", @arr);
  }
  return 1;
}
#**********************************************************
=head2 PAY_TYPE_report()

=cut
#**********************************************************
sub PAY_TYPE_report {
  my $self = shift;

  _add_header("PAY_TYPE");

  do ("/usr/abills/language/russian.pl");
  my $types = translate_list($Payments->payment_type_list({ COLS_NAME => 1 }));

  if ($self->{conf}->{PAYSYS_PAYMENTS_METHODS}) {
    foreach my $line (split(';', $self->{conf}->{PAYSYS_PAYMENTS_METHODS})) {
      my ($id, $type) = split(':', $line);
      push(@$types, { id => $id, name => $type });
    }
  }

  foreach (@$types) {
    my @arr;
    $_->{id} =~ s/^\s+|\s+$//g;
    $arr[0] = $_->{id};
    $arr[1] = "01.01.2010 21:00:00";
    $arr[2] = "30.12.2024 21:00:00";
    $arr[3] = $_->{name};
    $arr[4] = $self->{conf}->{SORM_ISP_ID};

    _add_report("PAY_TYPE", @arr);
  }
  return 1;
}
#**********************************************************
=head2 DOC_TYPE_report()

=cut
#**********************************************************
sub DOC_TYPE_report {
  my $self = shift;

  _add_header("DOC_TYPE");
  my @arr;
  $arr[0] = 1;
  $arr[1] = "01.01.2010 21:00:00";
  $arr[2] = "30.12.2024 21:00:00";
  $arr[3] = "Паспорт";
  $arr[4] = $self->{conf}->{SORM_ISP_ID};

  _add_report("DOC_TYPE", @arr);

  return 1;
}

#**********************************************************
=head2 IP_PLAN_report()

=cut
#**********************************************************
sub IP_PLAN_report {
  my $self = shift;

  my $ip_pools = $Nas->ip_pools_list({
    COLS_NAME => 1,
  });

  _add_header("IP_PLAN");

  for (@$ip_pools) {
    my @arr;

    $arr[0] = $_->{name};
    $arr[1] = 0;
    $arr[2] = sprintf("%X", $_->{ip});
    $arr[3] = "";
    $arr[4] = sprintf("%X", $_->{netmask});
    $arr[5] = "";
    $arr[6] = "01.01.2010 21:00:00";
    $arr[7] = "30.12.2024 21:00:00";
    $arr[8] = $self->{conf}->{SORM_ISP_ID};

    _add_report("IP_PLAN", @arr);

  }
  return 1;
}

#**********************************************************
=head2 GATEWAY_report()

=cut
#**********************************************************
sub GATEWAY_report {
  my $self = shift;

  my $nas_list = $Nas->list({
    COLS_NAME    => 1,
    NAS_ID       => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    DESCR        => '_SHOW',
  });

  _add_header("GATEWAY");

  for (@$nas_list) {
    my @arr;

    $arr[0] = $_->{nas_id};
    $arr[1] = "01.01.2010 21:00:00";
    $arr[2] = "30.12.2024 21:00:00";
    $arr[3] = $_->{descr};
    $arr[4] = 5;
    $arr[6] = 0;
    $arr[7] = 1;
    @arr[8 .. 15] = ("") x 8;
    $arr[16] = $_->{address_full};
    $arr[17] = $self->{conf}->{SORM_ISP_ID};

    _add_report("GATEWAY", @arr);
  }


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

  my $filename = $reports{$type};

  my $string = "";
  foreach (@params) {
    $string .= ($_ // "") . ';';
  }
  $string =~ s/;$/\n/;

  open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
  print $fh $string;
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
    ABONENT               => [ 'ID', 'REGION_ID', 'CONTRACT_DATE', 'CONTRACT', 'ACCOUNT', 'ACTUAL_FROM', 'ACTUAL_TO', 'ABONENT_TYPE',
      'NAME_INFO_TYPE', 'FAMILY_NAME', 'GIVEN_NAME', 'INITIAL_NAME', 'UNSTRUCT_NAME', 'BIRTH_DATE', 'IDENT_CARD_TYPE_ID',
      'IDENT_CARD_TYPE', 'IDENT_CARD_SERIAL', 'IDENT_CARD_NUMBER', 'IDENT_CARD_DESCRIPTION', 'IDENT_CARD_UNSTRUCT',
      'BANK', 'BANK_ACCOUNT', 'FULL_NAME', 'INN', 'CONTACT', 'PHONE_FAX', 'STATUS', 'DETACH', 'NETWORK_TYPE',
      'RECORD_ACTION' ],
    ABONENT_IDENT         => [ 'ABONENT_ID', 'REGION_ID', 'IDENT_TYPE', 'PHONE', 'INTERNAL_NUMBER', 'IMSI',
      'IMEI', 'ICC', 'MIN', 'ESN', 'EQUIPMENT_TYPE', 'MAC', 'VPI', 'VCI', 'LOGIN', 'E_MAIL', 'PIN', 'USER_DOMAIN',
      'RESERVED', 'ORIGINATOR_NAME', 'IP_TYPE', 'IPV4', 'IPV6', 'IPV4_MASK', 'IPV6_MASK', 'BEGIN_TIME',
      'END_TIME', 'LINE_OBJECT', 'LINE_CROSS', 'LINE_BLOCK', 'LINE_PAIR', 'LINE_RESERVED', 'LOC_TYPE',
      'LOC_LAC', 'LOC_CELL', 'LOC_TA', 'LOC_CELL_WIRELESS', 'LOC_MAC', 'LOC_LATITUDE', 'LOC_LONGITUDE',
      'LOC_PROJECTION_TYPE' ],
    ABONENT_SRV           => [
      'ABONENT_ID', 'REGION_ID', 'ID', 'BEGIN_TIME', 'END_TIME', 'PARAMETER'
    ],
    ABONENT_ADDR          => [
      'ABONENT_ID', 'REGION_ID', 'ADDRESS_TYPE_ID', 'ADDRESS_TYPE', 'ZIP', 'COUNTRY', 'REGION', 'ZONE', 'CITY',
      'STREET', 'BUILDING', 'BUILD_SECT', 'APARTMENT', 'UNSTRUCT_INFO', 'BEGIN_TIME', 'END_TIME'
    ],
    PAYMENT               => [
      'REGION_ID', 'PAYMENT_TYPE', 'PAY_TYPE_ID', 'PAYMENT_DATE', 'AMOUNT', 'AMOUNT_CURRENCY', 'PHONE_NUMBER',
      'ACCOUNT', 'ABONENT_ID', 'BANK_ACCOUNT', 'BANK_NAME', 'EXPRESS_CARD_NUMBER', 'TERMINAL_ID',
      'TERMINAL_NUMBER', 'LATITUDE', 'LONGITUDE', 'PROJECTION_TYPE', 'CENTER_ID', 'DONATED_PHONE_NUMBER',
      'DONATED_ACCOUNT', 'DONATED_INTERNAL_ID1', 'DONATED_INTERNAL_ID2', 'CARD_NUMBER', 'PAY_PARAMS', 'PERSON_RECIEVED'
      , 'BANK_DIVISION_NAME', 'BANK_CARD_ID', 'ADDRESS_TYPE_ID', 'ADDRESS_TYPE', 'ZIP', 'COUNTRY', 'REGION', 'ZONE',
      'CITY', 'STREET', 'BUILDING', 'BUILD_SECT', 'APARTMENT', 'UNSTRUCT_INFO'
    ],
    PAY_TYPE              => [
      'ID', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'REGION_ID'
    ],
    DOC_TYPE              => [
      'DOC_TYPE_ID', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'REGION_ID'
    ],
    IP_PLAN               => [
      'DESCRIPTION', 'IP_TYPE', 'IPV4', 'IPV6', 'IP_MASK_TYPE', 'IPV4_MASK', 'IPV6_MASK',
      'BEGIN_TIME', 'END_TIME', 'REGION_ID'
    ],
    GATEWAY               => [
      'GATE_ID', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'GATE_TYPE', 'ADDRESS_TYPE_ID',
      'ADDRESS_TYPE', 'ZIP', 'COUNTRY', 'REGION', 'ZONE', 'CITY', 'STREET', 'BUILDING', 'BUILD_SECT',
      'APARTMENT', 'UNSTRUCT_INFO', 'REGION_ID'
    ],
    SUPPLEMENTARY_SERVICE => [
      'ID', 'MNEMONIC', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'REGION_ID'
    ]
  );

  my $string = "";
  foreach (@{$headers{$type}}) {
    $string .= ($_ // "") . ';';
  }
  $string =~ s/;$/\n/;

  my $filename = $reports{$type};

  open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
  print $fh $string;
  close $fh;

  return 1;
}

#**********************************************************
=head2 send()

=cut
#**********************************************************
sub send {
  my $self = shift;

  for (values %reports){

    if(-e $_) {
      main::_ftp_upload({
        DIR   => "/",
        FILE  => $_
      });

      unlink $_;
    }

  }

  return 1;
}


1;