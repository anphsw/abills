package Portal::Api::admin::Menus;

=head1 NAME

  Portal menus manage

  Endpoints:
    /portal/menus/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(convert);
use Control::Errors;

use Portal;
use Portal::Misc::Attachments;

my Control::Errors $Errors;

my Portal $Portal;
my Portal::Misc::Attachments $Attachments;

my %permissions = ();

# TODO: make this centralized and more maintainable
my @allowed_methods = (5, 6, 10);

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

  %permissions = %{$attr->{permissions} || {}};

  bless($self, $class);

  $Portal = Portal->new($db, $admin, $conf);
  $Attachments = Portal::Misc::Attachments->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_portal_menus($path_params, $query_params)

  Endpoint GET /portal/menus

=cut
#**********************************************************
sub get_portal_menus {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
    DESC      => $query_params->{DESC},
  );

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0')
      ? $query_params->{$param}
      : '_SHOW';
  }

  my $list = $Portal->portal_menu_list({
    ID => '_SHOW',
    NAME => '_SHOW',
    URL => '_SHOW',
    DATE => '_SHOW',
    STATUS => '_SHOW',
    %$query_params,
    %PARAMS,
  });

  return {
    list  => $list,
    total => $Portal->{TOTAL}
  };
}


#**********************************************************
=head2 get_portal_menus_id($path_params, $query_params)

  Endpoint GET /portal/menus/:id/

=cut
#**********************************************************
sub get_portal_menus_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0')
      ? $query_params->{$param}
      : '_SHOW';
  }
  $query_params->{COLS_NAME} = 1;

  my $list = $Portal->portal_menu_list({
    NAME => '_SHOW',
    URL => '_SHOW',
    DATE => '_SHOW',
    STATUS => '_SHOW',
    %$query_params,
    ID => $path_params->{id}
  });

  return $list->[0] || {};
}

#**********************************************************
=head2 post_portal_menus($path_params, $query_params)

  Endpoint POST /portal/menus

=cut
#**********************************************************
sub post_portal_menus {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $Portal->portal_menu_add({ %$query_params });;
}

#**********************************************************
=head2 put_portal_menus_id($path_params, $query_params)

  PUT /portal/menus/:id

=cut
#**********************************************************
sub put_portal_menus_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $query_params->{STATUS} //= '0';
  return $Portal->portal_menu_change({ ID => $path_params->{id}, %$query_params });
}

#**********************************************************
=head2 delete_portal_menus_id($path_params, $query_params)

  Endpoint DELETE /portal/menus/:id/

=cut
#**********************************************************
sub delete_portal_menus_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $list = $Portal->portal_articles_list({ PORTAL_MENU_ID => $path_params->{id}, COLS_NAME => 1 });

  if (scalar(@$list)) {
    return $Errors->throw_error(1440008, { lang_vars => { ID => $path_params->{id} }});
  }

  return $Portal->portal_menu_del({ ID => $path_params->{id} });;
}

1;
