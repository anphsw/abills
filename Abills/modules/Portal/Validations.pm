package Portal::Validations;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

our @EXPORT = qw(
  POST_PORTAL_NEWSLETTER
  POST_PORTAL_ARTICLES
  POST_PORTAL_MENUS
);

our @EXPORT_OK = qw(
  POST_PORTAL_NEWSLETTER
  POST_PORTAL_ARTICLES
  POST_PORTAL_MENUS
);

use constant {
  POST_PORTAL_NEWSLETTER => {
    PORTAL_ARTICLE_ID => {
      required => 1,
      type     => 'unsigned_integer',
    },
    SEND_METHOD       => {
      required => 1,
      type     => 'unsigned_integer',
    },
  },
  POST_PORTAL_ARTICLES   => {
    TITLE             => {
      required   => 1,
      type       => 'string',
      min_length => 5,
      max_length => 255
    },
    DATE              => {
      required => 1,
      type     => 'date'
    },
    PORTAL_MENU_ID    => {
      required => 1,
      type     => 'string'
    },
    SHORT_DESCRIPTION => {
      type       => 'string',
      max_length => 600
    },
    CONTENT           => {
      type => 'string',
    }
  },
  POST_PORTAL_MENUS      => {
    NAME   => {
      required   => 1,
      type       => 'string',
      min_length => 3,
      max_length => 45,
    },
    URL    => {
      type       => 'string',
      max_length => 100,
    },
  }
};

1;
