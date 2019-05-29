#!/usr/bin/perl -w

=head1 NAME

 Paysys tests

=cut

use strict;
use warnings;
use Test::More tests => 16;
use Data::Dumper;


our (%FORM, %LIST_PARAMS, %functions, %conf, $html, %lang, @_COLORS, $DATE, $TIME);

BEGIN {
  our $libpath = '../../../../';
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
  unshift(@INC, $libpath . "Abills/mysql/");
}

use Abills::Init qw/$db $admin $users/;
use Paysys;

require "libexec/config.pl";
$conf{language} = 'english';
do "language/$conf{language}.pl";
do "/usr/abills/Abills/modules/Paysys/lng_$conf{language}.pl";

if (scalar @ARGV == 0) {
  print " help - man\n\n NAME= - enter pay_system name or default(IBOX)\n\n ID= - enter pay_system id or default\n\n URL= - enter IP:PORT for web_requests or default(127.0.0.1:9443)\n\n";
  exit;
}

if ($ARGV[0] eq 'help') {
  print " help - man\n\n NAME= - enter pay_system name or default(IBOX)\n\n ID= - enter pay_system id or default\n\n URL= - enter IP:PORT for web_requests or default(127.0.0.1:9443)\n\n";
  exit;
}

my $begin_time = Abills::Base::check_time();

use_ok('Paysys');
use_ok('Paysys::systems::USMP');
use_ok('Conf');
use_ok('Abills::Fetcher', qw/web_request/);
use_ok('Abills::Base', qw/mk_unique_value parse_arguments/);
use_ok('XML::Simple');

my $Conf = Conf->new($db, $admin, \%conf);
my $attr = parse_arguments(\@ARGV);
my $url = $attr->{URL} || '127.0.0.1:9443';
my $user_id = $attr->{USER} || '1';

my $random_number = int(rand(1000));

my $USMP = Paysys::systems::USMP->new($db, $admin, \%conf, {
  CUSTOM_NAME => $attr->{NAME} || '',
  CUSTOM_ID   => $attr->{ID} || '',
});

# checking function check with valid account
my $result = $USMP->proccess(
  {
    Account       => "$user_id",
    QueryType     => 'check',
    TransactionId => "$random_number",
    test          => 1,
  }
);
my $res = '';
($res) = ($result =~ /\<ResultCode\>(\d+)\<\/ResultCode\>/g);
ok($res eq '0', 'User Exist(function check)');

# checking function check with invalid account
$result = $USMP->proccess(
  {
    Account       => '1232124',
    QueryType     => 'check',
    TransactionId => "$random_number",
    test          => 1,
  }
);
$res = '';
($res) = ($result =~ /\<ResultCode\>(\d+)\<\/ResultCode\>/g);
ok($res eq '21', 'User not Exist(function check)');

# checking function pay with valid account
$result = $USMP->proccess(
  {
    Account       => "$user_id",
    QueryType     => 'pay',
    TransactionId => "$random_number",
    Amount        => '1.00',
    test          => 1,
  }
);
$res = '';
my $tr_id1 = '';
($res) = ($result =~ /\<ResultCode\>(\d+)\<\/ResultCode\>/g);
($tr_id1) = ($result =~ /\<TransactionId\>(\d+)\<\/TransactionId\>/g);
ok($res eq '0', "Payment completed(function pay).TransactionId:$tr_id1");

# checking function pay with invalid account
$result = $USMP->proccess(
  {
    Account       => "1234321",
    QueryType     => 'pay',
    TransactionId => "$random_number",
    Amount        => '1.00',
    test          => 1,
  }
);
$res = '';
($res) = ($result =~ /\<ResultCode\>(\d+)\<\/ResultCode\>/g);
ok($res eq '1', "Not exist user(function pay)checking with not existed account");

