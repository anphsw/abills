package Portal::Api::user::News;

=head1 NAME

  User Portal

  Endpoints:
    /user/portal/news*
    /user/portal/menu

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(dirname cmd next_month in_array);

use Portal;
use Control::Errors;

my Portal $Portal;
my Control::Errors $Errors;

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

  $Portal = Portal->new($db, $admin, $conf);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_portal_menu($path_params, $query_params)

  GET /user/portal/menu

=cut
#**********************************************************
sub get_user_portal_menu {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $self->_portal_menu({
    UID       => $path_params->{uid} || '',
    DOMAIN_ID => $query_params->{DOMAIN_ID},
    MENU      => 1,
  });
}

#**********************************************************
=head2 get_user_portal_news($path_params, $query_params)

  GET /user/portal/news

=cut
#**********************************************************
sub get_user_portal_news {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $self->_portal_menu({
    UID       => $path_params->{uid} || '',
    DOMAIN_ID => $query_params->{DOMAIN_ID},
    PORTAL_MENU_ID => $query_params->{PORTAL_MENU_ID},
    MAIN_PAGE => $query_params->{MAIN_PAGE},
    LIST      => 1
  });
}


#**********************************************************
=head2 get_user_portal_news_id($path_params, $query_params)($path_params, $query_params)

  GET /user/portal/news/:id/

=cut
#**********************************************************
sub get_user_portal_news_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $self->_portal_menu({
    UID        => $path_params->{uid} || '',
    ARTICLE_ID => $path_params->{id},
    DOMAIN_ID  => $query_params->{DOMAIN_ID},
    LIST       => 1
  });
}

#**********************************************************
=head2 _portal_menu($attr) - inner portal news

  Arguments:
    UID: int        - user identifier
    DOMAIN_ID: int  - id of domain
    LIST: boolean   - return as object with keys topics, news
    MENU: boolean   - build as array of topics inside with news

  Returns:
    List OR menu OR single article

=cut
#**********************************************************
sub _portal_menu {
  my $self = shift;
  my ($attr) = @_;

  my %menu = ();
  my %article_params = ();
  my %menu_params = ();
  my @topics = ();
  my @news = ();
  my $uid = $attr->{UID} || '';
  my $domain_id = $attr->{DOMAIN_ID} || '';

  $article_params{ID} = $attr->{ARTICLE_ID} if ($attr->{ARTICLE_ID});
  $article_params{PORTAL_MENU_ID} = $attr->{PORTAL_MENU_ID} if ($attr->{PORTAL_MENU_ID});
  $article_params{MAIN_PAGE} = $attr->{MAIN_PAGE} if ($attr->{MAIN_PAGE});

  my $news_list = $Portal->portal_articles_list({
    %article_params,
    ARCHIVE   => 0,
    COLS_NAME => 1,
    PAGE_ROWS => 10000
  });

  return {
    errno  => 10901,
    errstr => "News not found with id $attr->{ARTICLE_ID}",
  } if (!($Portal->{TOTAL} && $Portal->{TOTAL} > 0) && $attr->{ARTICLE_ID});

  $menu_params{ID} = $news_list->[0]->{portal_menu_id} if ($attr->{ARTICLE_ID});

  my $menu_portal = $Portal->portal_menu_list({
    %menu_params,
    STATUS    => 1,
    COLS_NAME => 1,
    ID        => '_SHOW',
    NAME      => '_SHOW',
    URL       => '_SHOW'
  });

  foreach my $menu (@{$menu_portal}) {
    my %topic = (
      id   => $menu->{id},
      name => $menu->{name},
    );

    $topic{url} = $menu->{url} if ($menu->{url});

    if ($attr->{MENU}) {
      $menu{$menu->{id}} = \%topic;
    }
    else {
      $menu{$menu->{id}} = 1;
      push @topics, \%topic;
    }
  }

  my $Users = {
    DOMAIN_ID        => 0,
    GID              => 0,
    DISTRICT_ID      => 0,
    STREET_ID        => 0,
    LOCATION_ID      => 0,
    ADDRESS_FLAT     => '',
    UID              => '--'
  };

  if ($uid) {
    require Users;
    Users->import();
    $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
    $Users->info($uid);
    $Users->pi({ UID => $uid });
    $Users->{DISTRICT_ID} //= 0;
    $Users->{STREET_ID} //= 0;
    $Users->{LOCATION_ID} //= 0;
    $Users->{ADDRESS_FLAT} //= '',
  }

  my $Tags = q{};
  if (in_array('Tags', \@main::MODULES)) {
    require Tags;
    Tags->import();
    $Tags = Tags->new($self->{db}, $self->{admin}, $self->{conf});
  }

  foreach my $news (@{$news_list}) {
    my @gids = split(/,\s*/, $news->{gid} || '');

    my $time_check = !$news->{etimestamp} || ($news->{utimestamp} && $news->{etimestamp} >= time && $news->{utimestamp} < time);
    my $gid_check = !$news->{gid} || $news->{gid} eq '0' || $news->{gid} eq '*' || grep { $_ eq "$Users->{GID}"} @gids;
    my $domain_check = (!$news->{domain_id} ||
      ($domain_id && "$news->{domain_id}" eq "$domain_id") ||
      ($Users->{DOMAIN_ID} && $news->{domain_id} == $Users->{DOMAIN_ID}));

    my $address_check = (!$news->{district_id} || $news->{district_id} eq $Users->{DISTRICT_ID})
      && (!$news->{street_id} || $news->{street_id} eq $Users->{STREET_ID})
      && (!$news->{build_id} || $news->{build_id} eq $Users->{LOCATION_ID})
      && (!$news->{address_flat} || $news->{address_flat} eq $Users->{ADDRESS_FLAT});

    my $tag_check = ($news->{tags} && !$uid) ? 0 : 1;
    if ($Tags) {
      my $tag = $Tags->tags_user({ COLS_NAME => 1, UID => $Users->{UID}, TAG_ID => $news->{tags} });
      $tag_check = defined($tag->[0]->{date}) || !$news->{tags};
    }

    if ($time_check && $gid_check && $domain_check && $address_check && $tag_check) {
      next if (!$menu{$news->{portal_menu_id}});
      my $article_sublink = $news->{permalink} || $news->{id};
      my $article_url = $self->_portal_link() . "/?article=$article_sublink";
      my $picture_link = $news->{picture} ? $self->_portal_link() . "/images/attach/portal/$news->{picture}" : '';

      my %news = (
        id                => $news->{id},
        importance        => $news->{importance},
        title             => $news->{title},
        content           => $news->{content},
        short_description => $news->{short_description},
        picture           => $picture_link,
        on_main_page      => $news->{on_main_page},
        date              => $news->{date},
        topic_id          => $news->{portal_menu_id},
        permalink         => $news->{permalink},
        url               => $article_url
      );

      if ($attr->{MENU}) {
        push @{$menu{$news->{portal_menu_id}}{news}}, \%news;
      }
      else {
        push @news, \%news;
      }
    }
  }

  if ($attr->{MENU}) {
    my @menu = map {$menu{$_}} sort keys %menu;
    return \@menu;
  }
  else {
    return {
      news   => \@news,
      topics => \@topics,
    };
  }
}

#**********************************************************
=head2 _portal_link()

  Returns:
    $src - main url

=cut
#**********************************************************
sub _portal_link {
  my $self = shift;

  my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  my $maybe_base = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}" : '';
  my $base_attach_link = ($self->{conf}{BILLING_URL} || $maybe_base);

  return $base_attach_link;
}

1;
