package Docs::Api::user::Edocs;
=head1 NAME

  Docs edocs

  Endpoints:
    /user/docs/invoices/*

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
=head2 get_user_docs_edocs_sign_id($path_params, $query_params)

  Endpoint GET /user/docs/edocs/sign/:id/

=cut
#**********************************************************
sub get_user_docs_edocs_sign_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $ESignService = $self->_init_esign_service();
  return $ESignService if ($ESignService->{errno});
  return {
    errno  => 1054030,
    errstr => 'UNKNOWN_OPERATION'
  } if (!$ESignService->can('mk_sign'));

  my $document = $Docs->edocs_list({
    ID         => $path_params->{id},
    UID        => $path_params->{uid},
    COMPANY_ID => '_SHOW',
    DOC_ID     => '_SHOW',
    DOC_TYPE   => '_SHOW',
    OFFER_ID   => '_SHOW',
    BRANCH_ID  => '_SHOW',
    COLS_UPPER => 1
  });

  return {
    errno  => 1054031,
    errstr => 'UNKNOWN_DOCUMENT'
  } if (!$Docs->{TOTAL} || $Docs->{TOTAL} < 1);

  if ($document->[0]->{company_id}) {
    require Companies;
    my $Companies = Companies->new($self->{db}, $self->{admin}, $self->{conf});
    my $company_admin = $Companies->admins_list({ UID => $path_params->{uid}, COMPANY_ID => $document->[0]->{company_id}, COLS_NAME => 1 });

    return {
      errno  => 1054032,
      errstr => 'UNKNOWN_DOCUMENT',
    } if (!scalar @{$company_admin});
  }
  elsif ($document->[0]->{uid}) {
    return {
      errno  => 1054033,
      errstr => 'UNKNOWN_DOCUMENT',
    } if ($document->[0]->{uid} ne $path_params->{uid});
  }
  else {
    return {
      errno  => 1054034,
      errstr => 'UNKNOWN_DOCUMENT',
    };
  }

  my $sign_result = $ESignService->mk_sign($document->[0]);

  return $sign_result;
}

#**********************************************************
=head2 _init_esign_service()

=cut
#**********************************************************
sub _init_esign_service {
  my $self = shift;

  require Docs::Init;
  Docs::Init->import('init_esign_service');

  my $ESignService = init_esign_service($self->{db}, $self->{admin}, $self->{conf}, {
    lang   => $self->{lang},
    html   => $self->{html},
    SILENT => 1
  });

  return {
    errno  => $ESignService->{errno} || 1054004,
    errstr => $ESignService->{errstr} || 'ESIGN_SERVICE_NOT_CONNECTED'
  } if (!%{$ESignService} || $ESignService->{errno});

  return $ESignService;
}

1;
