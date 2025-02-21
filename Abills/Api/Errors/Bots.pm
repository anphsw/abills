package Api::Errors::Bots;
use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1770001 => 'ERR_UNKNOWN_VIBER_BOT',
    1770002 => 'ERR_UNKNOWN_TELEGRAM_BOT',
    1770003 => 'ERR_UNKNOWN_BOT_NAME',
    1770004 => 'ERR_NO_FIELD',
    1770005 => 'ERR_INVALID_FIELD_TOKEN',
    1770006 => 'ERR_UNKNOWN_TOKEN',
    1770007 => 'ERR_UNKNOWN_BOT_TYPE',
    1770008 => 'ERR_UNKNOWN_TOKEN',
    1770009 => 'ERR_UNKNOWN_PHONE',
    1770010 => 'ERR_NO_FIELD',
  };
}

1;
