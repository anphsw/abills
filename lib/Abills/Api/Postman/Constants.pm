package Abills::Api::Postman::Constants;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

use constant {
  VARIABLES => [
    {
      key   => 'API_KEY',
      value => 'testAPI_KEY12',
      type  => 'string'
    },
    {
      key   => 'UID',
      value => '5620',
      type  => 'number',
    },
    {
      key   => 'USERSID',
      value => 'EXAMPLE_SID',
      type  => 'string',
    },
    {
      key   => 'BILLING_URL',
      value => 'https://demo.abills.net.ua:9443/api.cgi',
      type  => 'string'
    },
    {
      key   => 'LOGIN',
      value => 'testuser',
      type  => 'string',
    },
    {
      key   => 'PASSWORD',
      value => 'testuser',
      type  => 'string',
    },
  ]
};

our @EXPORT = qw/
  VARIABLES
/;

1;
