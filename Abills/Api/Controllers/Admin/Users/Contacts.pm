package Api::Controllers::Admin::Users::Contacts;

=head1 NAME

  ADMIN API Users Contracts

  Endpoints:
    /users/contacts/*
    /users/:uid/contacts/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Contacts;
use Control::Contacts;

my Control::Errors $Errors;
my Contacts $Contacts;
my Control::Contacts $Contacts_control;

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
    lang  => $attr->{lang} || {}
  };

  bless($self, $class);

  $Contacts = Contacts->new($self->{db}, $self->{admin}, $self->{conf});
  $Contacts_control = Control::Contacts->new($self->{db}, $self->{admin}, $self->{conf}, { lang => $self->{lang} });

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_users_contacts($path_params, $query_params)

  Endpoint POST /users/contacts/

=cut
#**********************************************************
sub post_users_contacts {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  $Contacts->contacts_list({
    %$query_params,
    UID => '_SHOW'
  });
}

#**********************************************************
=head2 get_users_uid_contacts($path_params, $query_params)

  Endpoint GET /users/:uid/contacts/

=cut
#**********************************************************
sub get_users_uid_contacts {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{0};

  $Contacts->contacts_list({
    UID       => $path_params->{uid},
    VALUE     => '_SHOW',
    PRIORITY  => '_SHOW',
    TYPE      => '_SHOW',
    TYPE_NAME => '_SHOW',
  });
}

#**********************************************************
=head2 post_users_uid_contacts($path_params, $query_params)

  Endpoint POST /users/:uid/contacts/

=cut
#**********************************************************
sub post_users_uid_contacts {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  if ($query_params->{CONTACTS} && ref $query_params->{CONTACTS} eq 'ARRAY') {
    return $Contacts_control->renew_contacts($path_params->{uid}, $query_params->{CONTACTS});
  }

  return $Contacts_control->add_contact($path_params->{uid}, $query_params);
}

#**********************************************************
=head2 delete_users_uid_contacts_id($path_params, $query_params)

  Endpoint DELETE /users/:uid/contacts/:id/

=cut
#**********************************************************
sub delete_users_uid_contacts_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{5};

  return $Contacts_control->del_contact($path_params->{uid}, $path_params->{id});
}

#**********************************************************
=head2 put_users_uid_contacts_id($path_params, $query_params)

  Endpoint PUT /users/:uid/contacts/:id/

=cut
#**********************************************************
sub put_users_uid_contacts_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  return $Contacts_control->change_contact($path_params->{uid}, {
    %$query_params,
    ID  => $path_params->{id}
  });
}

1;
