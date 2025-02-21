package Docs::Api::user::Root;
=head1 NAME

  Portal articles manage

  Endpoints:
    /user/docs/*

=cut
use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Docs;

my Docs $Docs;
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
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Docs = Docs->new($db, $admin, $conf);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_docs($path_params, $query_params)

  Endpoint GET /user/docs

=cut
#**********************************************************
sub get_user_docs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Docs->user_info($path_params->{uid});

  if ($Docs->{errno}) {
    delete @{$Docs}{qw/AFFECTED DOCS_ACCOUNT_EXPIRE_PERIOD TOTAL/};
    return $Docs;
  }
  else {
    return {
      UID          => $Docs->{UID},
      EMAIL        => $Docs->{EMAIL},
      NEXT_INVOICE_DATE => $Docs->{NEXT_INVOICE_DATE},
      INVOICING_PERIOD => $Docs->{INVOICING_PERIOD},
    };
  }
}

1;
