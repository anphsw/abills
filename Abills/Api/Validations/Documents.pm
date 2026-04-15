package Api::Validations::Documents;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

use Abills::Base qw(in_array);

our @EXPORT = qw(
  PUT_USERS_DOCUMENTS
  POST_USERS_DOCUMENTS
);

our @EXPORT_OK = qw(
  PUT_USERS_DOCUMENTS
  POST_USERS_DOCUMENTS
);

use constant {
  POST_USERS_DOCUMENTS => {
    UID       => {
      required => 1,
      type     => 'unsigned_integer'
    },
    NUM       => {
      required => 1,
      type     => 'string',
    },
    DOC_TYPE  => {
      required => 1,
      type     => 'custom',
      function => \&check_users_document_types,
    },
    EXPIRE    => {},
    DATE      => {},
    ISSUED_BY => {},
    FILENAME  => {},
    IS_MAIN   => {
      type => 'unsigned_integer'
    }
  },
  PUT_USERS_DOCUMENTS  => {
    UID       => {
      type => 'unsigned_integer'
    },
    NUM       => {},
    DOC_TYPE  => {
      type     => 'custom',
      function => \&check_users_document_types,
    },
    EXPIRE    => {},
    DATE      => {},
    ISSUED_BY => {},
    FILENAME  => {},
    IS_MAIN   => {
      type => 'unsigned_integer'
    }
  },
};

#**********************************************************
=head2 check_users_document_types($validator, $value)

=cut
#**********************************************************
sub check_users_document_types {
  my ($validator, $value) = @_;

  if ($value && $value > 0 && $value < 4) {
    return {
      result => 1
    };
  }

  return {
    result  => 0,
    errstr  => 'No type with current value',
    type_id => $value,
    type    => 'unsigned_integer',
  };
}

1;
