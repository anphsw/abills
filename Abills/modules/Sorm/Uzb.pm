package Sorm::Uzb;

=head1 NAME

  Module SORM for Uzbekistan

=head1 DOCS

  Arg:
    START - full uploading from the begining (START=1)
    DATE - date uploading (previous date is by default). Format DATE=YYYY.MM.DD
    DEBUG

  Execute:
  /usr/abills/libexec/billd sorm TYPE=Uzb

  DESCRIBE: Plugin for SORM of Uzbekistan

=head1 VERSION

  VERSION: 1.12
  UPDATED: 20240805

=cut

use strict;
use warnings FATAL => 'all';

use Companies;
use Internet::Collector;
use Time::Piece;
use Abills::Base qw(in_array ip2int int2ip);

my ($User, $Company, $Internet, $Sessions, $Nas, $Traffic, $debug);
my Payments $Payments;

my $begin_date = '2015-01-01';
my $end_date = '2049-12-31';
my $t = localtime;
my $upload_t = $t - 86400;

my $year  = sprintf("%04d", $t->year());
my $month = sprintf("%02d", $t->mon());
my $day   = sprintf("%02d", $t->mday());
my $hour  = 23;
my $min   = 59;

my $upload_year = sprintf("%04d", $upload_t->year());
my $upload_month = sprintf("%02d", $upload_t->mon());
my $upload_day = sprintf("%02d", $upload_t->mday());
my $upload_date = "$upload_year-$upload_month-$upload_day";

