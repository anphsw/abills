#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';

use Paysys::t::Init_t;
use Digest::SHA qw(hmac_sha256_hex);
use Paysys::Plugins::Stripe;

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

my $Payment_plugin = Paysys::Plugins::Stripe->new($db, $admin, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);
$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$Paysys->add({
  SYSTEM_ID      => 102,
  SUM            => 1.00,
  UID            => $user_id,
  IP             => '127.0.0.1',
  TRANSACTION_ID => "ST:$payment_id",
  INFO           => "Test payment",
  PAYSYS_IP      => "127.0.0.1",
  STATUS         => 1,
});

my $pay_req = qq/{
  "id": "evt_1RX6ZnKlSHFnTMxQ9Wbv3I7m",
  "object": "event",
  "api_version": "2020-08-27",
  "created": 1749240559,
  "data": {
    "object": {
      "id": "cs_test_a18Y7Sx75RE9nX3LdLQf17lEGn4Gs9sVqPyamZ1Obl8MU0AzWM6lMLa7rU",
      "object": "checkout.session",
      "adaptive_pricing": {
        "enabled": true
      },
      "after_expiration": null,
      "allow_promotion_codes": null,
      "amount_subtotal": 1000,
      "amount_total": 1000,
      "automatic_tax": {
        "enabled": false,
        "liability": null,
        "provider": null,
        "status": null
      },
      "billing_address_collection": null,
      "cancel_url": "https:\/\/8a2e-213-109-233-168.ngrok-free.app\/",
      "client_reference_id": null,
      "client_secret": null,
      "collected_information": {
        "shipping_details": null
      },
      "consent": null,
      "consent_collection": null,
      "created": 1749240529,
      "currency": "usd",
      "currency_conversion": null,
      "custom_fields": [

      ],
      "custom_text": {
        "after_submit": null,
        "shipping_address": null,
        "submit": null,
        "terms_of_service_acceptance": null
      },
      "customer": "cus_SS0avxmnx9mIKO",
      "customer_creation": "always",
      "customer_details": {
        "address": {
          "city": null,
          "country": "UA",
          "line1": null,
          "line2": null,
          "postal_code": null,
          "state": null
        },
        "email": "test\@gmail.com",
        "name": "test user",
        "phone": null,
        "tax_exempt": "none",
        "tax_ids": [

        ]
      },
      "customer_email": null,
      "discounts": [

      ],
      "expires_at": 1749326929,
      "invoice": null,
      "invoice_creation": {
        "enabled": false,
        "invoice_data": {
          "account_tax_ids": null,
          "custom_fields": null,
          "description": null,
          "footer": null,
          "issuer": null,
          "metadata": {
          },
          "rendering_options": null
        }
      },
      "livemode": false,
      "locale": null,
      "metadata": {
        "uid": "$user_id",
        "operation_id": "$payment_id"
      },
      "mode": "payment",
      "payment_intent": "pi_3RX6ZJKlSHFnTMxQ1mTEU3cI",
      "payment_link": null,
      "payment_method_collection": "always",
      "payment_method_configuration_details": {
        "id": "pmc_1MY8gDKlSHFnTMxQbX4LbEe9",
        "parent": null
      },
      "payment_method_options": {
        "card": {
          "request_three_d_secure": "automatic"
        }
      },
      "payment_method_types": [
        "card"
      ],
      "payment_status": "paid",
      "permissions": null,
      "phone_number_collection": {
        "enabled": false
      },
      "presentment_details": {
        "presentment_amount": 42973,
        "presentment_currency": "uah"
      },
      "recovered_from": null,
      "saved_payment_method_options": {
        "allow_redisplay_filters": [
          "always"
        ],
        "payment_method_remove": "disabled",
        "payment_method_save": null
      },
      "setup_intent": null,
      "shipping": null,
      "shipping_address_collection": null,
      "shipping_options": [

      ],
      "shipping_rate": null,
      "status": "complete",
      "submit_type": null,
      "subscription": null,
      "success_url": "https:\/\/8a2e-213-109-233-168.ngrok-free.app\/",
      "total_details": {
        "amount_discount": 0,
        "amount_shipping": 0,
        "amount_tax": 0
      },
      "ui_mode": "hosted",
      "url": null,
      "wallet_options": null
    }
  },
  "livemode": false,
  "pending_webhooks": 3,
  "request": {
    "id": null,
    "idempotency_key": null
  },
  "type": "checkout.session.completed"
}/;

$pay_req  =~ s/[\s\n\r]//gm;

my $t = '1749240559';
my $signed_payload = "$t.$pay_req";

my $sign = hmac_sha256_hex($signed_payload, ($conf{PAYSYS_STRIPE_WEBHOOK_SECRET} || ''));

our @requests = (
  {
    name    => 'PAY',
    request => $pay_req,
    headers   => [
      'Content-Type: application/json',
      "Stripe-Signature: t=$t,v1=$sign,v0=0dcdd1099e2ff4b9cbecb23ec5518a0c58ce0c49c6c4f33123198bdf2c7def8d",
    ],
    result  => q{}
  },
);

test_runner($Payment_plugin, \@requests);

1;
