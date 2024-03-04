=head1 NAME

   internet_session_create(); - Create fake sessions and update traffic
   for test only

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(mk_unique_value int2ip);

use Internet::Sessions;
use Internet;
use Nas;

our (
  $db,
  $admin,
  %conf,
  $argv,
  %AUTH,
  %RAD_REQUEST,
  %RAD_REPLY,
  %RAD_CHECK,
  $begin_time,
  $debug
);

my $create_sessions = 500;
my $session_prefix = 'virt_';


my $Internet = Internet->new($db, $admin, \%conf);

if ($argv->{UPDATE}) {
  internet_session_update();
}
else {
  internet_session_create($argv);
}


#**********************************************************
=head2 internet_session_create()

=cut
#**********************************************************
sub internet_session_create {
  my ($attr)=@_;

  _log('LOG_DEBUG', "internet_session_create");

  if ($attr->{SESSIONS}) {
    $create_sessions = $attr->{SESSIONS};
  }

  eval { do $Bin ."/rlm_perl.pl"; };

  my $nas_id = q{};

  if ($attr->{NAS_IDS}) {
    $nas_id = $attr->{NAS_IDS};
  }
  else {
    _log('LOG_ERR', "SELECT_NAS");
    return 1;
  }

  my $nas_list = get_nas();
  my $nas_ip = $nas_list->{$nas_id};

  my $internet_users = $Internet->user_list({
    LOGIN        => '_SHOW',
    ONLINE_NAS_ID=>'_SHOW',
    IP           => '_SHOW',
    ONLINE       => '_SHOW',
    CID          => '_SHOW',
    TP_ID        => '_SHOW',
    PAGE_ROWS    => 100000,
    COLS_NAME    => 1
  });
  my $online_sessions = 0;
  foreach my $u (@$internet_users) {

    if ($u->{online_nas_id} && $u->{online_nas_id} != $nas_id) {
      next;
    }

    $online_sessions++;
    if( $online_sessions > $create_sessions ) {
      last;
    }
    elsif ($u->{online}) {
      _log('LOG_INFO', "LOGIN: $u->{login} Skip");
      next;
    }
    my $ip = ($u->{ip_num}) ? int2ip($u->{ip_num}) : '0.0.0.0';

    _log('LOG_INFO', "$online_sessions LOGIN: $u->{login} CID: $u->{cid} IP: $ip");

    %RAD_REQUEST = (
      'User-Name'       => $u->{login},
      'Password'        => '123456',
      'Framed-IP-Address' => $ip,
      'NAS-IP-Address'  => $nas_ip || '127.0.0.1',
      'Acct-Status-Type'=> 'Start',
      'Calling-Station-Id' => $u->{cid} || q{},
      'Acct-Session-Id' => $session_prefix . mk_unique_value(6)
    );

    my $ret = accounting();

    if($ret) {
      print "OK\n";
    }

  }

  _log('LOG_DEBUG', "Online sessions: $online_sessions");


  return 1;
}


#**********************************************************
=head2 internet_session_update()

=cut
#**********************************************************
sub internet_session_update {
  my ($attr)=@_;

  if ($attr->{SESSIONS}) {
    $create_sessions = $attr->{SESSIONS};
  }

  my $Sessions = Internet::Sessions->new($db, $admin, \%conf);

  if ($debug > 5) {
    $Sessions->{debug}=1;
  }

  my $online = $Sessions->online({
    LOGIN             => '_SHOW',
    USER_NAME         => '_SHOW',
    ACCT_SESSION_ID   => $session_prefix . '*',
    ACCT_INPUT_OCTETS => '_SHOW',
    ACCT_OUTPUT_OCTETS=> '_SHOW',
  });

  foreach my $o ( @$online ) {
    _log('LOG_DEBUG', "LOGIN: $o->{user_name} ACCT_SESSION_ID: $o->{acct_session_id} BYTE: "
     .($o->{acct_input_octets} || 0) .'/'. ($o->{acct_output_octets} || 0) );

    $Sessions->online_update({
      USER_NAME         => $o->{user_name},
      ACCT_SESSION_ID   => $o->{acct_session_id},
      ACCT_INPUT_OCTETS => ($o->{acct_input_octets} || 0) + (1000 * mk_unique_value(2, { SYMBOLS => '01234567890' })) + mk_unique_value(2, { SYMBOLS => '01234567890' }),
      ACCT_OUTPUT_OCTETS=> ($o->{acct_output_octets} || 0) + (1000 * mk_unique_value(2, { SYMBOLS => '01234567890' })) + mk_unique_value(2, { SYMBOLS => '01234567890' }),
    })
  }

  return 1;
}

#**********************************************************
=head2 get_nas()

=cut
#**********************************************************
sub get_nas {

  my %nas_list = ();
  my $Nas      = Nas->new( $db, \%conf );
  my $nas_list = $Nas->list({ PAGE_ROWS => 100000, COLS_NAME => 1 });

  foreach my $n ( @$nas_list ) {
    $nas_list{$n->{nas_id}}=$n->{nas_ip};
  }

  return \%nas_list
}

1;