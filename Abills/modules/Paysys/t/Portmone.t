#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';

use Abills::Base qw(is_number);
use Paysys::t::Init_t;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id,
  $argv
);

my $Payment_plugin;
if (!$conf{PAYSYS_V4}) {
  require Paysys::systems::Portmone;
  $Payment_plugin = Paysys::systems::Portmone->new($db, $admin, \%conf);
}
else {
  require Paysys::Plugins::Portmone;
  $Payment_plugin = Paysys::Plugins::Portmone->new($db, $admin, \%conf);
}
$payment_id = int(rand(10000));
my $payee_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_PORTMONE_PAYEE_ID} || '';
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $user_id_2 = is_number($user_id) ? $user_id + 1 : $user_id;
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

our @requests = (
  {
    name    => 'PAY',
    request => qq{
data=<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<BILLS>
    <BILL>
        <BANK>
            <NAME>ГУ Ощадбанку м.Київ</NAME>
            <CODE>399999</CODE>
            <ACCOUNT>UA383226690000029243832900000</ACCOUNT>
        </BANK>
        <BILL_ID>966666666</BILL_ID>
        <BILL_NUMBER>$payment_id</BILL_NUMBER>
        <BILL_DATE>2021-07-14</BILL_DATE>
        <BILL_PERIOD>0721</BILL_PERIOD>
        <PAY_DATE>2021-07-14</PAY_DATE>
        <PAYED_AMOUNT>$payment_sum</PAYED_AMOUNT>
        <PAYED_COMMISSION>0.00</PAYED_COMMISSION>
        <PAYED_DEBT>0.00</PAYED_DEBT>
        <AUTH_CODE>TESTPM</AUTH_CODE>
        <PAYER>
            <CONTRACT_NUMBER>$user_id</CONTRACT_NUMBER>
        </PAYER>
        <PAYEE>
            <NAME>COMPANY_NAME</NAME>
            <CODE>30098</CODE>
        </PAYEE>
        <STATUS>PAYED</STATUS>
        <PAY_TIME>16:25:14</PAY_TIME>
        <CARD_MASK>444433******0000</CARD_MASK>
    </BILL>
</BILLS>
},
    result  => q{}
  },
  {
    name    => 'CHECK',
    request => qq{
data=<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<REQUESTS>
    <PAYEE>$payee_id</PAYEE>
    <PAYER>
        <CONTRACT_NUMBER>$user_id</CONTRACT_NUMBER>
        <AMOUNT>10</AMOUNT>
    </PAYER>
</REQUESTS>
},
    result  => q{}
  },
  {
    name    => 'MULTIPLE_CHECK',
    request => qq{
data=<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<REQUESTS>
    <PAYEE>$payee_id</PAYEE>
    <PAYER>
        <CONTRACT_NUMBER>$user_id</CONTRACT_NUMBER>
    </PAYER>
    <PAYER>
       <CONTRACT_NUMBER>$user_id_2</CONTRACT_NUMBER>
    </PAYER>
    <PAYER>
       <CONTRACT_NUMBER>12345678912</CONTRACT_NUMBER>
    </PAYER>
</REQUESTS>
},
    result  => q{}
  },
  {
    name    => 'PAY_ORDERS',
    request => qq{
data=<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<PAY_ORDERS>
    <PAY_ORDER>
        <PAY_ORDER_ID>12345</PAY_ORDER_ID>
        <PAY_ORDER_DATE>2024-08-09</PAY_ORDER_DATE>
        <PAY_ORDER_NUMBER>1234</PAY_ORDER_NUMBER>
        <PAY_ORDER_AMOUNT>5</PAY_ORDER_AMOUNT>
        <PAYEE>
            <NAME>FaineNet</NAME>
            <CODE>123455</CODE>
        </PAYEE>
        <BANK>
            <NAME>James Bank</NAME>
            <CODE>305299</CODE>
            <ACCOUNT>UA111152990000011111737536299</ACCOUNT>
        </BANK>
        <BILLS>
           <BILL>
               <BANK>
                   <NAME>ГУ Ощадбанку м.Київ</NAME>
                   <CODE>399999</CODE>
                   <ACCOUNT>UA383226690000029243832900000</ACCOUNT>
               </BANK>
               <BILL_ID>966666666</BILL_ID>
               <BILL_NUMBER>123$payment_id</BILL_NUMBER>
               <BILL_DATE>2021-07-14</BILL_DATE>
               <BILL_PERIOD>0721</BILL_PERIOD>
               <PAY_DATE>2021-07-14</PAY_DATE>
               <PAYED_AMOUNT>3</PAYED_AMOUNT>
               <PAYED_COMMISSION>0.00</PAYED_COMMISSION>
               <PAYED_DEBT>0.00</PAYED_DEBT>
               <AUTH_CODE>TESTPM</AUTH_CODE>
               <PAYER>
                   <CONTRACT_NUMBER>$user_id</CONTRACT_NUMBER>
               </PAYER>
               <PAYEE>
                   <NAME>COMPANY_NAME</NAME>
                   <CODE>30098</CODE>
               </PAYEE>
               <STATUS>PAYED</STATUS>
               <PAY_TIME>16:25:14</PAY_TIME>
               <CARD_MASK>444433******0000</CARD_MASK>
          </BILL>
          <BILL>
               <BANK>
                   <NAME>ГУ Ощадбанку м.Київ</NAME>
                   <CODE>399999</CODE>
                   <ACCOUNT>UA383226690000029243832900000</ACCOUNT>
               </BANK>
               <BILL_ID>966666666</BILL_ID>
               <BILL_NUMBER>321$payment_id</BILL_NUMBER>
               <BILL_DATE>2021-07-14</BILL_DATE>
               <BILL_PERIOD>0721</BILL_PERIOD>
               <PAY_DATE>2021-07-14</PAY_DATE>
               <PAYED_AMOUNT>2</PAYED_AMOUNT>
               <PAYED_COMMISSION>0.00</PAYED_COMMISSION>
               <PAYED_DEBT>0.00</PAYED_DEBT>
               <AUTH_CODE>TESTPM</AUTH_CODE>
               <PAYER>
                   <CONTRACT_NUMBER>$user_id</CONTRACT_NUMBER>
               </PAYER>
               <PAYEE>
                   <NAME>COMPANY_NAME</NAME>
                   <CODE>30098</CODE>
               </PAYEE>
               <STATUS>PAYED</STATUS>
               <PAY_TIME>16:25:14</PAY_TIME>
               <CARD_MASK>444433******0000</CARD_MASK>
          </BILL>
        </BILLS>
    </PAY_ORDER>
</PAY_ORDERS>
},
    result  => q{}
  },
  {
    name    => 'CANCEL',
    request => qq{
data=<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<BILLS>
    <BILL>
        <BANK>
            <NAME>ГУ Ощадбанку м.Київ</NAME>
            <CODE>399999</CODE>
            <ACCOUNT>UA383226690000029243832900000</ACCOUNT>
        </BANK>
        <BILL_ID>966666666</BILL_ID>
        <BILL_NUMBER>$payment_id</BILL_NUMBER>
        <BILL_DATE>2021-07-14</BILL_DATE>
        <BILL_PERIOD>0721</BILL_PERIOD>
        <PAY_DATE>2021-07-14</PAY_DATE>
        <PAYED_AMOUNT>-$payment_sum</PAYED_AMOUNT>
        <PAYED_COMMISSION>0.00</PAYED_COMMISSION>
        <PAYED_DEBT>0.00</PAYED_DEBT>
        <AUTH_CODE>TESTPM</AUTH_CODE>
        <PAYER>
            <CONTRACT_NUMBER>$user_id</CONTRACT_NUMBER>
        </PAYER>
        <PAYEE>
            <NAME>COMPANY_NAME</NAME>
            <CODE>30098</CODE>
        </PAYEE>
        <STATUS>PAYED</STATUS>
        <PAY_TIME>16:25:14</PAY_TIME>
        <CARD_MASK>444433******0000</CARD_MASK>
    </BILL>
</BILLS>
},
    result  => q{}
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