my $sufix = $upload_year . $upload_month . $upload_day . "_" . $hour . $min . ".txt";
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
  $Traffic = Internet::Collector->new($self->{db}, $self->{conf});

  my $argv = $self->{argv};
  $sorm_id = $self->{conf}->{SORM_ISP_ID};

  if (!$sorm_id){
    print "Please add REGION_ID to \$conf{SORM_ISP_ID} in config.pl \n";
    return 1;
  }

  if ($argv->{START}) {
    mkdir($main::var_dir . '/sorm/');
    mkdir($main::var_dir . '/sorm/UZB/');
    mkdir($main::var_dir . '/sorm/UZB/' . $sorm_id);
  }

  if ($argv->{DATE}){
    if ($argv->{DATE} =~ /(\d{4})\-(\d{2})\-(\d{2})/) {
      $upload_date = $argv->{DATE};
      my $sufix_date = $argv->{DATE};
      $sufix_date =~ s/\-//g;
      $sufix = $sufix_date . "_" . $hour . $min . ".txt";
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

  _add_header('ABONENT');

  foreach my $u (@$users_list) {
    $self->ABONENT_report($u->{uid});
  }

  # PAYMENT
  my $payments = $Payments->list({
    ID        => '_SHOW',
    FROM_DATE => $begin_date,
    TO_DATE   => $upload_date,
    SORT      => 'id',
    DESC      => 'DESC',
    COLS_NAME => 1,
    PAGE_ROWS => 99999,
});

  print "Payments: $Payments->{TOTAL}\n" if ($debug > 1);

  _add_header("PAYMENT");

  foreach my $p (@$payments) {
    $self->PAYMENT_report($p->{id});
  }

  _add_header('CONNECTION');
  $self->CONNECTION_report();

  _add_header('BASE_STATION');
  $self->BASE_STATION_report();

  _add_header('NAT');
  $self->NAT_report();

  $self->send();

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
  $arr[9] = ($User->{BIRTH_DATE} && $User->{BIRTH_DATE} ne '0000-00-00') ? $User->{BIRTH_DATE} : q{};  # BIRTH_DAY
  $arr[10] = 'паспорт';                              # IDENT_CARD_TYPE_ID

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

  my $user_mac = $Internet->{CPE_MAC} ? $Internet->{CPE_MAC} : $Internet->{CID};
  $user_mac =~ s/://g if $user_mac;

  $arr[16] = $user_mac;             # MAC
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
  $arr[22] = $User->{REG_ADDRESS} || q{};                                        # A_UNSTRUCT_INFO
  $arr[23] = "$zip $country $region $city $address_street $address_build $flat"; # H_UNSTRUCT_INFO

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
  $payment_type = 83 if ($payment->{method} && $payment->{method} == 0); # cash
  $payment_type = 80 if ($payment->{method} && $payment->{method} == 1); # bank

  $User->info($uid);
  if ($User->{errno}) {
    delete $User->{errno};
    return 0;
  }

  $User->pi({ UID => $uid });

  my @arr = ();

  $arr[0] = $payment_type; # PAYMENT_TYPE
  $arr[1] = $payment->{dsc} ? $payment->{dsc} : 'авансовый платеж'; # PAY_TYPE_ID
  $arr[2] = time2UTC($payment->{datetime}); # PAYMENT_DATE
  $arr[3] = $payment->{sum}; # AMOUNT
  $arr[4] = ''; # AMOUNT_CURRENCY
  $arr[5] = ($User->{PHONE} && $User->{PHONE} =~ /[0-9]+/) ? $User->{PHONE} : q{}; # PHONE_NUMBER
  $arr[6] = $User->{BILL_ID}; # ACCOUNT
  $arr[7] = ''; # BANK_ACCOUNT -
  $arr[8] = ''; # BANK_NAME -
  @arr[9] = ''; # EXPRESS_CARD_NUMBER -:
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
    FROM_DATE       => $begin_date,
    TO_DATE         => $upload_date,
    START           => '_SHOW',
    END             => '_SHOW',
    SENT            => '_SHOW',
    RECV            => '_SHOW',
    ACCT_SESSION_ID => '_SHOW',
    IP              => '_SHOW',
    NAS_IP          => '_SHOW',
    NAS_PORT        => '_SHOW',
    MASK            => '_SHOW',
    PAGE_ROWS       =>  100000,
    DESC            => 'DESC',
  });

  print "Sessions: $Sessions->{TOTAL}\n" if ($debug > 1);

  foreach my $session (@$session_list) {
    my @arr_start = ();
    my @arr_end   = ();

    my $user_internet_info = $Internet->user_info($session->{uid});
    my $user_mac = ($user_internet_info->{CPE_MAC}) ? $user_internet_info->{CPE_MAC} : $user_internet_info->{CID};
    $user_mac =~ s/://g if $user_mac;

    $arr_start[0] = time2UTC($session->{start}); #CONNECTION_TIME
    $arr_start[1] = $sorm_id;          #REGION_ID
    $arr_start[2] = '0';               #LOGIN_TYPE
    $arr_start[3] = $session->{acct_session_id}; #SESSION_ID
    $arr_start[4] = $session->{ip};                           #ALLOCATED_IPV4
    $arr_start[5] = $session->{mask} ? $session->{mask} : ''; #ALLOCATED_IPV4_MASK
    $arr_start[6] = $session->{login}; #USER_NAME
    $arr_start[7] = '';                #CONNECT_TYPE
    $arr_start[8] = '0';               #CALLING_NUMBER
    $arr_start[9] = '0';               #CALLED_NUMBER
    $arr_start[10] = $session->{nas_ip} ? $session->{nas_ip} : ''; #NAS_IPV4
    $arr_start[11] = $session->{port_id}; #NAS_IP_PORT
    $arr_start[12] = $session->{recv}; #IN_BYTES_COUNT
    $arr_start[13] = $session->{sent}; #OUT_BYTES_COUNT
    $arr_start[14] = $user_mac;        #USER_EQ_MAC
    $arr_start[15] = '';               #APN

    $arr_end[0] = time2UTC($session->{end}); #CONNECTION_TIME
    $arr_end[1] = $sorm_id;          #REGION_ID
    $arr_end[2] = '1';               #LOGIN_TYPE
    $arr_end[3] = $session->{acct_session_id}; #SESSION_ID
    $arr_end[4] = $session->{ip}; #ALLOCATED_IPV4
    $arr_end[5] = $session->{mask} ? $session->{mask} : ''; #ALLOCATED_IPV4_MASK
    $arr_end[6] = $session->{login}; #USER_NAME
    $arr_end[7] = '';                #CONNECT_TYPE
    $arr_end[8] = '0';               #CALLING_NUMBER
    $arr_end[9] = '0';               #CALLED_NUMBER
    $arr_end[10] = $session->{nas_ip} ? $session->{nas_ip} : '';  #NAS_IPV4
    $arr_end[11] = $session->{port_id}; #NAS_IP_PORT
    $arr_end[12] = $session->{recv}; #IN_BYTES_COUNT
    $arr_end[13] = $session->{sent}; #OUT_BYTES_COUNT
    $arr_end[14] = $user_mac;        #USER_EQ_MAC
    $arr_end[15] = '';               #APN

    _add_report("CONNECTION", @arr_start);
    _add_report("CONNECTION", @arr_end);
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
    DISABLE      => 0,
    DESCR        => '_SHOW',
    PAGE_ROWS    => 60000,
  });

  print "Nas: $Nas->{TOTAL}\n" if ($debug > 1);

  foreach my $nas (@$nas_list) {
    $nas->{mac} =~ s/\://g;

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
    $arr[10] = 22;                  #IP_PORT

    _add_report("BASE_STATION", @arr);
  }

  return 1;
}

