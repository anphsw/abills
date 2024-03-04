#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use lib '../../../../../';
use lib '../../../../../lib/';

use Test::More;

use_ok('Abills::Base');
use_ok('Abills::Api::Postman::Api');

use Abills::Base qw(_bp);

#define conf
our %conf;
require 'libexec/config.pl';

check_conf();

my $Postman = new_ok('Abills::Api::Postman::Api' => [ { conf => \%conf } ]);

can_ok($Postman, 'make_request');
can_ok($Postman, 'collection_info');

# get valid collections
get_valid_collection($conf{POSTMAN_USER_COLLECTION_ID}, 'user');
get_valid_collection($conf{POSTMAN_ADMIN_COLLECTION_ID}, 'admin');

# get not valid collections
my $invalid_collection = $Postman->collection_info({ collection_id => 'd25b0b66-2de2-4ca3-8dd4-3d3da679ab61' });
ok(ref $invalid_collection eq 'HASH' && $invalid_collection->{error}, 'Response valid. Request with not exists collection.');

done_testing();

sub check_conf {
  my @params = ('POSTMAN_API_KEY', 'POSTMAN_USER_COLLECTION_ID', 'POSTMAN_ADMIN_COLLECTION_ID');

  foreach my $param (@params) {
    ok($conf{$param}, "Conf parameter $param defined");
  }
}

sub get_valid_collection {
  my ($id, $name) = @_;
  my $user_collection = $Postman->collection_info({ collection_id => $id });

  ok(ref $user_collection eq 'HASH', "Response received about $name collection");
  my $check_result = ok(!$user_collection->{error}, 'User collection valid');
  if (!$check_result) {
    diag("Error happened during receiving info about $name collection");
    diag("Error - $user_collection->{error}->{name}. Error message - $user_collection->{error}->{message}");
  }
}

1;
