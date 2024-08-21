package Tags::Api::Validations;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

our @EXPORT = qw(
  POST_TAGS
  PUT_TAGS
);

our @EXPORT_OK = qw(
  POST_TAGS
  PUT_TAGS
);

use constant {
  POST_TAGS => {
    NAME        => {
      required => 1,
      type     => 'string',
    },
    EXPIRE_DAYS => {
      type => 'unsigned_integer'
    },
    PRIORITY    => {
      type        => 'enum',
      value_type  => 'integer',
      values      => [ 0 .. 4 ],
      values_desc => {
        0 => 'very low',
        1 => 'low',
        2 => 'normal',
        3 => 'high',
        4 => 'very high',
      }
    },
    COMMENTS    => {
      type => 'string',
    },
    COLOR       => {
      type  => 'string',
      regex => '^#?([a-f0-9]{6})$'
    },
    RESPONSIBLE => {
      type => 'string',
      regex => '^\d+(,\d+)*$'
    }
  },
};

use constant {
  PUT_TAGS => {
    %{+POST_TAGS},
    NAME => {
      type => 'string',
    },
  },
};

1;