#**********************************************************
=head2 NAT_report()

=cut
#**********************************************************
sub NAT_report {
  my $self = shift;

  my $traffic_list = $Traffic->traffic_user_list({
    FROM_DATE_START => $begin_date,
    TO_DATE_START   => $upload_date,
    SRC_IP       => '_SHOW',
    SRC_PORT     => '_SHOW',
    DST_IP       => '_SHOW',
    DST_PORT     => '_SHOW',
    NAS_ID       => '_SHOW',
    DESC         => 'DESC',
    PAGE_ROWS    => 1000000,
    COLS_NAME    => 1,
  });

  print "Traffic: $Traffic->{TOTAL}\n" if ($debug > 1);

  foreach my $traffic (@$traffic_list) {
    my $user_internal_ip = '';
    my $user_external_ip = '';

    my $ip_in_internal_range = _check_internal_network($traffic->{src_addr});

    if ($self->{conf}->{SORM_INTERNAL_TO_EXTERNAL_IP}){
      next if ($ip_in_internal_range == 0);
      my $user_internal_ip_int = $traffic->{src_addr};
      $user_internal_ip = int2ip($traffic->{src_addr});
      my $ip_pool = ($self->{conf}->{SORM_INTERNAL_TO_EXTERNAL_IP});

      foreach my $item (keys (%{$ip_pool})){
        my ($ip, $prefix) = split('/', $item);
        if ($item ne 'default'){
          my $pool_start = ip2int($ip);
          my $pool_end = ip2int($ip) + 512;

          if ($user_internal_ip_int >= $pool_start && $user_internal_ip_int <= $pool_end) {
            $user_external_ip = $ip_pool->{$item};
          }
        }
      }

      if (!$user_external_ip){
        $user_external_ip = $ip_pool->{default};
      }
    }
    else {
    # PPTP (CID = internal IP)
      my $cur_date = "$year-$month-$day";
      $user_external_ip = int2ip($traffic->{src_addr});

      next if ($ip_in_internal_range == 1);

      my $session_list = $Sessions->list({
        COLS_NAME     => 1,
        FROM_DATE     => $cur_date,
        TO_DATE       => $cur_date,
        CID           => '_SHOW',
        IP            => $user_external_ip,
        PAGE_ROWS     =>  1000,
        DESC          => 'DESC',
      });

      next if (!$session_list->[0]->{'cid'});
      $user_internal_ip = $session_list->[0]->{'cid'};
    };

    # internal and external port is the same
    my $ip_port = ($traffic->{src_port} != 0) ? $traffic->{src_port} : 80;
    my $dest_ip_port = ($traffic->{dst_port} != 0) ? $traffic->{dst_port} : 80;

    my @arr = ();
    $arr[0] = time2UTC($traffic->{s_time}); #TRANSLATION_TIME
    $arr[1] = $sorm_id;                     #REGION_ID
    $arr[2] = 1;                            #RECORD_TYPE
    $arr[3] = $user_internal_ip;            #PRIVATE_IPV4
    $arr[4] = $ip_port;                     #PRIVATE_IP_PORT
    $arr[5] = $user_external_ip;            #PUBLIC_IPV4
    $arr[6] = 65535;                        #PUBLIC_IP_PORT_END
    $arr[7] = int2ip($traffic->{dst_addr}); #DEST_IPV4
    $arr[8] = $dest_ip_port;                #DEST_IP_PORT
    $arr[9] = '';                           #TRANSLATION_TYPE
    $arr[10] = $ip_port;                    #PUBLIC_IP_PORT

    _add_report("NAT", @arr);
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
    ABONENT        => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_ABONENT_" . $sufix,
    PAYMENT        => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_PAYMENT_" . $sufix,
    CONNECTION     => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_CONNECTION_AAA_" . $sufix,
    BASE_STATION   => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_BASE-STATION_" . $sufix,
    NAT            => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_NAT_" . $sufix,
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
    ABONENT    => [
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
    PAYMENT    => [
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
    CONNECTION  => [
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
    BASE_STATION => [
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
    NAT          => [
      'TRANSLATION_TIME',
      'REGION_ID',
      'RECORD_TYPE',
      'PRIVATE_IPV4',
      'PRIVATE_IP_PORT',
      'PUBLIC_IPV4',
      'PUBLIC_IP_PORT_END',
      'DEST_IPV4',
      'DEST_IP_PORT',
      'TRANSLATION_TYPE',
      'PUBLIC_IP_PORT',
    ],
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
=head2 _check_internal_network(internal_ip) - check IP for internal network range

      Argument:
        internal_ip

      Return
        TRUE - in range
        FALSE - out of range

=cut
#**********************************************************
sub _check_internal_network {
  my ($internal_ip) = @_;

  my @internal_networks = (
    '10.0.0.0/8',
    '172.16.0.0/12',
    '192.168.0.0/16',
  );

  foreach my $ip_range (@internal_networks) {
    my ($ip, $prefix) = split('/', $ip_range);
    my $ip_range_start = ip2int($ip);
    my $ip_range_end = ip2int($ip) + 512;

    if ($internal_ip >= $ip_range_start && $internal_ip <= $ip_range_end) {
      return 1;
    }
  }

  return 0;
}


#**********************************************************
=head2 time2UTC($time) - format time to UTC

      Argument:
        time

      Return
        time UTC

=cut
#**********************************************************
sub time2UTC {
  my $t = shift;
  my $utc_hour = 5;

  my $cur_time = Time::Piece->strptime($t, "%Y-%m-%d %H:%M:%S");
  my $cur_time_sec = $cur_time - $utc_hour * 3600;
  my $utc_time = $cur_time_sec->strftime('%Y-%m-%d %H:%M:%S');

  return $utc_time;
}


#**********************************************************
=head2 send()

=cut
#**********************************************************
sub send {

  %reports = (
    ABONENT       => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_ABONENT_" . $sufix,
    PAYMENT       => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_PAYMENT_" . $sufix,
    CONNECTION    => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_CONNECTION_AAA_" . $sufix,
    BASE_STATION  => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_BASE-STATION_" . $sufix,
    NAT           => "$main::var_dir/sorm/UZB/$sorm_id/$sorm_id"."_NAT_" . $sufix,
  );

  for my $report (values %reports) {
    if (-e $report) {
      main::_ftp_upload({
        DIR  => "/",
        FILE => $report
      });

      unlink $report if ($debug < 3);
    }
  }

  return 1;
}

1;