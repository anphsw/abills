package Abills::Api::Paths;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array mk_unique_value camelize);

our $VERSION = 1.3805;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $html, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    html  => $html,
  };

  $self->{libpath} = $attr->{libpath} || '';

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 load_own_resource_info($attr)

  Arguments:
    $attr
      package       - package
      modules       - list of modules

  Returns:
    List of routes
=cut
#**********************************************************
sub load_own_resource_info {
  my $self = shift;
  my ($attr) = @_;

  my $extra_modules = $self->_extra_api_modules();
  my @modules = (@main::MODULES, @{$extra_modules});

  $attr->{package} = ucfirst($attr->{package} || q{});

  if (!in_array($attr->{package}, \@modules)) {
    return 0;
  }

  my $error_msg = '';
  my $module = $attr->{package} . '::Api';
  my $module_path = $module . '.pm';
  $module_path =~ s{::}{/}g;
  eval { require $module_path };

  if ($@) {
    $error_msg = $@;
    $@ = undef;
    $module = 'Api::Paths::' . $attr->{package};
    $module_path = $module . '.pm';
    $module_path =~ s{::}{/}g;
    eval { require $module_path };

    $error_msg .= $@;
    if ($@) {
      $self->{error_msg} = $error_msg;
      return 0;
    }
  }

  if ($attr->{type} eq 'admin' && $module->can('admin_routes')) {
    return $module->admin_routes();
  }
  elsif ($attr->{type} eq 'user' && $module->can('user_routes')) {
    return $module->user_routes();
  }
}

#**********************************************************
=head2 _extra_api_modules() return extra modules files of API

  Returns:
    List of extra modules

=cut
#**********************************************************
sub _extra_api_modules {
  my $self = shift;

  my @modules_list = (
    #core user API paths
    #TODO: when we location of Core modules of API now we can read it from folders
    'User_core',

    'Contacts',
    'Admins',
    'Global',
    'Tp',
    'Groups',
    'Callback',
    'Users',
    'Payments',
    'Fees',
    'Finance',
    'Online',
    'Districts',
    'Streets',
    'Builds',
    'Intervals',
    'Companies',
    'Config',
    'Version'
  );

  if ($self->{conf}->{VIBER_TOKEN} || $self->{conf}->{TELEGRAM_TOKEN}) {
    push @modules_list, 'Bots';
  }

  return \@modules_list;
}

1;
