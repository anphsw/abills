package Accident::Api::user::Root;
=head1 NAME

  Portal articles manage

  Endpoints:
    /user/accident

=cut
use strict;
use warnings FATAL => 'all';

use Abills::Base;
use Control::Errors;
use Accident;

my Control::Errors $Errors;
my Accident $Accident;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Accident = Accident->new($db, $admin, $conf);
  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_accidents($path_params, $query_params)

  Endpoint GET /user/accident/

=cut
#**********************************************************
sub get_user_accidents {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  my $accident_total = 0;

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
    DESC      => $query_params->{DESC},
  );

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} //= '';
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $list = $Accident->user_accident_list({
    UID       => $path_params->{uid},
    COLS_NAME => 1,
    %$query_params,
    %PARAMS,
  });
  $accident_total += $Accident->{TOTAL} if $Accident->{TOTAL};

  foreach my $line (@$list) {
    delete $line->{sent_open};
    delete $line->{sent_close};
  }

  if (in_array('Equipment', \@main::MODULES)) {
    my $warning_info = $Accident->accident_equipment_list({
      ID_EQUIPMENT  => '_SHOW',
      INTERNET_PORT => '_SHOW',
      PORT_ID       => '_SHOW',
      DATE          => '_SHOW',
      END_DATE      => '_SHOW',
      NAS_ID        => '_SHOW',
      STATUS        => '0',
      UID           => $path_params->{uid},
      EXT_TABLE     => 1,
      COLS_NAME     => 1,
    });
    if ($Accident->{TOTAL}){
      push @$list, @$warning_info;
      $accident_total += $Accident->{TOTAL} if $Accident->{TOTAL};
    }
  }

  return {
    list   => $list,
    total  => $accident_total,
  };
}

1;