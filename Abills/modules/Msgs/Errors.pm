package Msgs::Errors;

=head1 NAME

  Msgs::Errors - returns errors of module Msgs

=cut


use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    # user api
    1070001 => 'ERR_MESSAGE_SECONDS_LIMIT',
    1070002 => 'ERR_MESSAGE_SECONDS_LIMIT',
    1070003 => 'ERR_NO_ATTACHMENT',
    1070004 => 'ERR_READ_ATTACHMENT',
    1070005 => 'ERR_NO_ATTACHMENT',
    1070006 => 'ERR_SAVE_FILE',

    #admin api
    1071001 => 'ERR_NO_PERMISSION_ADD_MESSAGE',
    1071002 => 'ERR_NO_PERMISSION_TO_CHAPTER',
    1071003 => 'ERR_NO_PERMISSION_ADD_MESSAGE',
    1071004 => 'ERR_NO_MESSAGE_ACCESS',
    1071005 => 'ERR_NO_MESSAGE_ACCESS',
    1071006 => 'ERR_NO_MESSAGE_ACCESS',
    1071007 => 'ERR_NO_PERMISSION_TO_CHAPTER',
    1071008 => 'ERR_NO_PERMISSION_TO_CHAPTER',
  };
}

1;
