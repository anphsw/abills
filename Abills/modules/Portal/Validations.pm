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
    START_DATETIME    => {
      required => 1,
      type     => 'datetime'
    }
  },
  POST_PORTAL_ARTICLES   => {
    TITLE             => {
      required   => 1,
      type       => 'string',
      min_length => 5,
      max_length => 255
    },
    SHORT_DESCRIPTION => {
      type       => 'string',
      max_length => 600
    },
    CONTENT           => {
      type       => 'string',
    },
    STATUS            => {},
    ON_MAIN_PAGE      => {},
    DATE              => {
      required   => 1,
      type       => 'date'
    },
    PORTAL_MENU_ID    => {
      required   => 1,
      type       => 'string'
    },
    END_DATE          => {
      # type       => 'date'
    },
    ARCHIVE           => {},
    IMPORTANCE        => {},
    GID               => {
      # type       => 'string'
    },
    TAGS              => {
      # type       => 'unsigned_integer'
    },
    DOMAIN_ID         => {
      # type       => 'unsigned_integer'
    },
    DISTRICT_ID       => {
      # type       => 'unsigned_integer'
    },
    STREET_ID         => {
      # type       => 'unsigned_integer'
    },
    BUILD_ID          => {
      # type       => 'unsigned_integer'
    },
    ADDRESS_FLAT      => {
      # type       => 'string'
    },
    PICTURE           => {},
    PERMALINK         => {
      # type        => 'string'
    },
    DEEPLINK          => {},
    _PATTERN_PROPERTIES        => {
      '^.+_START_DATETIME' => {
        # type => 'datetime',
      },
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
