package Abills::Api::Paths::Contacts;
=head NAME

  Abills::Api::Paths::Contacts - Contacts api functions

=cut

use strict;
use warnings FATAL => 'all';

use Contacts;
use Abills::Base qw(in_array);

my Contacts $Contacts;
my $conf;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $Conf, $lang, $debug, $type) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $Conf,
    lang  => $lang,
    debug => $debug
  };

  $conf = $Conf;
  bless($self, $class);

  $Contacts = Contacts->new($self->{db}, $self->{admin}, $self->{conf});

  $self->{routes_list} = ();

  if ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }

  return $self;
}

#**********************************************************
=head2 user_routes() - Returns available API paths

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
sub user_routes {
  my $self = shift;

  return [
    {
      method      => 'DELETE',
      path        => '/user/contacts/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $validation = _validate_allowed_types_contacts($path_params->{id});
        return $validation if ($validation->{errno});

        $Contacts->contacts_del({
          UID     => $path_params->{uid},
          TYPE_ID => $path_params->{id}
        });

        if (!$Contacts->{errno}) {
          if ($Contacts->{AFFECTED} && $Contacts->{AFFECTED} =~ /^[0-9]$/) {
            return {
              result =>  'Successfully deleted'
            };
          }
          else {
            return {
              errno  => 10089,
              errstr => "Push contact with typeId $path_params->{id} not found",
            };
          }
        }
        else {
          return {
            errno  => 10090,
            errstr => "Failed delete contact with typeId $path_params->{id}, error happened try later",
          };
        }
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/:uid/contacts/push/subscribe/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errstr => 'No field token in body',
          errno  => 5000
        } if (!$query_params->{TOKEN});

        my $validation = _validate_allowed_types_push($path_params->{id});
        return $validation if ($validation->{errno});

        my $Ureports = '';
        if (in_array('Ureports', \@main::MODULES)) {
          eval {require Ureports; Ureports->import()};
          if (!$@) {
            $Ureports = Ureports->new($self->{db}, $self->{conf}, $self->{admin});
          }
        }

        my $list = $Contacts->push_contacts_list({
          UID     => $path_params->{uid},
          TYPE_ID => $path_params->{id},
          VALUE   => '_SHOW'
        });

        if ($list && !scalar(@{$list})) {
          $Contacts->push_contacts_add({
            TYPE_ID => $path_params->{id},
            VALUE   => $query_params->{TOKEN},
            UID     => $path_params->{uid},
          });

          if ($Ureports) {
            $Ureports->user_send_type_add({
              TYPE        => 10,
              DESTINATION => 1,
              UID         => $path_params->{uid}
            });
          }

          return 1;
        }
        else {
          if ($query_params->{TOKEN} ne $list->[0]->{value}) {
            $Contacts->push_contacts_change({
              ID    => $list->[0]->{id},
              VALUE => $query_params->{TOKEN},
            });

            if ($Ureports) {
              $Ureports->user_send_type_del({
                TYPE => 10,
                UID  => $path_params->{uid}
              });

              $Ureports->user_send_type_add({
                TYPE        => 10,
                DESTINATION => 1,
                UID         => $path_params->{uid}
              });
            }

            return 1;
          }
          else {
            return {
              errstr => 'You are already subscribed',
              errno  => 5001
            }
          }
        }
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/contacts/push/badges/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $validation = _validate_allowed_types_push($path_params->{id});
        return $validation if ($validation->{errno});

        my $list = $Contacts->push_contacts_list({
          UID     => $path_params->{uid},
          TYPE_ID => $path_params->{id},
          VALUE   => '_SHOW'
        });

        if (scalar @$list) {
          $Contacts->push_contacts_change({
            ID     => $list->[0]->{id},
            BADGES => 0,
          });
        }

        return {
          result => 'OK',
        };
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/:uid/contacts/push/subscribe/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $validation = _validate_allowed_types_push($path_params->{id});
        return $validation if ($validation->{errno});

        my $message = 'OK';

        $Contacts->push_contacts_del({
          TYPE_ID => $path_params->{id},
          UID     => $path_params->{uid},
        });

        if (!$Contacts->{errno}) {
          if ($Contacts->{AFFECTED} && $Contacts->{AFFECTED} =~ /^[0-9]$/) {
            $message = 'Successfully deleted';
          }
          else {
            return {
              errno  => 10084,
              errstr => "Push contact with typeId $path_params->{id} not found",
            };
          }
        }

        if (in_array('Ureports', \@main::MODULES)) {
          $Contacts->push_contacts_list({
            UID     => $path_params->{uid},
          });

          if (!$Contacts->{TOTAL}) {
            my $Ureports = '';
            eval {require Ureports; Ureports->import()};
            if (!$@) {
              $Ureports = Ureports->new($self->{db}, $self->{conf}, $self->{admin});
              $Ureports->user_send_type_del({
                TYPE => 10,
                UID  => $path_params->{uid}
              });
            }
          }
        }

        return {
          result => $message,
        };
      },
      module      => 'Contacts',
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/:uid/contacts/push/subscribe/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $validation = _validate_allowed_types_push($path_params->{id});
        return $validation if ($validation->{errno});

        my $list = $Contacts->push_contacts_list({
          UID     => $path_params->{uid},
          TYPE_ID => $path_params->{id},
          VALUE   => '_SHOW'
        });

        delete @{$list->[0]}{qw/type_id id/} if ($list->[0]);

        return $list->[0] || {};
      },
      module      => 'Contacts',
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/:uid/contacts/push/messages/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        if ($query_params->{TYPE_ID}) {
          my $validation = _validate_allowed_types_push($query_params->{TYPE_ID});
          return $validation if ($validation->{errno});
        }

        my $list = $Contacts->push_messages_list({
          UID     => $path_params->{uid},
          TITLE   => '_SHOW',
          MESSAGE => '_SHOW',
          CREATED => '_SHOW',
          STATUS  => 0,
          TYPE_ID => $query_params->{TYPE_ID} ? $query_params->{TYPE_ID} : '_SHOW',
        });

        return $list || [];
      },
      module      => 'Contacts',
      credentials => [
        'USER'
      ]
    },
  ],
}

