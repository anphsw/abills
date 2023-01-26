package Sorm::Uzb;

=head1 NAME

  Module SORM for Uzbekistan

=head1 DOCS

  version: v1.3

=head1 VERSION

  VERSION: 1.3
  UPDATE: 20221218

=cut

use strict;
use warnings FATAL => 'all';

use Companies;
use Time::Piece;
use Abills::Misc qw(translate_list);
use Abills::Base qw(in_array ip2int);

my ($User, $Company, $Internet, $Sessions, $Nas, $debug);
my Payments $Payments;
my %online_mac = ();

my $service_begin_date = '2010-01-01 01:00:00';
my $service_end_date = '2049-12-31 23:59:59';
my $t = localtime;

my $month = sprintf("%02d", $t->mon());
my $year  = sprintf("%04d", $t->year());
my $day   = sprintf("%02d", $t->mday());
my $hour  = sprintf("%02d", $t->hour());
my $min   = sprintf("%02d", $t->min());

my $sufix = $year . $month . $day . "_" . $hour . $min . ".txt";
my $sorm_id = '';
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
  $Sessions = Internet::Sessions->new($self->{db}, $self->{admin}, $self->{conf});
  $Payments = Finance->payments($self->{db}, $self->{admin}, $self->{conf});
  $Nas = Nas->new($self->{db}, $self->{admin}, $self->{conf});

  my $argv = $self->{argv};
  $sorm_id = $self->{conf}->{SORM_ISP_ID};

  if (!$sorm_id){
    print "Please add REGION_ID to \$conf{SORM_ISP_ID} in config.pl \n";
    return 1;
  }

  my $online_list = $Sessions->online({ CID => '_SHOW' });

  foreach my $online (@$online_list) {
    $online_mac{$online->{uid}}=$online->{cid};
  }

  if ($argv->{START}) {
    mkdir($main::var_dir . '/sorm/');
    mkdir($main::var_dir . '/sorm/UZB/');
    mkdir($main::var_dir . '/sorm/UZB/'.$sorm_id);

    # ABONENT
    my $users_list = $User->list({
      COLS_NAME => 1,
      PAGE_ROWS => 99999,
      DELETED   => 0,
      DISABLE   => 0,
    });

    _add_header('ABONENT');

    foreach my $u (@$users_list) {
      $self->ABONENT_report($u->{uid});
    }

    # PAYMENT
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

    # CONNECTION
    _add_header('CONNECTION');
    $self->CONNECTION_report();

    # BASE_STATION
    _add_header('BASE_STATION');
    $self->BASE_STATION_report();

    # _add_header('NAT');
    # $self->NAT_report();

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

  $User->pi({ UID => $uid });
  $Company->info($User->{COMPANY_ID});

  my ($family, $name, $surname) = ($User->{FIO}, $User->{FIO2}, $User->{FIO3});
  ($family, $name, $surname) = split(' ', $User->{FIO}) if (!$name || !$surname);

  my @arr = ();

  $arr[0] = $sorm_id;                               # REGION ID
  $arr[1] = $User->{REGISTRATION} . ' 12:00:00';    # ACTUAL_FROM
  $arr[2] = '2030-01-01 12:00:00';                  # ACTUAL_TO
  $arr[3] = $User->{REGISTRATION} . ' 12:00:00';    # CONTRACT_DATE
  $arr[4] = $User->{BILL_ID};                       # ACCOUNT
  $arr[5] = $User->{CONTRACT_ID} || $User->{LOGIN}; # CONTRACT
  $arr[6] = ($User->{COMPANY_ID} > 0) ? $Company->{BANK_NAME}    : '';         # BANK
  $arr[7] = ($User->{COMPANY_ID} > 0) ? $Company->{BANK_ACCOUNT} : '';         # BANK_ACCOUNT
  $arr[8] = $User->{FIO} || q{};                     # UNSTRUCT_NAME
   $arr[8] =~ s/[\"\'<>]+//g;
  $arr[9] = ($User->{BIRTH_DATE} ne '0000-00-00') ? $User->{BIRTH_DATE} : q{};  # BIRTH_DAY
  $arr[10] = '';                                      # IDENT_CARD_TYPE_ID

  my $passport = $User->{PASPORT_NUM} || q{};
  $passport =~ s/\s//g if ($passport);
  my $passport_grant = $User->{PASPORT_GRANT} || q{};
  $passport_grant =~ s/\n//g if ($passport_grant);
  $passport_grant =~ s/\r//g if ($passport_grant);
  my $passport_date = ($User->{PASPORT_DATE} ne '0000-00-00') ? $User->{PASPORT_DATE} : '';

  $arr[11] = "$passport $passport_grant $passport_date";                # IDENT_CARD_UNSTRUCT

  # COMPANY
  $arr[12] = ($User->{COMPANY_ID} > 0) ? $Company->{NAME}           : ''; # FULL_NAME
  $arr[13] = ($User->{COMPANY_ID} > 0) ? $Company->{TAX_NUMBER}     : ''; # INN
  $arr[14] = ($User->{COMPANY_ID} > 0) ? $Company->{REPRESENTATIVE} : ''; # CONTACT
  $arr[15] = ($User->{COMPANY_ID} > 0) ? $Company->{PHONE}          : ''; # PHONE_FAX

  if ($Internet->can('user_info')) {
    $Internet->user_info($uid);
  }
  else {
    $Internet->info($uid);
  }

  $arr[16] = $Internet->{CID};      # MAC
  $arr[17] = $Internet->{IP};       # IPV4
  $arr[18] = $Internet->{NETMASK};  # IPV4_MASK
  $arr[19] = $User->{LOGIN};        # LOGIN
  my $email = $User->{EMAIL} || q{};
  $email =~ s/^\s+|\s+$//g;
  $arr[20] = $email;                # E-MAIL
  $arr[21] = $User->{PHONE};        # PHONE
  my $zip = $User->{ZIP} || q{};
  my $country = 'Узбекистан';
  my $region = $User->{REGION} || q{};
  my $city = $User->{CITY} || q{};
  my $address_street = $User->{ADDRESS_STREET} || q{};
  my $address_build = $User->{ADDRESS_BUILD} || q{};
  my $flat = $User->{APPARTMENT} || q{};
  $arr[22] = "$zip $country $region $city $address_street $address_build $flat"; # A_UNSTRUCT_INFO
  $arr[23] = '';                    # H_UNSTRUCT_INFO


  _add_report("ABONENT", @arr);

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
  DSC       => '_SHOW',
  CURRENCY  => '_SHOW',
  ID        => $id,
  });

  $payment = $payment->[0];
  my $uid = $payment->{uid};

  my $payment_type = 86;
  $payment_type = 83 if($payment->{method} == 0); # cash
  $payment_type = 80 if($payment->{method} == 1); # bank

  $User->info($uid);
  if ($User->{errno}) {
    delete $User->{errno};
    return 0;
  }

  $User->pi({ UID => $uid });

  my @arr = ();

  $arr[0] = $payment_type; # PAYMENT_TYPE
  $arr[1] = $payment->{dsc}; # PAY_TYPE_ID
  $arr[2] = $payment->{datetime}; # PAYMENT_DATE
  $arr[3] = $payment->{sum}; # AMOUNT
  $arr[4] = ''; # AMOUNT_CURRENCY
  $arr[5] = ($User->{PHONE} && $User->{PHONE} =~ /[0-9]+/) ? $User->{PHONE} : q{}; # PHONE_NUMBER
  $arr[6] = $User->{BILL_ID}; # ACCOUNT
  $arr[7] = ''; # BANK_ACCOUNT -
  $arr[8] = ''; # BANK_NAME -
  @arr[9] = ''; # EXPRESS_CARD_NUMBER -
  @arr[10] = ''; # TERMINAL_ID -
  @arr[11] = ''; # TERMINAL_NUMBER -
  @arr[12] = ''; # CENTER_ID -
  @arr[13] = ''; # CARD_NUMBER -
  @arr[14] = $payment->{dsc}; # PAY_PARAMS
  @arr[15] = ''; # A_UNSTRUCT_INFO -
  @arr[16] = $sorm_id; # REGION_ID

  _add_report("PAYMENT", @arr);

  return 1;
}

