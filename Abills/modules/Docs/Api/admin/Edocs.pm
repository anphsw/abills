package Docs::Api::admin::Edocs;
=head1 NAME

  Docs edocs

  Endpoints:
    /docs/edocs/*

=cut
use strict;
use warnings FATAL => 'all';

use Abills::Base;
use Control::Errors;
use Docs;
use Docs::Constants qw(EDOCS_STATUS);

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
=head2 post_docs_edocs($path_params, $query_params)

  Endpoint POST /docs/edocs/

=cut
#**********************************************************
sub post_docs_edocs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 1054006,
    errstr => 'No required field docType'
  } if (!$query_params->{DOC_TYPE});

  return {
    errno  => 1054007,
    errstr => 'Not valid field docType required. Allowed types is numbers: 2 - act and 4 - contractId',
  } if (!in_array($query_params->{DOC_TYPE}, [ 2, 4 ]));

  return {
    errno  => 1054008,
    errstr => 'No field branchId or orderId'
  } if (!$query_params->{BRANCH_ID} || !$query_params->{OFFER_ID});

  return {
    errno  => 1054009,
    errstr => 'No field uid or companyId'
  } if (!$query_params->{UID} && !$query_params->{COMPANY_ID});

  my $documents = $Docs->edocs_list({
    DOC_TYPE   => $query_params->{DOC_TYPE},
    DOC_ID     => $query_params->{DOC_ID},
    UID        => $query_params->{UID} || '_SHOW',
    COMPANY_ID => $query_params->{COMPANY_ID} || '_SHOW',
    STATUS     => '_SHOW',
    COLS_NAME  => 1,
  });

  return {
    result   => EDOCS_STATUS->{$documents->[0]->{status}} || 'OK',
    warning  => 1054010,
    document => $documents->[0],
    id       => $documents->[0]->{id},
  } if ($Docs->{TOTAL} && $Docs->{TOTAL} > 0);

  $Docs->edocs_add({ %$query_params, STATUS => 1, AID => $self->{admin}->{AID}, });

  return $Docs if $Docs->{errno};

  ::load_module('Abills::Templates', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Abills/Templates.pm'}));
  ::load_module('Docs', $self->{html});

  my %info = (
    %{$query_params},
    DOC_ID        => $query_params->{DOC_ID},
    CERT          => '',
    PDF           => $self->{conf}->{DOCS_PDF_PRINT} ? 1 : 0,
    SAVE_DOCUMENT => 1
  );

  if ($query_params->{DOC_TYPE} == 4) {
    ::docs_contract(\%info);
  }
  elsif ($query_params->{DOC_TYPE} == 2) {
    require Docs::Acts;

    if ($query_params->{COMPANY_ID}) {
      require Companies;
      my $Companies = Companies->new($self->{db}, $self->{admin}, $self->{conf});
      $info{COMPANY} = $Companies->info($query_params->{COMPANY_ID});
    }
    else {
      require Users;
      my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
      $Users->info($query_params->{UID});
      $info{USER_INFO} = $Users->pi({ UID => $query_params->{UID} });
      $info{COMPANY} = {};
    }

    ::docs_acts_print(\%info);
  }

  return {
    result => 'DOCUMENT_SEND_USER_FOR_SIGN',
    id     => $Docs->{INSERT_ID},
  };
}

#**********************************************************
=head2 get_docs_edocs($path_params, $query_params)

  Endpoint GET /docs/edocs/

=cut
#**********************************************************
sub get_docs_edocs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $ESignService = $self->_init_esign_service();
  return $ESignService if ($ESignService->{errno});
  return {
    errno  => 1054005,
    errstr => 'Unknown operation'
  } if (!$ESignService->can('get_branches'));

  my $branches = $ESignService->get_branches();

  my $documents = $Docs->edocs_list({
    %$query_params,
    STATUS    => $query_params->{STATUS} || '_SHOW',
    OFFER_ID  => $query_params->{OFFER_ID} || '_SHOW',
    BRANCH_ID => $query_params->{BRANCH_ID} || '_SHOW',
    COLS_NAME => 1,
  });

  foreach my $document (@{$documents}) {
    $document->{status_message} = EDOCS_STATUS->{$document->{status}} || 'OK';
    $document->{branch_info} = $branches->{$document->{branch_id} || ''} || '';
    $document->{offer_info} = $branches->{$document->{branch_id} || ''}->{offers}->{$document->{offer_id} || ''} || '';
  }

  return $documents;
}

#**********************************************************
=head2 delete_docs_edocs_id($path_params, $query_params)

  Endpoint DELETE /docs/edocs/

=cut
#**********************************************************
sub delete_docs_edocs_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $ESignService = $self->_init_esign_service();
  return $ESignService if ($ESignService->{errno});
  return {
    errno  => 1054005,
    errstr => 'Unknown operation'
  } if (!$ESignService->can('get_branches'));

  my $branches = $ESignService->get_branches();

  my $documents = $Docs->edocs_list({
    %$query_params,
    STATUS    => $query_params->{STATUS} || '_SHOW',
    OFFER_ID  => $query_params->{OFFER_ID} || '_SHOW',
    BRANCH_ID => $query_params->{BRANCH_ID} || '_SHOW',
    COLS_NAME => 1,
  });

  foreach my $document (@{$documents}) {
    $document->{status_message} = EDOCS_STATUS->{$document->{status}} || 'OK';
    $document->{branch_info} = $branches->{$document->{branch_id} || ''} || '';
    $document->{offer_info} = $branches->{$document->{branch_id} || ''}->{offers}->{$document->{offer_id} || ''} || '';
  }

  return $documents;
}

#**********************************************************
=head2 get_docs_edocs_branches($path_params, $query_params)

  Endpoint GET /docs/edocs/branches/

=cut
#**********************************************************
sub get_docs_edocs_branches {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $ESignService = $self->_init_esign_service();
  return $ESignService if ($ESignService->{errno});
  return {
    errno  => 1054005,
    errstr => 'Unknown operation'
  } if (!$ESignService->can('get_branches'));

  my $branches = $ESignService->get_branches();

  return $branches;
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
