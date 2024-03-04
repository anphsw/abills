package Portal::Api::admin::Articles;

=head1 NAME

  Portal articles manage

  Endpoints:
    /portal/articles/*

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
=head2 get_portal_articles($path_params, $query_params)

  Endpoint GET /portal/articles

=cut
#**********************************************************
sub get_portal_articles {
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

  my $list = $Portal->portal_articles_list({ %$query_params, %PARAMS });

  my @result = map {
    my $article_sublink = $_->{permalink} || $_->{id};
    my $picture_link = $_->{picture} ? $self->_portal_picture_link($_->{picture}) : '';
    $_->{url} = $self->_portal_news_link($article_sublink);
    $_->{picture} = $picture_link;
    $_
  } @$list;

  return {
    list  => \@result,
    total => $Portal->{TOTAL}
  };
}


#**********************************************************
=head2 get_portal_articles_id($path_params, $query_params)

  Endpoint GET /portal/articles/:id/

=cut
#**********************************************************
sub get_portal_articles_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0')
      ? $query_params->{$param}
      : '_SHOW';
  }
  $query_params->{COLS_NAME} = 1;

  my $list = $Portal->portal_articles_list({ ID => $path_params->{id}, %$query_params });

  my @result = map {
    my $article_sublink = $_->{permalink} || $_->{id};
    my $picture_link = $_->{picture} ? $self->_portal_picture_link($_->{picture}) : '';
    $_->{url} = $self->_portal_news_link($article_sublink);
    $_->{picture} = $picture_link;
    $_
  } @$list;

  return $result[0] || {};
}

#**********************************************************
=head2 post_portal_articles($path_params, $query_params)

  Endpoint POST /portal/articles

=cut
#**********************************************************
sub post_portal_articles {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if ($query_params->{PICTURE}) {
    my $picture_name = $Attachments->save_picture($query_params->{PICTURE});
    $query_params->{PICTURE} = $picture_name;
  }

  my $permalink = $query_params->{PERMALINK} || _portal_generate_permalink($query_params->{TITLE});

  return $Portal->portal_article_add({ %$query_params, PERMALINK => $permalink });;
}

#**********************************************************
=head2 put_portal_articles_id($path_params, $query_params)

  PUT /portal/articles/:id

=cut
#**********************************************************
sub put_portal_articles_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if ($query_params->{PICTURE}) {
    my $picture_name = $Attachments->save_picture($query_params->{PICTURE}, $path_params->{id});
    $query_params->{PICTURE} = $picture_name;
  }

  my $permalink = $query_params->{PERMALINK} || _portal_generate_permalink($query_params->{TITLE});

  return $Portal->portal_article_change({ %$query_params, PERMALINK => $permalink });
}

#**********************************************************
=head2 delete_portal_articles_id($path_params, $query_params)

  Endpoint DELETE /portal/articles/:id/

=cut
#**********************************************************
sub delete_portal_articles_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $list = $Portal->portal_articles_list({ ID => $path_params->{id}, COLS_NAME => 1 });

  if (!($list && scalar(@$list))) {
    return $Errors->throw_error(1440002, { lang_vars => { ID => $path_params->{id} }});
  }

  my $result = $Portal->portal_article_del({ ID => $path_params->{id} });
  if (!$Portal->{errno}) {
    $Attachments->delete_attachment($path_params->{id});
  }

  return $result;
}

#**********************************************************
=head2 _portal_news_link($filename)

  Arguments:
    $permalink - string

  Returns:
    $src - link to news from web
=cut
#**********************************************************
sub _portal_news_link {
  my $self = shift;
  my ($filename) = @_;

  my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  my $maybe_base = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}" : '';
  my $base_attach_link = ($self->{conf}{BILLING_URL} || $maybe_base) . '/?article=';

  return $base_attach_link . ($filename || '');
}

#**********************************************************
=head2 _portal_make_link($filename)

  Arguments:
    $filename - string

  Returns:
    $src - link to file from web

=cut
#**********************************************************
sub _portal_picture_link {
  my $self = shift;
  my ($filename) = @_;

  my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  my $maybe_base = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}" : '';
  my $base_attach_link = ($self->{conf}{BILLING_URL} || $maybe_base) . '/images/attach/portal/';

  return $base_attach_link . $filename;
}
#**********************************************************
=head2 _portal_generate_permalink($title) - creates permalink

  Arguments:
    $attr - title

  Returns:
    $permalink

=cut
#**********************************************************
sub _portal_generate_permalink {
  my ($title) = @_;

  require Encode;

  $title =~ s/\n/-/gm;
  my $permalink = $title;
  $permalink =~ s/ +/-/gm;
  $permalink =~ s/\.//gm;
  # Forced by convert to translit issue
  $permalink = Encode::encode("UTF-8", $permalink);
  $permalink = Encode::decode("UTF-8", $permalink);
  $permalink = convert($permalink, { txt2translit => 1 });
  $permalink =~ s/'//gm;
  $permalink =~ s/'//gm;
  $permalink =~ s/[^\w-]+//gm;
  return lc($permalink);
}

1;
