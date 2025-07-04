package Triplay::Validations;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

our @EXPORT = qw(
  POST_TRIPLAY_USERS
  PUT_TRIPLAY_USERS
  PATCH_TRIPLAY_USERS
);

our @EXPORT_OK = qw(
  POST_TRIPLAY_USERS
  PUT_TRIPLAY_USERS
  PATCH_TRIPLAY_USERS
);

use constant {
  TRIPLAY_USERS => {
    SERVICE_STATUS => {
      required => 1,
      type     => 'unsigned_integer',
    },
    PERSONAL_TP    => {
      type => 'unsigned_number',
    },
    SERVICE_EXPIRE => {
      type    => 'date',
      default => '0000-00-00'
    },
    COMMENTS       => {
      type => 'string',
    },
  },
};

use constant {
  POST_TRIPLAY_USERS  => {
    %{+TRIPLAY_USERS},
    TP_ID => {
      type     => 'custom',
      function => \&check_tp,
      required => 1
    }
  },
  PATCH_TRIPLAY_USERS => {
    %{+TRIPLAY_USERS},
    SERVICE_STATUS => {
      type => 'unsigned_integer',
    },
  },
  PUT_TRIPLAY_USERS   => {}
};

#**********************************************************
=head2 check_tp($validator, $value)

=cut
#**********************************************************
sub check_tp {
  my ($validator, $value) = @_;
  return {
    errstr => 'Value is not valid',
    type   => 'unsigned_integer',
  } if ($value !~ /^[1-9]\d*$/);

  require Tariffs;
  Tariffs->import();
  my $Tariffs = Tariffs->new($validator->{db}, $validator->{conf}, $validator->{admin});

  $Tariffs->list({
    NEW_MODEL_TP => 1,
    MODULE       => 'Triplay',
    COLS_NAME    => 1,
    STATUS       => '0',
    INNER_TP_ID  => $value || '--',
  });

  if ($Tariffs->{TOTAL} && $Tariffs->{TOTAL} > 0) {
    return {
      result => 1,
    };
  }
  else {
    return {
      result => 0,
      errstr => "No tariff plan with tpId $value",
      type   => 'unsigned_integer',
    };
  }
}

1;
