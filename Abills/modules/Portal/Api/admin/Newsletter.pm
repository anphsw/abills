package Portal::Api::admin::Newsletter;

=head1 NAME

  Portal newsletter manage

  Endpoints:
    /portal/newsletter/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(dirname cmd next_month in_array);
use Control::Errors;

use Portal;
use Portal::Constants qw(ALLOWED_METHODS);

my Portal $Portal;
my Control::Errors $Errors;

my %permissions = ();

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
  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_portal_newsletter($path_params, $query_params)

  Endpoint GET /portal/newsletter

=cut
#**********************************************************
sub get_portal_newsletter {
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

  my $list = $Portal->portal_newsletter_list({ %$query_params, %PARAMS });

  my @result = map {
    my $article_sublink = $_->{permalink} || $_->{article_id};
    $_->{url} = $self->_portal_news_link($article_sublink);
    $_
  } @$list;

  return {
    list  => \@result,
    total => $Portal->{TOTAL}
  };
}


#**********************************************************
=head2 get_portal_newsletter_id($path_params, $query_params)

  Endpoint GET /portal/newsletter/:id/

=cut
#**********************************************************
sub get_portal_newsletter_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0')
      ? $query_params->{$param}
      : '_SHOW';
  }
  $query_params->{COLS_NAME} = 1;

  my $list = $Portal->portal_newsletter_list({ NEWSLETTER_ID => $path_params->{id}, %$query_params });

  my @result = map {
    my $article_sublink = $_->{permalink} || $_->{article_id};
    $_->{url} = $self->_portal_news_link($article_sublink);
    $_
  } @$list;

  return $result[0] || {};
}

#**********************************************************
=head2 post_portal_newsletter($path_params, $query_params)

  Endpoint POST /portal/newsletter

=cut
#**********************************************************
sub post_portal_newsletter {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Abills::Sender::Core;
  my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});
  my $available_methods = $Sender->available_types({ SOFT_CHECK => 1, HASH_RETURN => 1 });
  my @available_methods_ids = keys %$available_methods;

  my $is_available = (in_array($query_params->{SEND_METHOD}, ALLOWED_METHODS) && in_array($query_params->{SEND_METHOD}, \@available_methods_ids));

  if (!$is_available) {
    return $Errors->throw_error(1440001, { lang_vars => { ID => $query_params->{SEND_METHOD} }});
  };

  my $list = $Portal->portal_articles_list({ ID => $query_params->{PORTAL_ARTICLE_ID}, COLS_NAME => 1 });

  if (!($list && scalar(@$list))) {
    return $Errors->throw_error(1440002, { lang_vars => { ID => $query_params->{PORTAL_ARTICLE_ID} }});
  }

  my $newsletters = $Portal->portal_newsletter_list({
    ID => $query_params->{PORTAL_ARTICLE_ID},
    COLS_NAME => 1
  });

  my @new_with_same_method =
    grep { $_->{status} == 0 && $_->{send_method} == $query_params->{SEND_METHOD} } @$newsletters;
  if (@new_with_same_method) {
    return $Errors->throw_error(1440003, { lang_vars => $query_params });
  }

  return $Portal->portal_newsletter_add($query_params);
}

#**********************************************************
=head2 delete_portal_newsletter_id($path_params, $query_params)

  Endpoint DELETE /portal/newsletter/:id/

=cut
#**********************************************************
sub delete_portal_newsletter_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $list = $Portal->portal_newsletter_list({ NEWSLETTER_ID => $path_params->{id}, COLS_NAME => 1 });

  if (!($list && scalar(@$list))) {
    return $Errors->throw_error(1440004, { lang_vars => { ID => $path_params->{id} }});
  }

  if (grep { $_->{status} != 0 } @$list ) {
    return $Errors->throw_error(1440005)
  }
  return $Portal->portal_newsletter_delete({ ID => $path_params->{id} });
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

1;
