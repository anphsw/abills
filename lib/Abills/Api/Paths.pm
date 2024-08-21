package Abills::Api::Paths;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array mk_unique_value camelize);

my $VERSION = 1.2703;

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

  if ($@ || !$module->can('new')) {
    $error_msg = $@;
    $@ = undef;
    $module = 'Api::Paths::' . $attr->{package};
    $module_path = $module . '.pm';
    $module_path =~ s{::}{/}g;
    eval { require $module_path };

    $error_msg .= $@;
    if ($@ || !$module->can('new')) {
      $self->{error_msg} = $error_msg;
      return 0;
    }
  }

  if ($attr->{type} eq 'admin' && $self->{admin}->{MODULES} && in_array($attr->{package}, \@main::MODULES) && !$self->{admin}->{MODULES}->{$attr->{package}}) {
    return 2;
  }
  my $module_obj = $module->new($self->{db}, $self->{admin}, $self->{conf}, $self->{lang},
    $attr->{debug}, $attr->{type}, $self->{html}, { libpath => $self->{libpath} });
  $self->{Errors} = $module_obj->{Errors} || undef;
  return $module_obj->{routes_list};
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
    'Companies'
  );

  if ($self->{conf}->{VIBER_TOKEN} || $self->{conf}->{TELEGRAM_TOKEN}) {
    push @modules_list, 'Bots';
  }

  return \@modules_list;
}

#**********************************************************
=head2 list() - Returns available API paths

  Returns:
    {
      $resource_1_name => [ # $resource_1_name, $resource_2_name - names of API resources. always equals to first path segment
        {
          method  => 'GET',          # HTTP method. Path can be queried only with this method

          path    => '/users/:uid/', # API path. May contain variables like ':uid'.
                                     # these variables will be passed to handler function as argument ($path_params).
                                     # variables are always numerical.
                                     # example: if route's path is '/users/:uid/', and queried URL
                                     # is '/users/9/', $path_params will be { uid => 9 }.
                                     # if credentials is 'USER', variable :uid will be checked to contain only
                                     # authorized user's UID.

          handler => sub {           # handler function, coderef. Arguments that are passed to handler:
            my (
                $path_params,        # params from path. look at docs of path. hashref.
                $query_params,       # params from query. for details look at Abills::Api::Router::new(). hashref.
                                     # keys will be converted from camelCase to UPPER_SNAKE_CASE
                                     # using Abills::Base::decamelize unless no_decamelize_params is set
                $module_obj          # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

            $module_obj->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler as $module_obj. optional.

          type    => 'HASH',         # type of returned data. may be 'HASH' or 'ARRAY'. by default (if not set) it is 'HASH'. optional.

          credentials => [           # arrayref of roles required to use this path. if API user is authorized as at least one of
                                     # these roles access to this path will be granted. optional.
            'ADMIN'                  # may be 'ADMIN' or 'USER'
          ],

          no_decamelize_params => 0, # if set, $query_params for handler will not be converted to UPPER_SNAKE_CASE. optional.

          conf_params => [ ... ]     # variables from $conf to be returned in result. arrayref.
                                     # experimental feature, currently disabled
        },
        ...
      ],
      $resource_2_name => [
        ...
      ],
      ...
    }

=cut
#**********************************************************
sub list {
  my $self = shift;

  #TODO: check how it works with groups, multidoms
  return {
    #TODO: move to packages?
    version   => [
      {
        method      => 'GET',
        path        => '/version/',
        handler     => sub {
          my $version = ::get_version();
          ($version) = $version =~ /\d+.\d+.\d+/g;
          return {
            version     => "$version",
            billing     => 'ABillS',
            api_version => $VERSION,
          };
        },
        credentials => [
          'ADMIN', 'ADMINSID', 'USERSID', 'USER'
        ]
      }
    ],
    config    => [
      {
        method  => 'GET',
        path    => '/config/',
        handler => sub {
          my %config = ();
          $config{social_auth}{facebook} = 1 if ($self->{conf}->{AUTH_FACEBOOK_ID});
          $config{social_auth}{google} = 1 if ($self->{conf}->{AUTH_GOOGLE_ID});
          $config{social_auth}{apple} = 1 if ($self->{conf}->{AUTH_APPLE_ID});
          $config{password_recovery} = 1 if ($self->{conf}->{PASSWORD_RECOVERY});
          if ($self->{conf}->{NEW_REGISTRATION_FORM}) {
            $config{registration}{facebook} = 1 if ($self->{conf}->{FACEBOOK_REGISTRATION});
            $config{registration}{google} = 1 if ($self->{conf}->{GOOGLE_REGISTRATION});
            $config{registration}{apple} = 1 if ($self->{conf}->{APPLE_REGISTRATION});
          }
          else {
            $config{registration}{internet} = 1 if (in_array('Internet', \@main::MODULES) && in_array('Internet', \@main::REGISTRATION));
          }
          $config{login}{regx} = $self->{conf}->{USERNAMEREGEXP} if ($self->{conf}->{USERNAMEREGEXP});
          $config{login}{max_length} = $self->{conf}->{MAX_USERNAME_LENGTH} if ($self->{conf}->{MAX_USERNAME_LENGTH});
          $config{password}{symbols} = $self->{conf}->{PASSWD_SYMBOLS} if ($self->{conf}->{PASSWD_SYMBOLS});
          $config{password}{length} = $self->{conf}->{PASSWD_LENGTH} if ($self->{conf}->{PASSWD_LENGTH});
          $config{portal_news} = 1 if ($self->{conf}->{PORTAL_START_PAGE});

          $config{auth}{phone} = 1 if ($self->{conf}->{AUTH_BY_PHONE});
          $config{phone}{pattern} = $self->{conf}->{PHONE_NUMBER_PATTERN} if ($self->{conf}->{PHONE_NUMBER_PATTERN});

          return \%config;
        },
        credentials => [
          'PUBLIC'
        ]
      },
    ],
  };
}

1;
