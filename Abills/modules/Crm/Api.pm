package Crm::Api;
=head NAME

  Crm::Api - Crm api functions

=head VERSION

  DATE: 20221130
  UPDATE: 20221130
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use Crm::db::Crm;

my Crm $Crm;

our %lang;
require 'Abills/modules/Crm/lng_english.pl';

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $debug, $type, $html) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug
  };

  bless($self, $class);

  my %LANG = (%{$lang}, %lang);

  $Crm = Crm->new($db, $admin, $conf);
  $Crm->{debug} = $self->{debug};

  $self->{routes_list} = ();

  if ($type eq 'admin') {
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
      method      => 'POST',
      path        => '/crm/lead/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        if ($query_params->{CURRENT_STEP} && $query_params->{CURRENT_STEP} =~ /\D/g) {
          my $steps = $Crm->crm_progressbar_step_list({
            ID          => '_SHOW',
            NAME        => $query_params->{CURRENT_STEP},
            STEP_NUMBER => '_SHOW',
            COLS_NAME   => 1
          });

          $query_params->{CURRENT_STEP} = $Crm->{TOTAL} > 0 ? $steps->[0]{step_number} : 1;
        }

        $Crm->crm_lead_add($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/dialogue/:id/message/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        use Abills::Sender::Core;
        my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

        my $dialog = $Crm->crm_dialogue_info({ ID => $path_params->{id} });
        my $lead = $Crm->crm_lead_info({ ID => $dialog->{LEAD_ID} });
        my $lead_address = $lead->{"_crm_$dialog->{SOURCE}"};

        return {
          errno  => 101,
          errstr => 'No found address to send'
        } if !$lead_address;

        my $result = $Sender->send_message({
          TO_ADDRESS  => $lead_address,
          MESSAGE     => Encode::encode_utf8($query_params->{MESSAGE}),
          SENDER_TYPE => ucfirst $dialog->{SOURCE},
        });
        return {
          errno  => 102,
          errstr => 'The message was not sent'
        } if !$result;

        $Crm->crm_dialogue_messages_add({
          MESSAGE     => $query_params->{MESSAGE},
          AID         => $self->{admin}{AID},
          DIALOGUE_ID => $path_params->{id}
        });

        return $result;
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/dialogue/:id/messages/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return $Crm->crm_dialogue_messages_list({
          MESSAGE     => '_SHOW',
          DAY         => '_SHOW',
          TIME        => '_SHOW',
          AID         => '_SHOW',
          PAGE_ROWS   => 99999,
          %{$query_params},
          DIALOGUE_ID => $path_params->{id},
          SORT        => 'cdm.date',
          DESC        => 'DESC',
          COLS_NAME   => 1
        });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/dialogue/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        if ($query_params->{AID}) {
          $Crm->crm_dialogue_info({ ID => $path_params->{id} });
          return { affected => $Crm->{AID} eq $query_params->{AID} ? 1 : undef } if $Crm->{AID};
        }

        $Crm->crm_dialogues_change({ ID => $path_params->{id}, %{$query_params} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/lead/:id/comment/:comment_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return $Crm->progressbar_comment_change({ ID => $path_params->{comment_id}, %{$query_params} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
  ];
}

1;
