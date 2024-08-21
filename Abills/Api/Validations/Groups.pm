package Api::Validations::Groups;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

our @EXPORT = qw(
  PUT_GROUP
  POST_GROUP
);

our @EXPORT_OK = qw(
  PUT_GROUP
  POST_GROUP
);

use constant {
  GROUP => {
    ALLOW_CREDIT     => {
      type => 'bool_number'
    },
    BONUS            => {
      type => 'bool_number'
    },
    DESCR            => {
      type => 'string'
    },
    DISABLE_ACCESS   => {
      type => 'bool_number'
    },
    DISABLE_CHG_TP   => {
      type => 'bool_number'
    },
    DISABLE_PAYMENTS => {
      type => 'bool_number'
    },
    DISABLE_PAYSYS   => {
      type => 'bool_number'
    },
    DOCUMENTS_ACCESS => {
      type => 'bool_number'
    },
    DOMAIN_ID        => {
      type => 'unsigned_integer'
    },
    NAME             => {
      type => 'string'
    },
    SEPARATE_DOCS    => {
      type => 'bool_number'
    },
    SMS_SERVICE      => {
      type => 'unsigned_integer'
    },
  },
};

use constant {
  PUT_GROUP       => {
    %{+GROUP},
  },
  POST_GROUP        => {
    %{+GROUP},
    GID              => {
      type     => 'unsigned_integer',
      required => 1
    },
  },
};

1;
