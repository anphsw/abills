package Tasks::Validations;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

our @EXPORT = qw(
  POST_TASKS
);

our @EXPORT_OK = qw(
  POST_TASKS
);

use constant {
  POST_TASKS => {
    NAME         => {
      required => 1,
      type     => 'string',
    },
    DESCR        => {
      type => 'string',
    },
    TASK_TYPE    => {
      type => 'unsigned_integer',
    },
    RESPONSIBLE  => {
      type => 'unsigned_integer'
    },
    PARENT_ID    => {
      # type => 'unsigned_integer'
    },
    CONTROL_DATE => {
      type => 'date'
    }
  },
};

1;