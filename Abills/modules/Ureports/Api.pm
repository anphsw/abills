package Ureports::Api;
use strict;
use warnings FATAL => 'all';

use Ureports;

my Ureports $Ureports;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $debug, $type) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug
  };

  bless($self, $class);

  $Ureports = Ureports->new($db, $admin, $conf);

  $Ureports->{debug} = $self->{debug};

  $self->{routes_list} = ();

  if ($type && $type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  return $self;
}

#**********************************************************
=head2 admin_routes() - Returns available API paths

  ARGUMENTS
    admin_routes: boolean - if true return all admin routes, false - user

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
                        # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

          ->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler a. optional.

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
sub admin_routes {
  my $self = shift;

  return [
    {
      method      => 'GET',
      path        => '/ureports/user/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my @allowed_params = (
          'TP_ID',
          'TP_NAME',
          'DESTINATION',
          'TYPE',
          'STATUS',
          'UID',
          'REPORTS_COUNT',
        );

        my %PARAMS = (
          PAGE_ROWS => (defined($query_params->{PAGE_ROWS}) ? $query_params->{PAGE_ROWS} : 100000),
        );
        foreach my $param (@allowed_params) {
          next if (!defined($query_params->{$param}));
          $PARAMS{$param} = $query_params->{$param} || '_SHOW';
        }

        $Ureports->user_list({
          %PARAMS,
          COLS_NAME => 1,
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/ureports/user/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10202,
          errstr => 'No field tpId'
        } if !$query_params->{TP_ID};

        return {
          errno  => 10203,
          errstr => 'No field type'
        } if !defined $query_params->{TYPE};

        my $list = $Ureports->user_list({
          UID       => $path_params->{uid},
          COLS_NAME => 1,
        });

        if ($list && scalar(@{$list})) {
          return {
            errno  => 10207,
            errstr => 'User info exists'
          };
        }

        my %params = (
          UID    => $path_params->{uid},
          TP_ID  => $query_params->{TP_ID},
          TYPE   => $query_params->{TYPE},
          STATUS => $query_params->{STATUS} ? $query_params->{STATUS} : 0,
        );

        my $user_add = $Ureports->user_add({
          UID => $path_params->{uid},
          %{$query_params || {}}
        });

        my $reports = $query_params->{REPORTS};

        foreach my $report (keys %{$reports}) {
          $params{'VALUE_' . ($report || '')} = $reports->{$report};
        }

        my $user_reports_add = $Ureports->tp_user_reports_change(\%params);

        return {
          user_add_result    => $user_add->{result},
          reports_add_result => $user_reports_add->{result}
        };
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/ureports/user/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10205,
          errstr => 'No field tpId'
        } if !$query_params->{TP_ID};

        return {
          errno  => 10206,
          errstr => 'No field type'
        } if !defined $query_params->{TYPE};

        my %params = (
          UID    => $path_params->{uid},
          TP_ID  => $query_params->{TP_ID},
          TYPE   => $query_params->{TYPE},
          STATUS => $query_params->{STATUS} ? $query_params->{STATUS} : 0,
        );

        my $user_add = $Ureports->user_change({
          UID => $path_params->{uid},
          %{$query_params || {}}
        });

        my $reports = $query_params->{REPORTS};

        foreach my $report (keys %{$reports}) {
          $params{'VALUE_' . ($report || '')} = $reports->{$report};
        }

        my $user_reports_add = $Ureports->tp_user_reports_change(\%params);

        return {
          user_change_result => $user_add->{result},
          reports_add_result => $user_reports_add->{result}
        };
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/ureports/user/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Ureports->user_del({ UID => $path_params->{uid} });
      },
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

1;
