#!/usr/bin/perl -w
=head1 NAME

 Paysys tests

=cut
use strict;
use warnings;
use Test::More;
use Data::Dumper;

our (
  %FORM,
  %LIST_PARAMS,
  %functions,
  %conf,
  $html,
  %lang,
  @_COLORS,
);

BEGIN {
  our $Bin;
  use FindBin '$Bin';
  if ($Bin =~ m/\/abills(\/)/) {
    my $libpath = substr($Bin, 0, $-[1]);
    unshift (@INC, "$libpath/lib");
  }
  else {
    die " Should be inside /usr/abills dir \n";
  }
}

use Abills::Init qw/$db $admin $users/;

require "libexec/config.pl";
$conf{language} = 'english';
do "language/$conf{language}.pl";
do "/usr/abills/Abills/modules/Paysys/lng_$conf{language}.pl";
use_ok('Paysys');
use_ok('Paysys::systems::Osmp');
use_ok('Conf');
use_ok('Abills::Base', qw/mk_unique_value /);
new_ok("Conf", [ $db, $admin, \%conf ]);
new_ok("Paysys::systems::Osmp", [ $db, $admin, \%conf ]);

my $txn_id  = Abills::Base::mk_unique_value(8, { SYMBOLS => '1234567890' });
my $user_id = $ARGV[0] || 1;
my $prv_txn = '';

subtest 'check user' => sub {
    my $Osmp = Paysys::systems::Osmp->new($db, $admin, \%conf);

    my $result = $Osmp->check({
      account => $user_id,
      action  => 'check',
      sum     => 1.00,
      txn_id  => $txn_id,
      prv_txn => $prv_txn,
    });
    ok(ref $result eq 'HASH' && $result->{result} == 0, 'User found');

    my $result2 = $Osmp->check({
      account => 'user_12345678',
      action  => 'check',
      sum     => 1.00,
      txn_id  => $txn_id,
      prv_txn => $prv_txn,
    });
    ok(ref $result2 eq 'HASH' && $result2->{result} == 5, 'User not found');
  };

subtest 'success pay' => sub {
    my $Osmp = Paysys::systems::Osmp->new($db, $admin, \%conf);
    my $result = $Osmp->pay({
      account => $user_id,
      action  => 'pay',
      sum     => 1.00,
      txn_id  => $txn_id,
      prv_txn => 1,
    });

    ok(ref $result eq 'HASH' && $result->{result} == 0, 'Success pay');
  };

subtest 'cancel pay' => sub {
    my $Osmp = Paysys::systems::Osmp->new($db, $admin, \%conf);
    my $cancel_txn_id  = Abills::Base::mk_unique_value(8, { SYMBOLS => '1234567890' });

    my $pay_result = $Osmp->pay({
      account => $user_id,
      action  => 'pay',
      sum     => 1.00,
      txn_id  => $cancel_txn_id,
      prv_txn => 1,
    });

    ok(ref $pay_result eq 'HASH' && $pay_result->{result} == 0, 'Success pay before cancel');

    $prv_txn = $pay_result->{prv_txn};

    my $result = $Osmp->cancel({
      account => $user_id,
      action  => 'cancel',
      sum     => 1.00,
      txn_id  => $cancel_txn_id,
      prv_txn => $prv_txn,
    });

    ok(ref $result eq 'HASH' && $result->{result} == 0, 'Success cancel');
  };

done_testing;