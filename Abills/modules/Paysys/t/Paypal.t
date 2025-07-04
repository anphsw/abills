#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';

use Paysys::t::Init_t;
use Digest::SHA qw(hmac_sha256_hex);
use Paysys::Plugins::Paypal;

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

my $Payment_plugin = Paysys::Plugins::Paypal->new($db, $admin, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);
$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$Paysys->add({
  SYSTEM_ID      => 66,
  SUM            => 1.00,
  UID            => $user_id,
  IP             => '127.0.0.1',
  TRANSACTION_ID => "PayPal:$payment_id",
  INFO           => "Test payment",
  PAYSYS_IP      => "127.0.0.1",
  STATUS         => 1,
});

my $pay_req = qq/{
    "id": "WH-8G3100567M1356841-1NS37236C05148814",
    "event_version": "1.0",
    "create_time": "2025-06-18T14:55:27.671Z",
    "resource_type": "checkout-order",
    "resource_version": "2.0",
    "event_type": "CHECKOUT.ORDER.APPROVED",
    "summary": "An order has been approved by buyer",
    "resource": {
        "create_time": "2025-06-18T14:55:11Z",
        "purchase_units": [
            {
                "reference_id": "default",
                "amount": {
                    "currency_code": "USD",
                    "value": "$payment_sum",
                    "breakdown": {
                        "item_total": {
                            "currency_code": "USD",
                            "value": "$payment_sum"
                        }
                    }
                },
                "payee": {
                    "email_address": "sb-qgf3g14302874\@business.example.com",
                    "merchant_id": "99SBX4QU2U33C"
                },
                "invoice_id": "$payment_id",
                "items": [
                    {
                        "name": "Internet services",
                        "unit_amount": {
                            "currency_code": "USD",
                            "value": "$payment_sum"
                        },
                        "quantity": "1",
                        "description": "Username:  UID: 120619"
                    }
                ],
                "shipping": {
                    "name": {
                        "full_name": "John Doe"
                    },
                    "address": {
                        "address_line_1": "1 Main St",
                        "admin_area_2": "San Jose",
                        "admin_area_1": "CA",
                        "postal_code": "95131",
                        "country_code": "US"
                    }
                }
            }
        ],
        "links": [
            {
                "href": "https:\/\/api.sandbox.paypal.com\/v2\/checkout\/orders\/2G870242343691539",
                "rel": "self",
                "method": "GET"
            },
            {
                "href": "https:\/\/api.sandbox.paypal.com\/v2\/checkout\/orders\/2G870242343691539",
                "rel": "update",
                "method": "PATCH"
            },
            {
                "href": "https:\/\/api.sandbox.paypal.com\/v2\/checkout\/orders\/2G870242343691539\/capture",
                "rel": "capture",
                "method": "POST"
            }
        ],
        "id": "2G870242343691539",
        "payment_source": {
            "paypal": {
                "email_address": "sb-y3xgh14302873\@personal.example.com",
                "account_id": "SPXM833W3N292",
                "account_status": "VERIFIED",
                "name": {
                    "given_name": "John",
                    "surname": "Doe"
                },
                "address": {
                    "country_code": "US"
                }
            }
        },
        "intent": "CAPTURE",
        "payer": {
            "name": {
                "given_name": "John",
                "surname": "Doe"
            },
            "email_address": "sb-y3xgh14302873\@personal.example.com",
            "payer_id": "SPXM833W3N292",
            "address": {
                "country_code": "US"
            }
        },
        "status": "APPROVED"
    },
    "links": [
        {
            "href": "https:\/\/api.sandbox.paypal.com\/v1\/notifications\/webhooks-events\/WH-8G3100567M1356841-1NS37236C05148814",
            "rel": "self",
            "method": "GET"
        },
        {
            "href": "https:\/\/api.sandbox.paypal.com\/v1\/notifications\/webhooks-events\/WH-8G3100567M1356841-1NS37236C05148814\/resend",
            "rel": "resend",
            "method": "POST"
        }
    ]
}/;

our @requests = (
  {
    name    => 'PAY',
    request => $pay_req,
    headers   => [
      'Content-Type: application/json',
    ],
    result  => q{}
  },
);

test_runner($Payment_plugin, \@requests);

1;
