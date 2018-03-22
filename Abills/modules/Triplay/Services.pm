=head2 NAME

  Services

=cut

use strict;
use warnings FATAL => 'all';

our (
  $db,
  %conf,
  %lang,
  $admin,
  $html,
  %permissions,
);

my $Triplay = Triplay->new($db, $admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $admin);
use Abills::Base;


#**********************************************************
=head2 test()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub triplay_users_services {
  my ($attr) = @_;

  my $users_services_list = $Triplay->list_user_service({
    UID         => $attr->{UID} || '_SHOW',
    #    TP_ID       => '_SHOW',
#    INTERNET_TP => '_SHOW',
#    IPTV_TP     => '_SHOW',
#    VOIP_TP     => '_SHOW',
    INTERNET_NAME => '_SHOW',
    VOIP_NAME => '_SHOW',
    IPTV_NAME => '_SHOW',
  });

  result_former(
    {
      INPUT_DATA     => $Triplay,
      LIST           => $users_services_list,
      BASE_FIELDS    => 0,
      DEFAULT_FIELDS => "uid, internet_name, iptv_name, voip_name",
      #      FUNCTION_FIELDS => 'change, del',
      EXT_TITLES     => {
        'uid'         => 'UID',
        'internet_name' => "Internet",
        'iptv_name'     => "IPTV",
        'voip_name'     => "VOIP",
      },
      TABLE          => {
        width   => '100%',
        caption => "$lang{SERVICES}",
        qs      => $pages_qs,
        ID      => 'TRIPLAY_USER_SERVICES',
        header  => '',
        EXPORT  => 1,
        #        MENU    => "$lang{ADD}:index=" . get_function_index( 'triplay_main' ) . ':add' . ";",
      },
      MAKE_ROWS      => 1,
      SEARCH_FORMER  => 1,
      MODULE         => 'Triplay',
      TOTAL          => 1
    }
  );

  return 1;
}

1;