package Docs::Validations;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

our @EXPORT = qw(
  POST_INVOICE_ADD
  POST_DOCS_INVOICES_PAYMENTS
  DELETE_DOCS_INVOICES_PAYMENTS
  PATCH_DOCS_INVOICES_PAYMENTS
  POST_USER_DOCS_INVOICES
);

our @EXPORT_OK = qw(
  POST_INVOICE_ADD
  POST_DOCS_INVOICES_PAYMENTS
  DELETE_DOCS_INVOICES_PAYMENTS
  PATCH_DOCS_INVOICES_PAYMENTS
  POST_USER_DOCS_INVOICES
);

use constant {
  INVOICE_OBJ => {
    SUM       => {
      required => 1,
      type     => 'unsigned_number',
    },
    ORDER     => {
      type => 'string'
    },
    FEES_TYPE => {
      # probably add custom validation on fees types
      type => 'unsigned_integer'
    },
    COUNT     => {
      type => 'unsigned_integer'
    },
    UNIT      => {
      type => 'unsigned_integer'
    },
  },
};

use constant {
  POST_DOCS_INVOICES_PAYMENTS   => {
    IDS            => {
      required => 1,
      type     => 'string',
    },
    PAYMENT_METHOD => {
      type => 'unsigned_integer',
    }
  },
  PATCH_DOCS_INVOICES_PAYMENTS  => {
    SUM            => {
      required => 1,
      type     => 'unsigned_number',
    },
    PAYMENT_ID     => {
      required => 1,
      type     => 'unsigned_integer',
    },
    INVOICE_CREATE => {
      type => 'unsigned_integer',
    },
    INVOICE_ID     => {
      type => 'unsigned_integer',
    },
  },
  DELETE_DOCS_INVOICES_PAYMENTS => {
    IDS => {
      type => 'string',
    },
    ID  => {
      type => 'unsigned_integer',
    },
  },
  POST_USER_DOCS_INVOICES       => {
    NEXT_PERIOD     => {
      type => 'unsigned_integer',
    },
    CUSTOMER        => {
      type => 'string',
    },
    ORDER           => {
      type => 'string',
    },
    ORDER2          => {
      type => 'string',
    },
    PHONE           => {
      type => 'string',
    },
    SUM             => {
      type => 'unsigned_number',
    },
    IDS             => {
      type => 'string'
    },
    ORDERS_AS_ARRAY => {
      type => 'number',
    }
  },
  POST_INVOICE_ADD              => {
    UID                        => {
      type     => 'unsigned_integer',
      required => 1
    },
    CUSTOMER                   => {
      type => 'string',
    },
    CURRENCY                   => {
      type => 'unsigned_integer',
    },
    INCLUDE_DEPOSIT            => {
      type => 'unsigned_integer',
    },
    INCLUDE_CUR_BILLING_PERIOD => {
      type => 'unsigned_integer',
    },

    # new type
    ORDERS                     => {
      type  => 'array',
      items => {
        type       => 'object',
        properties => INVOICE_OBJ
      }
    },

    SUM                        => {
      type => 'unsigned_number',
    },
    ORDER                      => {
      type => 'string'
    },
    FEES_TYPE                  => {
      # probably add custom validation on fees types
      type => 'unsigned_integer'
    },
    COUNT                      => {
      type => 'unsigned_integer'
    },
    UNIT                       => {
      type => 'unsigned_integer'
    },

    # old type
    _PATTERN_PROPERTIES        => {
      "SUM_\\d+\$"       => {
        type => 'unsigned_number',
      },
      "ORDER_\\d+\$"     => {
        type => 'string'
      },
      "FEES_TYPE_\\d+\$" => {
        # probably add custom validation on fees types
        type => 'unsigned_integer'
      },
      "COUNT_\\d+\$"     => {
        type => 'unsigned_integer'
      },
      "UNIT_\\d+\$"      => {
        type => 'unsigned_integer'
      },
    }
  }
};

1;