#**********************************************************
=head2 validate_allowed_types_push()

=cut
#**********************************************************
sub _validate_allowed_types_push {
  my ($id) = @_;
  my @allowed_types = (1, 2, 3);

  if (in_array($id, \@allowed_types)) {
    return {
      result => 'OK',
    };
  }
  else {
    return {
      errno  => 9,
      errstr => 'Validation failed',
      errors => [ {
        errno          => 21,
        errstr         => 'typeId is not valid',
        param          => 'typeId',
        type           => 'number',
        allowed_params => [ 1, 2, 3 ],
        desc_params    => {
          1 => 'Web Push',
          2 => 'Android Push',
          3 => 'iOS/MacOS Silicon Push'
        }
      } ],
    }
  };
}

#**********************************************************
=head2 _validate_allowed_types_contacts()

=cut
#**********************************************************
sub _validate_allowed_types_contacts {
  my ($id) = @_;
  my @allowed_types = ();

  push @allowed_types, 5 if ($conf->{VIBER_TOKEN});
  push @allowed_types, 6 if ($conf->{TELEGRAM_TOKEN});

  if (!scalar @allowed_types) {
    return {
      errno  => 10048,
      errstr => 'No allowed contacts typeId to delete, try later'
    };
  }

  if (in_array($id, \@allowed_types)) {
    return {
      result => 'OK',
    };
  }
  else {
    my %desc_params = ();
    $desc_params{5} = 'Viber bot token' if ($conf->{VIBER_TOKEN});
    $desc_params{6} = 'Telegram bot token' if ($conf->{TELEGRAM_TOKEN});

    return {
      errno  => 9,
      errstr => 'Validation failed',
      errors => [ {
        errno          => 21,
        errstr         => 'typeId is not valid',
        param          => 'typeId',
        type           => 'number',
        allowed_params => \@allowed_types,
        desc_params    => \%desc_params
      } ],
    }
  };
}


1;
