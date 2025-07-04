package Internet::Errors;

=head1 NAME

  Internet::Errors - returns errors of module Internet

=cut


use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1360001 => 'ERR_NO_FIELD', # uid
    1360002 => 'ERR_NO_FIELD', # id
    1360003 => 'ERR_NO_FIELD', # tpId
    1360004 => 'ERR_ACCESS_DENY',
    1360005 => 'ERR_ACCESS_DENY',
    1360006 => 'USER_NOT_EXIST',
    1360007 => 'USER_NOT_EXIST',
    1360007 => 'USER_NOT_EXIST',
    1360008 => 'ERR_TARIFF_EXISTS',
    1360009 => 'ERR_NO_FIELD', # date
    1360010 => 'ERR_WRONG_DATE',
    1360011 => 'ERR_WRONG_DATE',
    1360012 => 'ERR_WRONG_DATE',
    1360013 => 'ERR_FAILED_SET_SCHEDULE',
    1360014 => 'ERR_CHANGE_TP',
    1360015 => 'ERR_NO_TARIFF',
    1360016 => 'ERR_NO_FREE_IP_IN_POOL',
    1360017 => 'ERR_IP_POOLS',
    1360018 => 'ERR_IP_EXISTS',
    1360019 => 'ERR_UID_TOO_HIGH_FOR_IPV6',
    1360020 => 'ERR_CID_EXIST',
    1360021 => 'ERR_VLAN_EXIST',
    1360022 => 'ERR_NAS_AND_PORT_ALREADY_USE',
    1360023 => 'ERR_NO_WRONG_PORT_SELECTED',
    1360024 => 'ERR_CPE_EXIST',
    1360025 => 'ERR_SELECT_TP',
    1360026 => 'ERR_WRONG_CONFIRM',
    1360027 => 'ERR_SHORT_PASSWD',
    1360028 => 'ERR_EXTERNAL_CMD',
    1360030 => 'ERR_UID_SERVICE_NOT_EXISTS'
  };
}

1;
