package Crm::Errors;

=head1 NAME

  Crm::Errors - returns errors of module Crm

=cut


use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1230001 => 'ERR_CRM_PHONE_NOT_FOUND',
    1230002 => 'ERR_CRM_EXTERNAL_CMD_NOT_FOUND',
    1230003 => 'ERR_CRM_EXTERNAL_CMD_ERROR',
    1230004 => 'ERR_CRM_BOT_USER_ID_ERROR',
    1230005 => 'ERR_CRM_MESSAGE_SOURCE_ERROR',
    1230006 => 'ERR_CRM_GET_LEAD_BY_BOT_ERROR',
    1230007 => 'ERR_CRM_LEAD_NOT_FOUND',
    1230008 => 'ERR_CRM_SEND_DIALOGUE_MESSAGE_ERROR',
    1230009 => 'ERR_CRM_NUMBER_NOT_FOUND',
    1230010 => 'ERR_CRM_NUMBER_ALREADY_ACTIVATED',
    1230011 => 'ERR_CRM_NUMBER_ALREADY_DEACTIVATED',
    1230012 => 'ERR_CRM_EXTERNAL_API_ERROR',
    1230013 => 'ERR_CRM_NO_FIELD',
    1230014 => 'ERR_CRM_UNKNOWN_MESSENGER_TYPE',
    1230015 => 'ERR_CRM_API_TIMEOUT',
    1230016 => 'ERR_CRM_INVALID_JSON_RESPONSE',
    1230017 => 'ERR_CRM_INVALID_RESPONSE_STRUCTURE',
  };
}

1;
