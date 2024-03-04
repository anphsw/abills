# billd plugin
#**********************************************************
=head1

 billd plugin

 Standart execute
    /usr/abills/libexec/billd users_app_activity

 DESCRIBE:  Plugin fill out info fields of users (_ANDROID, _IOS)

=cut
#*********************************************************
use strict;
use warnings FATAL => 'all';

use Users;
use Api;

our (
  $db,
  $Admin,
  %conf,
  $debug
);

my $Users = Users->new($db, $Admin, \%conf);
my $Api = Api->new($db, $Admin, \%conf);

users_app_last_activity();

#********************************************************
=head2 users_app_last_activity()

=cut
#********************************************************
sub users_app_last_activity {

  my $users_list = $Users->list({
    COLS_NAME => 1,
    PAGE_ROWS => 99999,
    DELETED   => 0,
    DISABLE   => 0,
  });
  return 0 if $Users->{TOTAL} < 1;

  foreach my $user (@$users_list) {
    my $api_list = $Api->list({
      UID             => $user->{uid},
      DATE            => '_SHOW',
      REQUEST_HEADERS => '_SHOW',
      MOBILE_APP      => 1,
      LAST_MONTH      => 1,
      PAGE_ROWS       => 100,
      DESC            => 'DESC',
    });
    next if $Api->{TOTAL} < 1;

    my $request_headers = $api_list->[0]->{request_headers};

    my ($app_android_activity, $app_ios_activity) = '';
    if ($request_headers =~ /Android/) {
      $app_android_activity = $api_list->[0]{date};
    }
    elsif ($request_headers =~ /iOS/) {
      $app_ios_activity = $api_list->[0]{date};
    }

    if ($app_ios_activity || $app_android_activity) {
      $Users->pi_change({
        UID      => $user->{uid},
        _ANDROID => $app_android_activity,
        _IOS     => $app_ios_activity
      });
    }
  }

  return 1;
}

1;