#**********************************************************
=head2 CONNECTION_report()

=cut
#**********************************************************
sub CONNECTION_report {
  my $self = shift;

  my $session_list = $Sessions->list({
    COLS_NAME       => 1,
    UID             => '_SHOW',
    LOGIN           => '_SHOW',
    START           => '_SHOW',
    SENT            => '_SHOW',
    RECV            => '_SHOW',
    ACCT_SESSION_ID => '_SHOW',
    IP              => '_SHOW',
    NAS_PORT        => '_SHOW',
    PAGE_ROWS       =>  100000,
    DESC            => 'DESC',
  });

  foreach my $session (@$session_list) {
    my @arr = ();
    $arr[0] = $session->{start}; #CONNECTION_TIME
    $arr[1] = $sorm_id; #REGION_ID
    $arr[2] = '0'; #LOGIN_TYPE
    $arr[3] = $session->{acct_session_id}; #SESSION_ID
    $arr[4] = $session->{ip}; #ALLOCATED_IPV4
    $arr[5] = ''; #ALLOCATED_IPV4_MASK
    $arr[6] = $session->{login}; #USER_NAME
    $arr[7] = ''; #CONNECT_TYPE -
    $arr[8] = ''; #CALLING_NUMBER -
    $arr[9] = ''; #CALLED_NUMBER -
    $arr[10] = ''; #NAS_IPV4 -
    $arr[11] = $session->{port_id}; #NAS_IP_PORT
    $arr[12] = $session->{recv}; #IN_BYTES_COUNT
    $arr[13] = $session->{sent}; #OUT_BYTES_COUNT
    $arr[14] = ''; #USER_EQ_MAC
    $arr[15] = ''; #APN -

    _add_report("CONNECTION", @arr);
  }


  return 1;
}

