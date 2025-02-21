package Crm::Validations;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

our @EXPORT = qw(
  POST_CRM_LEADS_SOCIAL
  POST_CRM_LEADS_DIALOGUE_MESSAGE
);

our @EXPORT_OK = qw(
  POST_CRM_LEADS_SOCIAL
  POST_CRM_LEADS_DIALOGUE_MESSAGE
);

use constant {
  ATTACHMENT_OBJ => {
    FILE_NAME    => {
      required => 1,
      type     => 'string',
    },
    CONTENTS     => {
      required => 1,
      # FIXME: several binary contents crashes on string check.
      # type     => 'string'
    },
    CONTENT_TYPE => {
      required => 1,
      type     => 'string'
    },
    SIZE         => {
      required => 1,
      type     => 'unsigned_integer'
    },
  },
};

use constant {
  POST_CRM_LEADS_SOCIAL           => {
    FIO   => {
      type => 'string',
    },
    PHONE => {
      type => 'string',
    },
    EMAIL => {
      type => 'string',
    },
  },
  POST_CRM_LEADS_DIALOGUE_MESSAGE => {
    MESSAGE     => {
      required => 1,
      type     => 'string',
    },
    ATTACHMENTS => {
      type  => 'array',
      items => {
        type       => 'object',
        properties => ATTACHMENT_OBJ
      }
    },
  }
};

1;
