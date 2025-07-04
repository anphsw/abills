package Abon::Api::admin::Tariffs;

=head1 NAME

  Abon tariffs manage

  Endpoints:
    /abon/tariffs/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(convert);
use Control::Errors;

use Abon;
use Abon::Misc::Attachments;
use Abon::Services;

my Control::Errors $Errors;

my Abon $Abon;
my Abon::Misc::Attachments $Attachments;
my Abon::Services $Abon_services;

my %permissions = ();

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
    lang  => $attr->{lang}
  };

  %permissions = %{$attr->{permissions} || {}};

  bless($self, $class);

  $Abon = Abon->new($db, $admin, $conf);
  $Attachments = Abon::Misc::Attachments->new($self->{db}, $self->{admin}, $self->{conf});
  $Abon_services = Abon::Services->new($self->{db}, $self->{admin}, $self->{conf}, { LANG => $self->{lang} });

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_abon_tariffs($path_params, $query_params)

  Endpoint GET /abon/tariffs/

=cut
#**********************************************************
sub get_abon_tariffs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $Abon->tariff_list({
    _SHOW_ALL_COLUMNS => 1,
    %$query_params,
    COLS_NAME         => 1
  });
}

#**********************************************************
=head2 post_abon_tariffs($path_params, $query_params)

  Endpoint POST /abon/tariffs/

=cut
#**********************************************************
sub post_abon_tariffs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $picture_name = $Attachments->save_picture($query_params->{SERVICE_IMG});
  $Abon->tariff_add({ %$query_params, SERVICE_IMG => $picture_name });

  if ($query_params->{GID}) {
    my @gids = split(/,\s?/, $query_params->{GID});
    for my $gid (@gids) {
      $Abon->tariff_gid_add({ GID => $gid, TP_ID => $query_params->{ABON_ID} });
    }
  }

  $Abon->tariff_add({
    %$query_params
  });

  return $Abon;
}

#**********************************************************
=head2 get_abon_tariffs_id($path_params, $query_params)

  Endpoint GET /abon/tariffs/:id/

=cut
#**********************************************************
sub get_abon_tariffs_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Abon->tariff_info($path_params->{id});
  return $Abon;
}

#**********************************************************
=head2 put_abon_tariffs_id($path_params, $query_params)

  Endpoint PUT /abon/tariffs/:id/

=cut
#**********************************************************
sub put_abon_tariffs_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Abon->tariff_info($path_params->{id});
  my $local_gid = $Abon->{GID};

  if ($query_params->{SERVICE_IMG}) {
    my $picture_name = $Attachments->save_picture($query_params->{SERVICE_IMG}, $path_params->{id});
    $query_params->{SERVICE_IMG} = $picture_name;
  }

  $Abon->tariff_change({ %$query_params });

  if ($local_gid) {
    $Abon->tariff_gid_del({ TP_ID => $path_params->{id}});
  }

  if ($query_params->{GID}) {
    my @gids = split(/,\s?/, $query_params->{GID});
    for my $gid (@gids) {
      $Abon->tariff_gid_add({ GID => $gid, TP_ID => $path_params->{id} });
    }
  }

  return $Abon;
}


#**********************************************************
=head2 delete_abon_tariffs_id($path_params, $query_params)

  Endpoint DELETE /abon/tariffs/:id/

=cut
#**********************************************************
sub delete_abon_tariffs_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Abon->tariff_del($path_params->{id});
  $Abon->tariff_gid_del({ TP_ID => $path_params->{id}});
}

#**********************************************************
=head2 get_abon_tariffs_id_users_uid($path_params, $query_params)

  Endpoint GET /abon/tariffs/:id/users/:uid/

=cut
#**********************************************************
sub get_abon_tariffs_id_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Abon_services->abon_user_tariff_activate({
    DEBUG => 0,
    % { $query_params },
    UID   => $path_params->{uid},
    ID    => $path_params->{id},
  });
}

#**********************************************************
=head2 delete_abon_tariffs_id_users_uid($path_params, $query_params)

  Endpoint DELETE /abon/tariffs/:id/users/:uid/

=cut
#**********************************************************
sub delete_abon_tariffs_id_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Abon_services->abon_user_tariff_deactivate({
    %{$query_params},
    UID => $path_params->{uid},
    ID  => $path_params->{id},
  });

  if (!$result->{errno} && $result->{AFFECTED} && $result->{AFFECTED} =~ /^[0-9]$/) {
    return { result => 'Successfully deleted', };
  }

  return $result;
}

1;
