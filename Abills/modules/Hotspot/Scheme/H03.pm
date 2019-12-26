#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 scheme_radius_error()

=cut
#**********************************************************
sub scheme_radius_error {
  my ($uid) = @_;
  trial_tp_change($uid);
  user_portal_redirect();
  return 1;
}

#**********************************************************
=head2 scheme_pre_auth()

=cut
#**********************************************************
sub scheme_pre_auth {
  return 1;
}

#**********************************************************
=head2 scheme_auth()

=cut
#**********************************************************
sub scheme_auth {
  mac_login();
  return 1;
}

#**********************************************************
=head2 scheme_registration()

=cut
#**********************************************************
sub scheme_registration {
  hotspot_user_registration();
  return 1;
}

1;