#**********************************************************
=head2 BASE_STATION_report()

=cut
#**********************************************************
sub BASE_STATION_report {
  my $self = shift;

  my $nas_list = $Nas->list({
  COLS_NAME    => 1,
  NAS_ID       => '_SHOW',
  ADDRESS_FULL => '_SHOW',
  DESCR        => '_SHOW',
  PAGE_ROWS    => 60000,
  });

  foreach my $nas (@$nas_list) {
    my @arr = ();
    $arr[0] = $nas->{nas_id};       #ID
    $arr[1] = '';                   #BEGIN_TIME
    $arr[2] = '';                   #END_TIME
    $arr[3] = $nas->{address_full}; # UNSTRUCT_INFO
    $arr[4] = '';                   #LATITUDE_GRADE
    $arr[5] = '';                   #LONGITUDE_GRADE
    $arr[6] = '';                   #PROJECTION_TYPE
    $arr[7] = $sorm_id;             #REGION_ID
    $arr[8] = $nas->{mac};          #MAC
    $arr[9] = $nas->{nas_ip};       #IPV4
    $arr[10] = $nas->{nas_mng_ip_port};      #IP_PORT

    _add_report("BASE_STATION", @arr);
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

  if ($debug > 5) {
    print "$content\n";
  }

  %reports = (
    ABONENT               => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_ABONENT_" . $sufix,
    PAYMENT               => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_PAYMENT_" . $sufix,
    CONNECTION            => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_CONNECTION_AAA_" . $sufix,
    BASE_STATION          => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_BASE-STATION_" . $sufix,
    # NAT                   => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_NAT_" . $sufix,
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
    ABONENT               => [
      'REGION_ID',
      'ACTUAL_FROM',
      'ACTUAL_TO',
      'CONTRACT_DATE',
      'ACCOUNT',
      'CONTRACT',
      'BANK',
      'BANK_ACCOUNT',
      'UNSTRUCT_NAME',
      'BIRTH_DATE',
      'IDENT_CARD_TYPE_ID',
      'IDENT_CARD_UNSTRUCT',
      'FULL_NAME',
      'INN',
      'CONTACT',
      'PHONE_FAX',
      'MAC',
      'IPV4',
      'IPV4_MASK',
      'LOGIN',
      'E_MAIL',
      'PHONE',
      'A_UNSTRUCT_INFO',
      'H_UNSTRUCT_INFO'
    ],
    PAYMENT               => [
      'PAYMENT_TYPE',
      'PAY_TYPE_ID',
      'PAYMENT_DATE',
      'AMOUNT',
      'AMOUNT_CURRENCY',
      'PHONE_NUMBER',
      'ACCOUNT',
      'BANK_ACCOUNT',
      'BANK_NAME',
      'EXPRESS_CARD_NUMBER',
      'TERMINAL_ID',
      'TERMINAL_NUMBER',
      'CENTER_ID',
      'CARD_NUMBER',
      'PAY_PARAMS',
      'A_UNSTRUCT_INFO',
      'REGION_ID'
    ],
    CONNECTION            => [
      'CONNECTION_TIME',
      'REGION_ID',
      'LOGIN_TYPE',
      'SESSION_ID',
      'ALLOCATED_IPV4',
      'ALLOCATED_IPV4_MASK',
      'USER_NAME',
      'CONNECT_TYPE',
      'CALLING_NUMBER',
      'CALLED_NUMBER',
      'NAS_IPV4',
      'NAS_IP_PORT',
      'IN_BYTES_COUNT',
      'OUT_BYTES_COUNT',
      'USER_EQ_MAC',
      'APN'
    ],
    BASE_STATION          => [
      'ID',
      'BEGIN_TIME',
      'END_TIME',
      'UNSTRUCT_INFO',
      'LATITUDE_GRADE',
      'LONGITUDE_GRADE',
      'PROJECTION_TYPE',
      'REGION_ID',
      'MAC',
      'IPV4',
      'IP_PORT'
    ],
    # NAT                   => [
    #   'TRANSLATION_TIME',
    #   'REGION_ID',
    #   'RECORD_TYPE',
    #   'PRIVATE_IPV4',
    #   'PRIVATE_IP_PORT',
    #   'PUBLIC_IPV4',
    #   'PUBLIC_IP_PORT_END',
    #   'DEST_IPV4',
    #   'DEST_IP_PORT',
    #   'TRANSLATION_TYPE',
    #   'PUBLIC_IP_PORT',
    # ],
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

  %reports = (
    ABONENT               => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_ABONENT_" . $sufix,
    PAYMENT               => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_PAYMENT_" . $sufix,
    CONNECTION            => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_CONNECTION_AAA_" . $sufix,
    BASE_STATION          => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_BASE-STATION_" . $sufix,
    # NAT                   => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_NAT_" . $sufix,
  );

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