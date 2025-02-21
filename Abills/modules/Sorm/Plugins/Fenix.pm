package Sorm::Plugins::Fenix;

=head1 NAME

  Fenix SORM

=head1 DOCS

  version: v3.3

=head1 VERSION

  VERSION: 0.39
  UPDATE: 20240902

=cut

use strict;
use warnings FATAL => 'all';

use Companies;
use Time::Piece;
use Abills::Misc qw(translate_list);
use Abills::Base qw(in_array ip2int);
use Abon;

my ($User, $Company, $Internet, $Sessions, $Nas, $Abon, $debug);

my Payments $Payments;
my %online_mac = ();

my $service_begin_date = '2010-01-01 01:00:00';
my $service_end_date = '2030-12-31 23:59:59';
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
  SUPPLEMENTARY_SERVICE => "$main::var_dir/sorm/Fenix/SUPPLEMENTARY_SERVICE_" . $sufix,
  REGIONS               => "$main::var_dir/sorm/Fenix/REGIONS_" . $sufix,
);

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
  $Sessions = Internet::Sessions->new($self->{db}, $self->{admin}, $self->{conf});
  $Payments = Finance->payments($self->{db}, $self->{admin}, $self->{conf});
  $Nas = Nas->new($self->{db}, $self->{admin}, $self->{conf});
  $Abon = Abon->new($self->{db}, $self->{admin}, $self->{conf});

  my $argv = $self->{argv};

  my $online_list = $Sessions->online({ CID => '_SHOW' });

  foreach my $online (@$online_list) {
    $online_mac{$online->{uid}}=$online->{cid};
  }

  if ($argv->{START}) {
    mkdir($main::var_dir . '/sorm/');
    mkdir($main::var_dir . '/sorm/Fenix');

    my $users_list = $User->list({
      COLS_NAME => 1,
      PAGE_ROWS => 99999,
      DELETED   => 0,
      DISABLE   => 0,
    });

    _add_header('ABONENT');
    _add_header('ABONENT_IDENT');
    _add_header('ABONENT_SRV');
    _add_header('ABONENT_ADDR');

    foreach my $u (@$users_list) {
      $self->ABONENT_report($u->{uid});
      $self->ABONENT_IDENT_report($u->{uid});
      $self->ABONENT_SRV_report($u->{uid});
      $self->ABONENT_ADDR_report($u->{uid});
    }

    my $payments = $Payments->list({
      COLS_NAME => 1,
      PAGE_ROWS => 99999,
      DATE      => '>' . $service_begin_date,
      ID        => '_SHOW',
      SORT      => 'id',
      DESC      => 'DESC'
    });

    _add_header("PAYMENT");
    foreach my $p (@$payments) {
      $self->PAYMENT_report($p->{id});
    }

    $self->PAY_TYPE_report();
    $self->DOC_TYPE_report();
    $self->IP_PLAN_report();
    $self->GATEWAY_report();
    if (in_array('Abon', \@main::MODULES)) {
      $self->SUPPLEMENTARY_SERVICE_report();
    }

    $self->REGIONS_report();

    $self->send();
  }

  return 1;
}

#**********************************************************
=head2 REGIONS_report()

