package Tags::Api::Admin::Tags;
=head1 NAME

  Tags manage

  Endpoints:
    /tags/ AND /tags/:id/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Tags;

my Control::Errors $Errors;
my Tags $Tags;

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
    attr  => $attr
  };

  bless($self, $class);

  $Tags = Tags->new($db, $admin, $conf);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_tags($path_params, $query_params)

  Endpoint GET /tags/

=cut
#**********************************************************
sub get_tags {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{RESPONSIBLE_ADMIN} = 1 if (exists $query_params->{ID_RESPONSIBLE} || exists $query_params->{RESPONSIBLE} || exists $query_params->{TAGS_ID});

  $Tags->list({
    NAME      => '_SHOW',
    SORT      => 't.id',
    %$query_params,
    COLS_NAME => 1,
  });
}

#**********************************************************
=head2 post_tags($path_params, $query_params)

  Endpoint POST /tags/

=cut
#**********************************************************
sub post_tags {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Tags->add($query_params);

  return $Tags if $Tags->{errno};

  if ($query_params->{RESPONSIBLE}) {
    $Tags->add_responsible({ ID => $Tags->{INSERT_ID}, AID => $query_params->{RESPONSIBLE} });
  }

  $Tags->info($Tags->{INSERT_ID});
  delete @{$Tags}{qw/TOTAL list AFFECTED INSERT_ID/};

  return $Tags;
}

#**********************************************************
=head2 get_tags_id($path_params, $query_params)

  Endpoint GET /tags/:id/

=cut
#**********************************************************
sub get_tags_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Tags->info($path_params->{id});
  delete @{$Tags}{qw/TOTAL list AFFECTED/};

  return $Tags;
}

#**********************************************************
=head2 put_tags_id($path_params, $query_params)

  Endpoint PUT /tags/:id/

=cut
#**********************************************************
sub put_tags_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Tags->change({ ID => $path_params->{id}, %$query_params });

  return $Tags if $Tags->{errno};

  if ($query_params->{RESPONSIBLE}) {
    $Tags->add_responsible({ ID => $Tags->{INSERT_ID}, AID => $query_params->{RESPONSIBLE} });
  }

  $Tags->info($path_params->{id});
  delete @{$Tags}{qw/TOTAL list AFFECTED INSERT_ID/};

  return $Tags;
}

#**********************************************************
=head2 delete_tags_id($path_params, $query_params)

  Endpoint DELETE /tags/:id/

=cut
#**********************************************************
sub delete_tags_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Tags->del_responsible($path_params->{id});
  $Tags->del($path_params->{id});

  if (!$Tags->{errno}) {
    if ($Tags->{AFFECTED} && $Tags->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
      };
    }
    else {
      $Errors->throw_error(1570001);
    }
  }
  return $Tags;
}

1;
