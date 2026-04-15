=head1 NAME

  Quick reports for Internet

=cut

use strict;
use warnings FATAL => 'all';

our(
  $html,
  %lang,
  $admin,
  $db,
  %conf
);

my $Sessions = Internet::Sessions->new($db, $admin, \%conf);

#***************************************************************
=head2 internet_start_page($attr) - Start page summary

=cut
#***************************************************************
sub internet_start_page {

  my %START_PAGE_F = (
    'internet_sp_online' => "$lang{INTERNET} - Online",
    'internet_sp_errors' => "$lang{INTERNET} $lang{ERROR}",
    'internet_users_summary' => "$lang{INTERNET} - $lang{ERR_SMALL_DEPOSIT}",
    'internet_users_unknown' => "$lang{INTERNET} - $lang{UNKNOWN_USERS}",
  );

  return \%START_PAGE_F;
}

#***************************************************************
=head2 internet_sp_online($attr) - Online summary

=cut
#***************************************************************
sub internet_sp_online {

  $Sessions->online({
    STATUS_COUNT => 1,
    DOMAIN_ID    => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef
  });

  my $internet_online_index = get_function_index('internet_online');

  my $table = $html->table({
    width   => '100%',
    caption => "$lang{INTERNET} - Online",
    ID      => 'INTERNET_ONLINE',
    rows    => [
      [ $html->button('Online', "index=$internet_online_index"),
        $Sessions->{ONLINE_COUNT} ],
      [ $html->button('Reconnect', "STATUS=6&index=$internet_online_index"),
        $Sessions->{RECONNECT_COUNT} ],
      [ $html->button('Recovery', "STATUS=9&index=$internet_online_index"),
        $Sessions->{RECOVER_COUNT} ],
      [ $html->button('Zaped', "ZAPED=2&index=$internet_online_index"),
        $Sessions->{ZAPPED_COUNT} ],
      [ $html->button('Guest', "index=$internet_online_index&FILTER=1&FILTER_FIELD=GUEST"),
        $Sessions->{GUEST_COUNT} ],
      [ $html->button('Unknown', "index=$internet_online_index&FILTER=0&&FILTER_FIELD=UNKNOWN"),
        $Sessions->{UNKNOWN_COUNT} ],
    ],
  });

  my $reports = $table->show();

  return $reports;
}


#***************************************************************
=head2 internet_sp_errors($attr) - Quick menu errors

=cut
#***************************************************************
sub internet_sp_errors {

  my $Log  = Log->new($db, \%conf);
  my $list = $Log->log_reports({
    RETRIES   => 10,
    COLS_NAME => 1
  });

  my $table = $html->table({
    width       => '100%',
    caption     => "$lang{INTERNET} $lang{ERROR}",
    ID          => 'INTERNET_ERRORS',
    title_plain => [ $lang{USER}, $lang{COUNT} ],
  });

  foreach my $line (@$list) {
    $table->addrow(
      $html->button($line->{user}, "index=". get_function_index('internet_error') ."&LOGIN=$line->{user}&search=1"),
      $line->{count},
    );
  }

  my $reports = $table->show();

  return $reports;
}


#**********************************************************
=head2 internet_users_summary($attr)

=cut
#**********************************************************
sub internet_users_summary {

  require Internet;
  Internet->import();
  my $Internet = Internet->new($db, $admin, \%conf);
  my $index = get_function_index ('internet_users_list');
  my $deposit = 0;
  my $fee = 0;

  my $user_list = $Internet->user_list({
    DEPOSIT         => '_SHOW',
    MONTH_FEE       => '_SHOW',
    INTERNET_STATUS => 5,
    COLS_NAME       => 1
  });

  foreach my $line (@$user_list) {
    $deposit += $line->{deposit} if ($line->{deposit});
    $fee += $line->{month_fee} if ($line->{month_fee});
  }
  
  my $table = $html->table({
    width   => '100%',
    caption => "$lang{INTERNET} - $lang{ERR_SMALL_DEPOSIT}",
    ID      => 'INTERNET_USERS_SUMMARY',
    rows    => [
      [ $html->button($lang{TOTAL}, "index=$index&INTERNET_STATUS=5"), $Internet->{TOTAL} ],
      [ $lang{DEPOSIT}, $deposit ],
      [ $lang{MONTH_FEE}, $fee ],
    ],
  });

  return $table->show();
}

#***************************************************************
=head2 internet_users_unknown($attr) - Quick report of unknown users

=cut
#***************************************************************
sub internet_users_unknown {

  $Sessions->{debug} = 1 if ($FORM{DEBUG});

  my $list = $Sessions->online({
    UID             => 0,
    CLIENT_IP       => '_SHOW',
    SWITCH_ID       => '_SHOW',
    SWITCH_PORT     => '_SHOW',
    DURATION_SEC    => '_SHOW',
    NAS_ID          => '_SHOW',
    NAS_NAME        => '_SHOW',
    NAS_PORT_ID     => '_SHOW',
    CONNECT_INFO    => '_SHOW',
    ACCT_SESSION_ID => '_SHOW',
    GID             => '_SHOW',
    COLS_NAME       => 1,
    PAGE_ROWS       => 1000,
  });

  my $table = $html->table({
    width       => '100%',
    caption     => "$lang{UNKNOWN_USERS}",
    ID          => 'INTERNET_UNKNOWN_USERS',
    title_plain => [ '','','', '','','','',''],
    DATA_TABLE  => { paging => "false", ordering => "false" },
  });

  foreach my $line (@$list) {
    $table->addrow(
      $html->button('H', "index=". get_function_index('internet_online') . "&FRAMED_IP_ADDRESS="
        . ($line->{client_ip} || q{0.0.0.0})
        . "&hangup=$line->{nas_id}+" . ($line->{nas_port_id} || q{})
        . "+$line->{acct_session_id}+$line->{user_name}",
        { TITLE => 'Hangup', class => 'power-off' }),
      $line->{user_name} || q{},
      $line->{client_ip},
      $line->{switch_id},
      $line->{switch_port},
      $line->{nas_name},
      $line->{connect_info},
      $line->{duration_sec},
    );
  }

  my $reports = $table->show();

  return $reports;
}

1;