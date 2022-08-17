package Msgs::Api;
=head NAME

  Paysys::Api - Paysys api functions

=head VERSION

  DATE: 20220608
  UPDATE: 20220610
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use Msgs;
use Msgs::Notify;

my Msgs $Msgs;
my Msgs::Notify $Notify;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $conf, $admin, $lang, $debug, $type) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug
  };

  bless($self, $class);

  $Msgs = Msgs->new($self->{db}, $self->{admin}, $self->{conf});
  $self->{permissions} = $Msgs->permissions_list($admin->{AID});

  $Msgs->{debug} = $self->{debug};

  $self->{routes_list} = ();

  if ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }
  elsif ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  return $self;
}

#**********************************************************
=head2 user_routes() - Returns available API paths

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
sub user_routes {
  my $self = shift;

  return [
    {
      method      => 'GET',
      path        => '/user/:uid/msgs/chapters/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $chapters = $Msgs->chapters_list({
          INNER_CHAPTER => 0,
          COLS_NAME     => 1,
        });

        foreach my $chapter (@{$chapters}) {
          if (ref $chapter eq 'HASH') {
            delete @{$chapter}{qw/admin_login autoclose inner_chapter responsible/};
          }
        }

        return $chapters;
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/:uid/msgs/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Msgs->messages_list({
          COLS_NAME     => 1,
          SUBJECT       => '_SHOW',
          STATE_ID      => '_SHOW',
          DATE          => '_SHOW',
          MESSAGE       => '_SHOW',
          CHAPTER_NAME  => '_SHOW',
          CHAPTER_COLOR => '_SHOW',
          STATE         => '_SHOW',
          UID           => $path_params->{uid}
        });
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/:uid/msgs/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Msgs->message_add({
          %$query_params,
          UID => $path_params->{uid}
        });
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/:uid/msgs/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Msgs->message_info($path_params->{id}, { UID => $path_params->{uid} });
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/:uid/msgs/:id/reply/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $reply_list = $Msgs->messages_reply_list({
          MSG_ID    => $path_params->{id},
          UID       => $path_params->{uid},
          INNER_MSG => 0,
          LOGIN     => '_SHOW',
          ADMIN     => '_SHOW',
          COLS_NAME => 1
        });

        my $first_msg = $Msgs->message_info($path_params->{id}, { UID => $path_params->{uid} });

        unshift @$reply_list, {
          'creator_id'    => ($first_msg->{AID} || q{}),
          'admin'         => '',
          'datetime'      => ($first_msg->{DATE} || q{}),
          'survey_id'     => ($first_msg->{SURVEY_ID} || 0),
          'status'        => 0,
          'uid'           => ($first_msg->{UID} || q{}),
          'caption'       => '',
          'run_time'      => '',
          'creator_fio'   => '',
          'inner_msg'     => ($first_msg->{INNER_MSG} || q{}),
          'main_msg'      => 0,
          'ip'            => ($first_msg->{IP} || q{}),
          'text'          => ($first_msg->{MESSAGE} || q{}),
          'id'            => $path_params->{id},
          'aid'           => ($first_msg->{AID} || q{})
        };

        foreach my $reply (@{$reply_list}) {
          if (ref $reply eq 'HASH') {
            delete @{$reply}{qw/filename attachment_id content_size run_time inner_msg ip/};
          }

          my $attachments_list = $Msgs->attachments_list({
            REPLY_ID     => $reply->{id},
            FILENAME     => '_SHOW',
            CONTENT_SIZE => '_SHOW',
            CONTENT_TYPE => '_SHOW',
            CONTENT      => '_SHOW',
          });

          if ($attachments_list && scalar(@{$attachments_list}) > 0) {
            my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
            my $SELF_URL = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}/images" : '';

            foreach my $attachment (@$attachments_list) {
              my $content = $attachment->{content} || '';
              my ($file_path) = $content =~ /Abills\/templates(\/.+)/;

              push @{$reply->{attachments}}, {
                id           => $attachment->{id},
                content_size => $attachment->{content_size} || 0,
                filename     => $attachment->{filename} || q{},
                content_type => $attachment->{content_type} || q{},
                file_path    => ($SELF_URL || q{}) . ($file_path || q{}),
              };
            }
          }
        }

        return $reply_list;
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/:uid/msgs/:id/reply/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Msgs->message_reply_add({
          REPLY_TEXT => $query_params->{REPLY_TEXT} || '',
          ID         => $path_params->{id},
          UID        => $path_params->{uid},
          STATE      => $query_params->{STATUS} || 0,
        });

        $Msgs->message_change({
          ID         => $path_params->{id},
          STATE      => 0,
          ADMIN_READ => '0000-00-00 00:00:00'
        });

        $Notify->notify_admins({ MSG_ID => $path_params->{id} });
        ($Msgs->{errno}) ? return 0 : return 1;
      },
      credentials => [
        'USER'
      ]
    },
  ]
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
      path        => '/msgs/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 100,
          errstr => 'No permission to add messages'
        } if !$self->{permissions}{1}{0};

        return {
          errno  => 101,
          errstr => 'No permission for this chapter'
        } if ($query_params->{CHAPTER} && $self->{permissions}{4} && !$self->{permissions}{4}{$query_params->{CHAPTER}});

        $Msgs->message_add({
          %$query_params
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/msgs/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $message = $Msgs->message_info($path_params->{id});

        return {
          errno  => 102,
          errstr => 'The message cannot be accessed'
        } if $self->{permissions}{1}{21} && (!$message->{RESPOSIBLE} || $message->{RESPOSIBLE} ne $self->{admin}{AID});

        return {
          errno  => 103,
          errstr => 'The message cannot be accessed'
        } if $self->{permissions}{4} && (!$message->{CHAPTER} || !$self->{permissions}{4}{$message->{CHAPTER}});

        return $message;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/msgs/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        if ($query_params->{CHAPTER} && $self->{permissions}{4}) {
          my @available_chapters = keys %{$self->{permissions}{4}};

          $query_params->{CHAPTER} = $query_params->{CHAPTER} eq '_SHOW' ? join(';', @available_chapters)
            : join(';', grep { Abills::Base::in_array($_, \@available_chapters) } split('[,;]\s?', $query_params->{CHAPTER}));
        }
        elsif ($self->{permissions}{4}) {
          $query_params->{CHAPTER} = join(';', keys %{$self->{permissions}{4}});
        }

        $Msgs->messages_list({
          %$query_params,
          COLS_NAME    => 1,
          SUBJECT      => '_SHOW',
          STATE_ID     => '_SHOW',
          DATE         => '_SHOW'
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/msgs/:id/reply/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Msgs->message_reply_add({
          %$query_params,
          ID => $path_params->{id}
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/msgs/:id/reply/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Msgs->messages_reply_list({
          %$query_params,
          MSG_ID    => $path_params->{id},
          LOGIN     => '_SHOW',
          ADMIN     => '_SHOW',
          COLS_NAME => 1
        });
      },
      type        => 'ARRAY',
      credentials => [
        'ADMIN'
      ]
    },
    {
      #TODO: we can save attachment with wrong filesize. fix it?
      method       => 'POST',
      path         => '/msgs/reply/:reply_id/attachment/',
      handler      => sub {
        my ($path_params, $query_params) = @_;

        $Msgs->attachment_add({
          %$query_params,
          REPLY_ID  => $path_params->{reply_id},
          COLS_NAME => 1
        });
      },
      module       => 'Msgs',
      credentials  => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/msgs/chapters/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        if ($query_params->{CHAPTER} && $self->{permissions}{4}) {
          my @available_chapters = keys %{$self->{permissions}{4}};

          $query_params->{CHAPTER} = $query_params->{CHAPTER} eq '_SHOW' ? join(';', @available_chapters)
            : join(';', grep { Abills::Base::in_array($_, \@available_chapters) } split('[,;]\s?', $query_params->{CHAPTER}));
        }
        elsif ($self->{permissions}{4}) {
          $query_params->{CHAPTER} = join(';', keys %{$self->{permissions}{4}});
        }

        return {
          errno  => 104,
          errstr => 'Access denied'
        } if (defined $query_params->{CHAPTER} && !$query_params->{CHAPTER});

        $Msgs->chapters_list({
          %$query_params,
          COLS_NAME => 1
        });
      },
      credentials => [
        'ADMIN'
      ]
    }
  ];
}

1;
