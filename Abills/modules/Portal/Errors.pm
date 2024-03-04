package Portal::Errors;

=head1 NAME

  Portal::Errors - returns errors of module Portal

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1440001 => 'ERR_PORTAL_NO_SENDER',
    1440002 => 'ERR_PORTAL_NO_ARTICLE',
    1440003 => 'ERR_PORTAL_NEWSLETTER_ALREADY_EXIST',
    1440004 => 'ERR_PORTAL_NEWSLETTER_NOT_EXIST',
    1440005 => 'ERR_PORTAL_NEWSLETTER_DENY_DELETE_ACTIVE',
    1440006 => 'ERR_PORTAL_ATTACHMENT_FAILED_TO_SAVE',
    1440007 => 'ERR_PORTAL_ATTACHMENT_NO_FILES',
    1440008 => 'ERR_PORTAL_MENUS_HAVE_ARTICLES'
  };
}

1;
