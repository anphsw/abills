package Tags::Api::Admin::Users;
=head1 NAME

  Tags manage

  Endpoints:
    /tags/users/* AND /tags/:id/users/*

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
=head2 get_tags_users($path_params, $query_params)

  Endpoint GET /tags/users/

=cut
#**********************************************************
sub get_tags_users {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $query_params->{TAG_ID} = $query_params->{ID} if (defined $query_params->{ID});

  $Tags->tags_list({
    %$query_params,
    COLS_NAME => 1,
  });
}

#**********************************************************
=head2 get_tags_users_uid($path_params, $query_params)

  Endpoint GET /tags/users/:uid/

=cut
#**********************************************************
sub get_tags_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Tags->tags_list({
    LOGIN     => '_SHOW',
    DISABLE   => '_SHOW',
    %$query_params,
    UID       => $path_params->{uid},
    COLS_NAME => 1
  });
}

#**********************************************************
=head2 post_tags_users_uid($path_params, $query_params)

  Endpoint POST /tags/users/:uid/

=cut
#**********************************************************
sub post_tags_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  $self->_user_tags_add($path_params, $query_params, 1);
}

#**********************************************************
=head2 put_tags_users_uid($path_params, $query_params)

  Endpoint PUT /tags/users/:uid/

=cut
#**********************************************************
sub put_tags_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  $self->_user_tags_add($path_params, $query_params, 0);
}

#**********************************************************
=head2 patch_tags_users_uid($path_params, $query_params)

  Endpoint PATCH /tags/users/:uid/

=cut
#**********************************************************
sub patch_tags_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  $self->_user_tags_add($path_params, $query_params, 1);
}

#**********************************************************
=head2 post_tags_id_users_uid($path_params, $query_params)

  Endpoint POST /tags/:id/users/:uid/

=cut
#**********************************************************
sub post_tags_id_users_uid {
  my $self = shift;
  $self->_user_tag_add(@_);
}

#**********************************************************
=head2 put_tags_id_users_uid($path_params, $query_params)

  Endpoint PUT /tags/:id/users/:uid/

=cut
#**********************************************************
sub put_tags_id_users_uid {
  my $self = shift;
  $self->_user_tag_add(@_);
}

#**********************************************************
=head2 delete_tags_id_users_uid($path_params, $query_params)

  Endpoint DELETE /tags/:id/users/:uid/

=cut
#**********************************************************
sub delete_tags_id_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Tags->user_del({
    TAG_ID => $path_params->{id},
    UID    => $path_params->{uid},
  });

  if (!$Tags->{errno}) {
    if ($Tags->{AFFECTED} && $Tags->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
      };
    }
    else {
      $Errors->throw_error(1570002);
    }
  }
  return $Tags;
}

#**********************************************************
=head2 _user_tags_change_body($path_params, $query_params)

=cut
#**********************************************************
sub _user_tags_change_body {
  my $self = shift;
  my ($query_params) = @_;

  my @ids = ();
  my @end_dates = ();

  if ($query_params->{TAGS} && scalar @{$query_params->{TAGS}}) {
    foreach my $tag (@{$query_params->{TAGS}}) {
      push @ids, $tag->{ID} || '';
      push @end_dates, $tag->{END_DATE} || '';
    }
  }

  my $ids = join(',', @ids);
  my $end_dates = join(',', @end_dates);

  return $ids, $end_dates;
}

#**********************************************************
=head2 _user_tag_add($path_params, $query_params)

=cut
#**********************************************************
sub _user_tag_add {
  # In REST API the same path can not update and add data
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Tags->tags_user_change({
    REPLACE  => 1,
    IDS      => $path_params->{id},
    UID      => $path_params->{uid},
    END_DATE => $query_params->{END_DATE},
  });

  $Tags->tags_list({ UID => $path_params->{uid}, COLS_NAME => 1 });

  return $Tags;
}

#**********************************************************
=head2 _user_tag_add($path_params, $query_params)

=cut
#**********************************************************
sub _user_tags_add {
  # In REST API the same path can not update and add data
  my $self = shift;
  my ($path_params, $query_params, $replace) = @_;

  my ($ids, $end_dates) = $self->_user_tags_change_body($query_params);

  $Tags->tags_user_change({
    REPLACE  => $replace,
    IDS      => $ids,
    UID      => $path_params->{uid},
    END_DATE => $end_dates,
  });

  $Tags->tags_list({ UID => $path_params->{uid}, COLS_NAME => 1 });

  return $Tags;
}

1;
