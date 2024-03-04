package Portal::Api;

=head1 NAME

  Portal Api

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array);
use Control::Errors;

use Portal::Validations qw(POST_PORTAL_NEWSLETTER POST_PORTAL_ARTICLES POST_PORTAL_MENUS);

my Control::Errors $Errors;

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

  $Errors = Control::Errors->new($self->{db}, $self->{admin}, $self->{conf},
    { lang => $lang, module => 'Portal' }
  );

  $self->{routes_list} = ();

  if ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  } elsif ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
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
      method      => 'GET',
      path        => '/user/portal/menu/',
      handler     => sub {
        #TODO: make load and object creating from API itself like option "module"
        require Portal::Api::user::News;
        my $User_news = Portal::Api::user::News->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $User_news->get_user_portal_menu(@_);
      },
      credentials => [
        'USER', 'USERSID', 'PUBLIC'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/portal/news/',
      handler     => sub {
        require Portal::Api::user::News;
        my $User_news = Portal::Api::user::News->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $User_news->get_user_portal_news(@_);
      },
      credentials => [
        'USER', 'USERSID', 'PUBLIC'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/portal/news/:string_id/',
      handler     => sub {
        require Portal::Api::user::News;
        my $User_news = Portal::Api::user::News->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $User_news->get_user_portal_news_id(@_);
      },
      credentials => [
        'USER', 'USERSID', 'PUBLIC'
      ]
    },
  ];
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
      path        => '/portal/attachment/',
      handler     => sub {
        require Portal::Api::admin::Attachment;
        my $Attachment = Portal::Api::admin::Attachment->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Attachment->get_portal_attachment(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/portal/attachment/',
      handler     => sub {
        require Portal::Api::admin::Attachment;
        my $Attachment = Portal::Api::admin::Attachment->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Attachment->post_portal_attachment(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/attachment/:id/',
      handler     => sub {
        require Portal::Api::admin::Attachment;
        my $Attachment = Portal::Api::admin::Attachment->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Attachment->get_portal_attachment_id(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/portal/attachment/:id/',
      handler     => sub {
        require Portal::Api::admin::Attachment;
        my $Attachment = Portal::Api::admin::Attachment->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Attachment->delete_portal_attachment_id(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/newsletter/',
      handler     => sub {
        require Portal::Api::admin::Newsletter;
        my $Newsletter = Portal::Api::admin::Newsletter->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->get_portal_newsletter(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/portal/newsletter/',
      params      => POST_PORTAL_NEWSLETTER,
      handler     => sub {
        require Portal::Api::admin::Newsletter;
        my $Newsletter = Portal::Api::admin::Newsletter->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->post_portal_newsletter(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/newsletter/:id/',
      handler     => sub {
        require Portal::Api::admin::Newsletter;
        my $Newsletter = Portal::Api::admin::Newsletter->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->get_portal_newsletter_id(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/portal/newsletter/:id/',
      handler     => sub {
        require Portal::Api::admin::Newsletter;
        my $Newsletter = Portal::Api::admin::Newsletter->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->delete_portal_newsletter_id(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/articles/',
      handler     => sub {
        require Portal::Api::admin::Articles;
        my $Newsletter = Portal::Api::admin::Articles->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->get_portal_articles(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/portal/articles/',
      params      => POST_PORTAL_ARTICLES,
      handler     => sub {
        require Portal::Api::admin::Articles;
        my $Newsletter = Portal::Api::admin::Articles->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->post_portal_articles(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/articles/:id/',
      handler     => sub {
        require Portal::Api::admin::Articles;
        my $Newsletter = Portal::Api::admin::Articles->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->get_portal_articles_id(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/portal/articles/:id/',
      handler     => sub {
        require Portal::Api::admin::Articles;
        my $Newsletter = Portal::Api::admin::Articles->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->put_portal_articles_id(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/portal/articles/:id/',
      handler     => sub {
        require Portal::Api::admin::Articles;
        my $Newsletter = Portal::Api::admin::Articles->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->delete_portal_articles_id(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/menus/',
      handler     => sub {
        require Portal::Api::admin::Menus;
        my $Newsletter = Portal::Api::admin::Menus->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->get_portal_menus(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/portal/menus/',
      params      => POST_PORTAL_MENUS,
      handler     => sub {
        require Portal::Api::admin::Menus;
        my $Newsletter = Portal::Api::admin::Menus->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->post_portal_menus(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/menus/:id/',
      handler     => sub {
        require Portal::Api::admin::Menus;
        my $Newsletter = Portal::Api::admin::Menus->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->get_portal_menus_id(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/portal/menus/:id/',
      handler     => sub {
        require Portal::Api::admin::Menus;
        my $Newsletter = Portal::Api::admin::Menus->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->put_portal_menus_id(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/portal/menus/:id/',
      handler     => sub {
        require Portal::Api::admin::Menus;
        my $Newsletter = Portal::Api::admin::Menus->new($self->{db}, $self->{admin}, $self->{conf}, { Errors => $Errors });

        return $Newsletter->delete_portal_menus_id(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
  ];
}

1;