=cut
#**********************************************************
sub REGIONS_report {
  my $self = shift;

  _add_header('REGIONS');

  my @arr = (
    $self->{conf}->{SORM_ISP_ID}, # ID
    $service_begin_date, # BEGIN_TIME
    $service_end_date, # END_TIME
    $self->{conf}->{SORM_ISP_DESCRIPTION}, # DESCRIPTION
    '', # MCC
    '', # MNC
  );

  _add_report("REGIONS", @arr);

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

  my @arr = ();

  $User->pi({ UID => $uid });

  my ($family, $name, $surname) = ($User->{FIO}, $User->{FIO2}, $User->{FIO3});
  ($family, $name, $surname) = split(' ', $User->{FIO}) if (!$name || !$surname);

  my $sorm_id = $self->{conf}->{SORM_ISP_ID};

  $arr[0] = $uid;                                                                 #ID
  $arr[1] = $sorm_id;                                                             #REGION ID
  $arr[2] = $User->{REGISTRATION} . ' 12:00:00';                                  #CONTRACT_DATE
  $arr[3] = $User->{CONTRACT_ID} || $User->{LOGIN};                               #CONTRACT
  $arr[4] = $User->{INVOICE_NUM} || $User->{CONTRACT_ID} || $User->{LOGIN} || ''; #ACCOUNT
  $arr[5] = $User->{REGISTRATION} . ' 12:00:00';                                  # дата активации основной услуги
  $arr[6] = '2025-01-01 12:00:00';
  #ФИЗ. Лицо
  if (!$User->{COMPANY_ID}) {
    $arr[7] = 42;

    if ($name && $surname && $family) {
      $arr[8] = 0;         # тип ФИО (0-структурировано, 1 - одной строкой)
      $arr[9] = $family;   # фамилия
      $arr[10] = $name;    # имя
      $arr[11] = $surname; # отчество
      $arr[12] = "";       # ФИО строкой
    }
    else {
      $arr[8] = 1; # тип ФИО (0-структурировано, 1 - одной строкой)
      @arr[9 .. 11] = ("") x 3;
      $arr[12] = $User->{FIO} || q{}; #UNSTRUCT_NAME ФИО строкой
      $arr[12] =~ s/[\"\'<>]+//g;
    }

    $arr[13] = $User->{BIRTH_DATE} || q{}; # BIRTH_DATE;

    my ($passport_ser, $passport_num) = $User->{PASPORT_NUM} =~ m/(.*)\s(\d+)/;
    $passport_ser =~ s/\s//g if ($passport_ser);
    $User->{PASPORT_GRANT} =~ s/\n//g;
    $User->{PASPORT_GRANT} =~ s/\r//g;
    $arr[14] = 0;

    if ($passport_ser && $passport_num && $User->{PASPORT_GRANT}) {
      $arr[15] = '0';                                                  # IDENT_CARD_TYPE тип паспортных данных (0-структурировано, 1-одной строкой)
      $arr[16] = $passport_ser;                                        # серия паспорта
      $arr[17] = $passport_num;                                        # номер паспорта
      $arr[18] = $User->{PASPORT_GRANT} . " " . $User->{PASPORT_DATE}; # кем и когда выдан
      $arr[19] = "";                                                   # IDENT_CARD_UNSTRUCT паспортные данные строкой
    }
    else {
      $arr[15] = '1';                                                                               # тип паспортных данных (0-структурировано, 1-одной строкой)
      @arr[16 .. 18] = ("") x 3;                                                                    # кем и когда выдан
      $arr[19] = (($User->{PASPORT_NUM}) ? $User->{PASPORT_NUM} . " " : q{})
        . (($User->{PASPORT_GRANT}) ? $User->{PASPORT_GRANT} . " " : q{})
        . (($User->{PASPORT_DATE} && $User->{PASPORT_DATE} ne '0000-00-00') ? $User->{PASPORT_DATE} : q{}) ; # IDENT_CARD_UNSTRUCT  паспортные данные строкой
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
  $arr[27] = $User->{REGISTRATION} . ' 12:00:00';                                                        # дата активации основной услуги
  $arr[28] = ($User->{EXPIRE} ne '0000-00-00' && $User->{EXPIRE} lt $main::DATE) ? $User->{EXPIRE} : $service_end_date; # дата отключения основной услуги
  $arr[29] = 4;
  $arr[30] = 1;
  $arr[31] = '';

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

  #TODO: FIX ME
  if ($Internet->can('user_info')) {
    $Internet->user_info($uid);
  }
  else {
    $Internet->info($uid);
  }

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
  $arr[14] = $online_mac{$uid} || $User->{LOGIN};
  my $email = $User->{EMAIL} || q{};
  $email =~ s/^\s+|\s+$//g;
  $arr[15] = $email; # E_MAIL
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

  $arr[21] = ($ip) ? sprintf("%X", ip2int($ip)) : "";           # static IP
  $arr[22] = "";                                                # Static ipv6
  $arr[23] = ($bitmask) ? sprintf("%X", ip2int($bitmask)) : ""; # Mask
  $arr[24] = "";
  $arr[25] = $User->{REGISTRATION} . ' 12:00:00';             # дата активации основной услуги
  $arr[26] = ($User->{EXPIRE} ne '0000-00-00' && $User->{EXPIRE} lt $main::DATE) ? $User->{EXPIRE} : $service_end_date; # дата отключения основной услуги
  @arr[27 .. 40] = ("") x 14;

  $arr[41] = 1;

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
  #TODO: FIX ME
  if ($Internet->can('user_info')) {
    $Internet->user_info($uid);
  }
  else {
    $Internet->info($uid);
  }

  my @arr = ();

  my $sorm_id = $self->{conf}->{SORM_ISP_ID};
  $arr[0] = $uid;     #ID
  $arr[1] = $sorm_id; #REGION ID
  $arr[2] = 10; #Internet
  $arr[3] = $User->{REGISTRATION} . ' 12:00:00';                                                        # дата активации основной услуги
  $arr[4] = ($User->{EXPIRE} && $User->{EXPIRE} ne '0000-00-00' && $User->{EXPIRE} lt $main::DATE) ? $User->{EXPIRE}. ' 23:59:59' : $service_end_date; # дата отключения основной услуги
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
  #TODO: FIX ME
  if ($Internet->can('user_info')) {
    $Internet->user_info($uid);
  }
  else {
    $Internet->info($uid);
  }

  my @arr;
  my $sorm_id = $self->{conf}->{SORM_ISP_ID};
  $arr[0] = $uid;     #ID
  $arr[1] = $sorm_id; #REGION ID
  $arr[2] = 0;
  $arr[3] = 0; # ADDRESS_TYPE

  if ($arr[3]) {
    @arr[4 .. 12] = ("") x 9;
    $self->{conf}->{BUILD_DELIMITER} = ', ' if (!defined($self->{conf}->{BUILD_DELIMITER}));
    my $address_full =($User->{CITY} && $User->{ADDRESS_FULL})
      ? "$User->{CITY}$self->{conf}->{BUILD_DELIMITER}$User->{ADDRESS_FULL}" : "";
    $address_full =~ s/^\s+|\s+$//g;
    $arr[13] = $address_full # UNSTRUCT_INFO
  }
  else {
    $arr[4]=$User->{ZIP} || q{};		# ZIP	STRING (1 .. 32)
    $arr[5]=$User->{COUNTRY} || q{};		# COUNTRY	STRING (1 .. 128)
    $arr[6]=q{};		# REGION	STRING (1 .. 128)
    $arr[7]=q{};		# ZONE	STRING (1 .. 128)
    $arr[8]=$User->{CITY}	|| q{};		# CITY	STRING (1 .. 128)
    $arr[9]=$User->{ADDRESS_STREET}	|| q{};	# STREET	STRING (1 .. 128)
    $arr[10]=$User->{ADDRESS_BUILD}	|| q{};	# BUILDING	STRING (1 .. 128)
    $arr[11]="";		# BUILD_SECT	STRING (1 .. 128)
    $arr[12]=$User->{APPARTMENT} || q{}	;	# APARTMENT	STRING (1 .. 128)
    $arr[13]=q{};
  }

  $arr[14] = $User->{REGISTRATION} . ' 12:00:00';                                                        # дата активации основной услуги
  $arr[15] = ($User->{EXPIRE} ne '0000-00-00' && $User->{EXPIRE} lt $main::DATE) ? $User->{EXPIRE} : $service_end_date; # дата отключения основной услуги

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
    METHOD    => '_SHOW',
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

  my @arr = ();
  my $sorm_id = $self->{conf}->{SORM_ISP_ID};
  $arr[0] = $sorm_id; #REGION ID
  $arr[1] = 86;
  $arr[2] = $payment->{method}; # PAY_TYPE_ID
  $arr[3] = $payment->{datetime};
  $arr[4] = $payment->{sum};
  $arr[5] = "";
  $arr[6] = ($User->{PHONE} && $User->{PHONE} =~ /[0-9]+/) ? $User->{PHONE} : q{};
  $arr[7] = $User->{CONTRACT_ID} || $User->{LOGIN};
  $arr[8] = $uid;
  @arr[9 .. 38] = ("") x 30;
  $arr[39]=1; # RECORD_ACTION
  _add_report("PAYMENT", @arr);

  return 1;
}

#**********************************************************
=head2 SUPPLEMENTARY_SERVICE_report()

=cut
#**********************************************************
sub SUPPLEMENTARY_SERVICE_report() {
  my $self = shift;

  _add_header("SUPPLEMENTARY_SERVICE");

  my $tp_list = $Abon->tariff_list({
    COLS_NAME => 1,
  });

  my %tp_list = (
    10 => 'интернет',
    20 => 'телефония',
    30 => 'телевидение',
  );

  foreach my $tp_num (sort keys %tp_list) {
    my @arr = ();

    #$tp->{name} =~ s/[\(\)]+//g;

    $arr[0] = $tp_num;
    $arr[1] = $tp_list{$tp_num};
    $arr[2] = "2010-01-01 21:00:00";
    $arr[3] = "2025-12-31 21:00:00";
    $arr[4] = $tp_list{$tp_num};
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

  # Old function
  # if ($self->{conf}->{PAYSYS_PAYMENTS_METHODS}) {
  #   foreach my $line (split(';', $self->{conf}->{PAYSYS_PAYMENTS_METHODS})) {
  #     my ($id, $type) = split(':', $line);
  #     push(@$types, { id => $id, name => $type });
  #   }
  # }

  foreach my $type (@$types) {
    my @arr;
    $type->{id} =~ s/^\s+|\s+$//g;
    $arr[0] = $type->{id} || 0;
    $arr[1] = "2010-01-01 21:00:00";
    $arr[2] = "2025-12-31 21:00:00";
    $arr[3] = $type->{name};
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
  my @arr = ();
  $arr[0] = 0;
  $arr[1] = "2010-01-01 21:00:00";
  $arr[2] = "2025-12-31 21:00:00";
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

  $Nas->{debug}=1 if ($self->{debug} && $self->{debug} > 3);
  my $ip_pools = $Nas->nas_ip_pools_list({
    IP        => '_SHOW',
    POOL_NAME => '_SHOW',
    NETMASK   => '_SHOW',
    COLS_NAME => 1,
  });

  _add_header("IP_PLAN");

  for my $pool (@$ip_pools) {
    my @arr = ();

    $arr[0] = $pool->{pool_name};
    $arr[1] = 0;
    $arr[2] = sprintf("%8X", $pool->{ip});
    $arr[3] = "";
    $arr[4] = sprintf("%X", $pool->{netmask});
    $arr[5] = "";
    $arr[6] = "2010-01-01 21:00:00";
    $arr[7] = "2025-12-31 21:00:00";
    $arr[8] = $self->{conf}->{SORM_ISP_ID};

    _add_report("IP_PLAN", @arr);
  }

  return 1;
}

#**********************************************************
=head2 static_report($type)

  Argumnets:
    $type Report type

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub static_report {
  my ($type)=@_;

  if (! -f "$main::var_dir/sorm/Fenix/static/$type" ) {
    return 0;
  }

  #_log("LOG_INFO", "static_reports: $type");

  my $content = q{};
  open(my $fh, '<', "$main::var_dir/sorm/Fenix/static/$type");
    $content = <$fh>;
  close($fh);

  _save_report($type, $content);

  return 1;
}

#**********************************************************
=head2 GATEWAY_report()

=cut
#**********************************************************
sub GATEWAY_report {
  my $self = shift;

  _add_header("GATEWAY");
  if (static_report('GATEWAY')) {
    return 1;
  }

  my $nas_list = $Nas->list({
    COLS_NAME    => 1,
    NAS_ID       => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    DESCR        => '_SHOW',
    PAGE_ROWS    => 60000,
  });

  for my $nas (@$nas_list) {
    my @arr = ();

    $arr[0] = $nas->{nas_id};
    $arr[1] = "2010-01-01 21:00:00";
    $arr[2] = "2025-12-31 21:00:00";
    $arr[3] = $nas->{descr};
    $arr[4] = 5;
    $arr[6] = 1; #ADDRESS_TYPE 1 - Unstructure
    $arr[7] = 1;
    @arr[8 .. 15] = ("") x 8;
    $arr[16] = $nas->{address_full};
    $arr[17] = $self->{conf}->{SORM_ISP_ID};

    _add_report("GATEWAY", @arr);
  }

  return 1;
}

#**********************************************************
=head2 GATEWAY_report()

=cut
#**********************************************************
sub IP_GATEWAY_report {
  my $self = shift;

  _add_header("IP_GATEWAY");

  if (static_report('IP_GATEWAY')) {
    return 1;
  }

  my $nas_list = $Nas->list({
    NAS_ID       => '_SHOW',
    NAS_IP       => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    DESCR        => '_SHOW',
    PAGE_ROWS    => 60000,
    COLS_NAME    => 1,
  });

  for my $nas (@$nas_list) {
    my @arr = ();

    $arr[0] = $nas->{nas_id};
    $arr[1] = 0;
    $arr[2] = sprintf("%X", ip2int($nas->{ip}));
    $arr[3] = 0;
    $arr[4] = "";
    $arr[6] = $self->{conf}->{SORM_ISP_ID};

    _add_report("IP_GATEWAY", @arr);
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

  my $string = "";
  foreach my $line (@params) {
    $line //= q{};
    $line =~ s/;/ /;
    $string .= $line . ';';
  }

  $string =~ s/\r/ /g;
  $string =~ s/\n/ /g;
  $string =~ s/\t/ /g;
  $string =~ s/;$/\n/;

  # if ($debug > 3) {
  #   print "TYPE: $type\n";
  # }

  _save_report($type, $string);

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
sub _save_report {
  my($type, $content)=@_;

  if ($debug > 5) {
    print "$content\n";
  }

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
    ABONENT               => [ 'ID', 'REGION_ID', 'CONTRACT_DATE', 'CONTRACT', 'ACCOUNT', 'ACTUAL_FROM', 'ACTUAL_TO', 'ABONENT_TYPE',
      'NAME_INFO_TYPE', 'FAMILY_NAME', 'GIVEN_NAME', 'INITIAL_NAME', 'UNSTRUCT_NAME', 'BIRTH_DATE', 'IDENT_CARD_TYPE_ID',
      'IDENT_CARD_TYPE', 'IDENT_CARD_SERIAL', 'IDENT_CARD_NUMBER', 'IDENT_CARD_DESCRIPTION', 'IDENT_CARD_UNSTRUCT',
      'BANK', 'BANK_ACCOUNT', 'FULL_NAME', 'INN', 'CONTACT', 'PHONE_FAX', 'STATUS', 'ATTACH', 'DETACH', 'NETWORK_TYPE',
      'RECORD_ACTION', 'INTERNAL_ID1' ],
    ABONENT_IDENT         => [ 'ABONENT_ID', 'REGION_ID', 'IDENT_TYPE', 'PHONE', 'INTERNAL_NUMBER', 'IMSI',
      'IMEI', 'ICC', 'MIN', 'ESN', 'EQUIPMENT_TYPE', 'MAC', 'VPI', 'VCI', 'LOGIN', 'E_MAIL', 'PIN', 'USER_DOMAIN',
      'RESERVED', 'ORIGINATOR_NAME', 'IP_TYPE', 'IPV4', 'IPV6', 'IPV4_MASK', 'IPV6_MASK', 'BEGIN_TIME',
      'END_TIME', 'LINE_OBJECT', 'LINE_CROSS', 'LINE_BLOCK', 'LINE_PAIR', 'LINE_RESERVED', 'LOC_TYPE',
      'LOC_LAC', 'LOC_CELL', 'LOC_TA', 'LOC_CELL_WIRELESS', 'LOC_MAC', 'LOC_LATITUDE', 'LOC_LONGITUDE',
      'LOC_PROJECTION_TYPE',
      'RECORD_ACTION',
      'INTERNAL_ID1',
      'INTERNAL_ID2'
    ],
    ABONENT_SRV           => [
      'ABONENT_ID', 'REGION_ID', 'ID', 'BEGIN_TIME', 'END_TIME', 'PARAMETER',
      'SRV_CONTRACT',
      'RECORD_ACTION',
      'INTERNAL_ID1',
      'INTERNAL_ID2'
    ],
    ABONENT_ADDR          => [
      'ABONENT_ID', 'REGION_ID', 'ADDRESS_TYPE_ID', 'ADDRESS_TYPE', 'ZIP', 'COUNTRY', 'REGION', 'ZONE', 'CITY',
      'STREET', 'BUILDING', 'BUILD_SECT', 'APARTMENT', 'UNSTRUCT_INFO', 'BEGIN_TIME', 'END_TIME',
      'RECORD_ACTION',
      'INTERNAL_ID1',
      'INTERNAL_ID2'
    ],
    PAYMENT               => [
      'REGION_ID', 'PAYMENT_TYPE', 'PAY_TYPE_ID', 'PAYMENT_DATE', 'AMOUNT', 'AMOUNT_CURRENCY', 'PHONE_NUMBER',
      'ACCOUNT', 'ABONENT_ID', 'BANK_ACCOUNT', 'BANK_NAME', 'EXPRESS_CARD_NUMBER', 'TERMINAL_ID',
      'TERMINAL_NUMBER', 'LATITUDE', 'LONGITUDE', 'PROJECTION_TYPE', 'CENTER_ID', 'DONATED_PHONE_NUMBER',
      'DONATED_ACCOUNT', 'DONATED_INTERNAL_ID1', 'DONATED_INTERNAL_ID2', 'CARD_NUMBER', 'PAY_PARAMS', 'PERSON_RECIEVED'
      , 'BANK_DIVISION_NAME', 'BANK_CARD_ID', 'ADDRESS_TYPE_ID', 'ADDRESS_TYPE', 'ZIP', 'COUNTRY', 'REGION', 'ZONE',
      'CITY', 'STREET', 'BUILDING', 'BUILD_SECT', 'APARTMENT', 'UNSTRUCT_INFO',
      'RECORD_ACTION'
    ],
    PAY_TYPE              => [
      'ID', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'REGION_ID'
    ],
    DOC_TYPE              => [
      'DOC_TYPE_ID', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'REGION_ID'
    ],
    IP_PLAN               => [
      'DESCRIPTION', 'IP_TYPE', 'IPV4', 'IPV6', 'IPV4_MASK', 'IPV6_MASK',
      'BEGIN_TIME', 'END_TIME', 'REGION_ID'
    ],
    GATEWAY               => [
      'GATE_ID', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'GATE_TYPE', 'ADDRESS_TYPE_ID',
      'ADDRESS_TYPE', 'ZIP', 'COUNTRY', 'REGION', 'ZONE', 'CITY', 'STREET', 'BUILDING', 'BUILD_SECT',
      'APARTMENT', 'UNSTRUCT_INFO', 'REGION_ID'
    ],
    IP_GATEWAY            => [
      'GATE_ID', 'IP_TYPE', 'IPV4', 'IPV6', 'IP_PORT', 'REGION_ID'
    ],
    SUPPLEMENTARY_SERVICE => [
      'ID', 'MNEMONIC', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'REGION_ID'
    ],
    'REGIONS'             => [
      'ID', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'MCC', 'MNC'
    ]
  );

  my $string = "";
  foreach (@{$headers{$type}}) {
    $string .= ($_ // "") . ';';
  }
  $string =~ s/;$/\n/;

  _save_report($type, $string);

  return 1;
}

#**********************************************************
=head2 send()

=cut
#**********************************************************
sub send {
  my $self = shift;

  for my $report (values %reports) {
    if (-e $report) {
      main::_ftp_upload({
        DIR  => "/",
        FILE => $report
      });

      if ($debug < 3) {
        unlink $report;
      }
    }
  }

  return 1;
}


1;