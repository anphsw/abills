package Storage::Api::user::Installation;

=head1 NAME

  Storage User Installation

  Endpoints:
    /user/storage/installation/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Storage;
use Storage::Installation;

my Storage $Storage;
my Control::Errors $Errors;
my Storage::Installation $Installation;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    attr    => $attr,
    html    => $attr->{html},
    lang    => $attr->{lang},
    libpath => $attr->{libpath}
  };

  bless($self, $class);

  $Storage = Storage->new($db, $admin, $conf);
  $Installation = Storage::Installation->new($db, $admin, $conf, { lang => $self->{lang}, html => $self->{html}, libpath => $self->{libpath} });
  $Storage->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_user_storage_installation($path_params, $query_params)

  Endpoint POST /user/storage/installation/

=cut
#**********************************************************
sub post_user_storage_installation {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if (!$query_params->{SERIAL} || $query_params->{SERIAL} =~ /\*/) {
    return $Errors->throw_error(1180005);
  }

  my $incoming_articles = $Storage->storage_incoming_articles_list2({
    SERIAL            => $query_params->{SERIAL},
    ARTICLE_NAME      => '_SHOW',
    ARTICLE_TYPE_NAME => '_SHOW',
    SIA_COUNT         => '>0',
    SIA_SUM           => '_SHOW',
    COLS_NAME         => 1
  });

  if (!$Storage->{TOTAL} || $Storage->{TOTAL} < 1) {
    return $Errors->throw_error(1180005);
  }

  return $Installation->storage_add_installation({
    UID        => $path_params->{uid},
    ARTICLE_ID => $incoming_articles->[0]{id},
    COUNT      => 1,
    STATUS     => $query_params->{STATUS} || 0
  });
}
1;
