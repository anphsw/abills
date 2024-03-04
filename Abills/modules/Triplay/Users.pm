=head2 NAME

  Services

=cut

use strict;
use warnings FATAL => 'all';
use Triplay;

our (
  $db,
  %conf,
  %lang,
  $admin,
  %permissions
);

our Abills::HTML $html;
my $Triplay = Triplay->new($db, $admin, \%conf);

#**********************************************************
=head2 test()

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub triplay_users_services {
  my ($attr) = @_;

  result_former({
    INPUT_DATA     => $Triplay,
    FUNCTION       => 'user_list',
    BASE_FIELDS    => 0,
    DEFAULT_FIELDS => "LOGIN,INTERNET_TP_NAME,IPTV_TP_NAME,ABON_TP_NAME,VOIP_TP_NAME",
    FILTER_COLS    => {
      abonplata => '_triplay_abonplata_count::ABONPLATA'
    },
    #      FUNCTION_FIELDS => 'change, del',
    EXT_TITLES     => {
      'internet_tp_name' => $lang{INTERNET},
      'iptv_tp_name'     => $lang{TV},
      'abon_tp_name'     => $lang{ABON},
      'voip_tp_name'     => $lang{VOIP},
    },
    TABLE          => {
      width   => '100%',
      caption => "Triplay - $lang{USERS}",
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
  });

  return 1;
}

#**********************************************************
=head2 _triplay_abonplata_count() - count amount for all triplay services

  Arguments:
     uid  - user identifier
     attr - {

     }

  Returns:
    total_sum - amount of money to pay for all services

  Example:
    my $total_sum = _triplay_abonplata_count(1, {});

=cut
#**********************************************************
sub _triplay_abonplata_count {
  my ($uid) = @_;

  return 'This user has not services  ' if (! $uid);

  my $user_services_information = cross_modules('docs', { UID => $uid });

  my $total_sum = 0;
  if($user_services_information->{Internet}){
    foreach my $internet_service_info (@{ $user_services_information->{Internet} }){
      my (undef, undef, $amount, undef, undef, undef, undef) = split('\|', $internet_service_info);
      $total_sum += $amount;
    }
  }

  if($user_services_information->{Iptv}){
    foreach my $iptv_service_info (@{ $user_services_information->{Iptv} }){
      my (undef, undef, $amount, undef, undef, undef, undef) = split('\|', $iptv_service_info);
      $total_sum += $amount;
    }
  }

  if($user_services_information->{Voip}){
    foreach my $voip_service_info (@{ $user_services_information->{Voip} }){
      my (undef, undef, $amount, undef, undef, undef, undef) = split('\|', $voip_service_info);
      $total_sum += $amount;
    }
  }

  return sprintf('%.2f', $total_sum);
}

1;