# checking function pay with valid account
$result = $USMP->proccess(
  {
    Account       => "$user_id",
    QueryType     => 'pay',
    TransactionId => "$random_number",
    test          => 1,
  }
);
$res = '';
($res) = ($result =~ /\<ResultCode\>(\d+)\<\/ResultCode\>/g);
ok($res eq '12', "There isn't attr Ammount (function pay)");

# checking function pay with valid account again
$result = $USMP->proccess(
  {
    Account       => "$user_id",
    QueryType     => 'pay',
    TransactionId => "$random_number",
    Amount        => '1.00',
    test          => 1,
  }
);
$res = '';
my $tr_id2 = '';
($res) = ($result =~ /\<ResultCode\>(\d+)\<\/ResultCode\>/g);
($tr_id2) = ($result =~ /\<TransactionId\>(\d+)\<\/TransactionId\>/g);
ok($tr_id1 && $tr_id2 && "$tr_id1" eq "$tr_id2", "Payment exist (function pay) checking with same Transaction");

# checking function cancel
if ($tr_id1 && $tr_id1 != 0) {
  $result = $USMP->proccess(
    {
      Account       => "$user_id",
      QueryType     => 'cancel',
      TransactionId => "$tr_id1",
      RevertId      => "$tr_id1",
      RevertDate    => "20190515210510",
      Amount        => '1.00',
      test          => 1,
    }
  );
  $res = '';
  ($res) = ($result =~ /\<ResultCode\>(\d+)\<\/ResultCode\>/g);
  ok($res eq '0', 'Transaction was canceled(function cancel)');
}


#Web test
print "________________\nWeb test\n\n";
#Web test check
$result = Abills::Fetcher::web_request("https://$url/paysys_check.cgi?QueryType=check&TransactionId=$random_number&Account=$user_id", {
  INSECURE => 1,
});
my $req_xml_check = XML::Simple::XMLin($result, ForceArray => 0, KeyAttr => 1);
ok(defined($req_xml_check->{ResultCode}) && $req_xml_check->{ResultCode} == 0, "Function check - ok, User exist.");
#Web test pay
my $transaction = int(rand(10000));
$result = Abills::Fetcher::web_request("https://$url/paysys_check.cgi?QueryType=pay&TransactionId=$transaction&TransactionDate=20190515210510&Account=$user_id&Amount=1.00", {
  INSECURE => 1,
});
my $req_xml_pay = XML::Simple::XMLin($result, ForceArray => 0, KeyAttr => 1);
ok(defined($req_xml_pay->{ResultCode}) && $req_xml_pay->{ResultCode} == 0, "Function pay - ok, Payment is maked for Payment_id:"
  . $req_xml_pay->{TransactionId} || '' . ".");

#Web pay for cancel
my $tr_for_cancel = int(rand(10000));
my $response = Abills::Fetcher::web_request("https://$url/paysys_check.cgi?QueryType=pay&TransactionId=$tr_for_cancel&TransactionDate=20190515210510&Account=$user_id&Amount=1.00", {
  INSECURE => 1,
});
my $req_xml_pyament_id = XML::Simple::XMLin($response, ForceArray => 0, KeyAttr => 1);
#Web cancel check
$result = Abills::Fetcher::web_request("https://$url/paysys_check.cgi?QueryType=cancel&TransactionId=$req_xml_pyament_id->{TransactionId}
  . &RevertId=$req_xml_pyament_id->{TransactionId}&RevertDate=20190515210510&Account=$user_id&Amount=1.00", {
  INSECURE => 1,
});
my $req_xml_cancel = XML::Simple::XMLin($result, ForceArray => 0, KeyAttr => 1);
ok(defined($req_xml_cancel->{ResultCode}) && $req_xml_cancel->{ResultCode} == 0, "Function cancel - ok, Payment is canceled for Payment_id:"
  . $req_xml_pyament_id->{TransactionId} || '' . ".");



print "\nTest time: " . Abills::Base::gen_time($begin_time) . "\n\n";