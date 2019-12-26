#!/usr/bin/perl

# Обязательная проверка телефона, верификация с помощью пина.
# Авторизация с помощью куки или телефона.
# Автоматическая регистрация новых абонентов.

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 scheme_radius_error()

=cut
#**********************************************************
sub scheme_radius_error {
  return 1;
}

#**********************************************************
=head2 scheme_pre_auth()

=cut
#**********************************************************
sub scheme_pre_auth {
  return 1 if check_phone_verify();
  ask_phone();
  ask_pin();
  return 1;
}

#**********************************************************
=head2 scheme_auth()

=cut
#**********************************************************
sub scheme_auth {
  cookie_login();
  phone_login();
  return 1;
}

#**********************************************************
=head2 scheme_registration()

=cut
#**********************************************************
sub scheme_registration {
  hotspot_user_registration({ ANY_MAC => 1 });
  return 1;
}

1;