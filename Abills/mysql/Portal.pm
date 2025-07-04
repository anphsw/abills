package Portal;

=head1 NAME 

  Portal - internet providers Portal site

=head1 SYNOPSIS

  use Portal;

  my $Portal = Portal->new($db, $admin, \%conf);

=cut

use strict;
our $VERSION = 2.02;
use parent qw(dbcore);

my ($admin, $CONF);

#**********************************************************
=head2 function new() - add TP\'s information to datebase

  Returns:
    $self object

  Examples:
    my $Portal = Portal->new($db, $admin, \%conf);

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 function portal_menu_add() - add menu section

  Arguments:
    $attr
      id     - menu identifier in table;
      name   - section name;
      url    - url for redirect from menu;
      date   - date section add;
      status - 1: show; 0:hide;

  Returns:
    $self object

  Examples:
    $Portal->portal_menu_add({%FORM});

=cut
#**********************************************************
sub portal_menu_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('portal_menu', { %{$attr}, DATE => 'now()' });

  return $self;
}

#**********************************************************
=head2 function portal_menu_list() - get menu section list

  Arguments:
    $attr

  Returns:
    \@list -
  Examples:
    my $list = $Portal->portal_menu_list({COLS_NAME=>1});

=cut
#**********************************************************
sub portal_menu_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',       'INT',   'pm.id',                   1 ],
    [ 'NAME',     'STR',   'pm.name',                 1 ],
    [ 'URL',      'STR',   'pm.url',                  1 ],
    [ 'DATE',     'STR',   'DATE(pm.date) as date',   1 ],
    [ 'STATUS',   'INT',   'pm.status',               1 ],
  ], { WHERE => 1 });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} pm.id
      FROM portal_menu pm
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM portal_menu pm
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 function portal_menu_del() - delete menu section

  Arguments:
    $attr

  Returns:

  Examples:
    $Portal->portal_menu_del({ ID => 1 });

=cut
#**********************************************************
sub portal_menu_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('portal_menu', $attr);

  return $self;
}

#**********************************************************
=head2 function portal_menu_info() - get information aboutn menu section

  Arguments:
    $attr
      id  - section identifier

  Returns:
    $self object

  Examples:
    $Portal->portal_menu_info({ ID => 1 });

=cut
#**********************************************************
sub portal_menu_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM portal_menu WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 function portal_menu_change() - change section information in datebase

  Arguments:
    $attr
      id     - menu identifier in table;
      name   - section name;
      url    - url for redirect from menu;
      date   - date section add;
      status - 1: show; 0:hide;

  Returns:
    $self object

  Examples:
    $Portal->portal_menu_change({%FORM});

=cut
#**********************************************************
sub portal_menu_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'portal_menu',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 function portal_article_add() - add article

  Arguments:
    $attr
      id                - article's identifier
      title             - article's title
      short_description - article's short description
      content           - article's content
      status            - 0:hide article; 1:show article;
      on_main_page      - 1:on main page; 0:on subpage;
      date              - date for post this article
      portal_menu_id    - number of menu section to show

  Returns:
    $self object

  Examples:
    $Portal->portal_article_add({%FORM});

=cut
#**********************************************************
sub portal_article_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('portal_articles', $attr);

  return $self;
}

#**********************************************************
=head2 function portal_articles_list() - get articles list

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my $list = $Portal->portal_articles_list({COLS_NAME=>1});

=cut
#**********************************************************
sub portal_articles_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'date';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : 'desc';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  if (defined($attr->{ID})) {
    push @WHERE_RULES, "pa.id='$attr->{ID}' OR pa.permalink='$attr->{ID}'";
  }
  if (defined($attr->{PORTAL_MENU_ID})) {
    push @WHERE_RULES, "pa.portal_menu_id='$attr->{PORTAL_MENU_ID}' and pa.status = 1";
  }
  if (defined($attr->{MAIN_PAGE})) {
    push @WHERE_RULES, "pa.on_main_page = 1 and pa.status = 1";
  }
  if (defined($attr->{ARCHIVE})) {
    push @WHERE_RULES, "pa.archive = '$attr->{ARCHIVE}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    "SELECT pa.id,
      pa.title,
      pa.short_description,
      pa.content,
      pa.status,
      pa.on_main_page,
      pa.archive,
      pa.importance,
      pa.gid,
      pa.domain_id,
      pa.tags,
      pa.street_id,
      pa.district_id,
      pa.build_id,
      pa.address_flat,
      pa.permalink,
      DATE(pa.end_date) as end_date,
      UNIX_TIMESTAMP(pa.end_date) as etimestamp,
      UNIX_TIMESTAMP(pa.date) as utimestamp,
      pa.portal_menu_id,
      pa.picture,
      pm.name,
      ds.name as dis_name,
      st.name as st_name,
      tg.name as tag_name,
      DATE(pa.date) as date,
      pa.deeplink as deeplink
      FROM `portal_articles` AS pa
      LEFT JOIN `portal_menu` pm ON (pm.id=pa.portal_menu_id)
      LEFT JOIN `districts` ds ON (ds.id=pa.district_id)
      LEFT JOIN `streets` st ON (st.id=pa.street_id)
      LEFT JOIN `tags` tg ON (tg.id=pa.tags)
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT count(*) AS total FROM `portal_articles` pa $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 function portal_article_del() - delete article

  Arguments:
    $attr

  Returns:

  Examples:
    $Portal->portal_article_del({ ID => 1 });

=cut
#**********************************************************
sub portal_article_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('portal_articles', $attr);
  $self->query_del('portal_newsletters', {}, { PORTAL_ARTICLE_ID => $attr->{ID} }) if ($attr->{ID});

  return $self;
}

#**********************************************************
=head2 function portal_article_info() - get information aboutn article

  Arguments:
    $attr
      id  - section identifier

  Returns:
    $self object

  Examples:
    $Portal->portal_article_info({ ID => 1 });

=cut
#**********************************************************
sub portal_article_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM portal_articles AS pa
      WHERE pa.id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 function portal_article_change() - change section information in datebase

  Arguments:
    $attr
      id                - article's identifier
      title             - article's title
      short_description - article's short description
      content           - article's content
      status            - 0:hide article; 1:show article;
      on_main_page      - 1:on main page; 0:on subpage;
      date              - date for post this article
      portal_menu_id    - number of menu section to show

  Returns:
    $self object

  Examples:
    $Portal->portal_article_change({%FORM});

=cut
#**********************************************************
sub portal_article_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{ON_MAIN_PAGE} //= 0;
  $attr->{GID} //= 0;
  $attr->{TAGS} //= 0;
  $attr->{DISTRICT_ID} //= 0;
  $attr->{STREET_ID} //= 0;
  $attr->{BUILD_ID} //= 0;
  $attr->{ADDRESS_FLAT} //= '';

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'portal_articles',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 function portal_newsletter_add() - add newsletter

  Arguments:
    $attr
      id                - id;
      portal_article_id - article id;
      send_method       - id of sender;
      status            - 3 in process; 2: error, 1: success; 0: created;
      sent              - count sent messages

  Returns:
    $self object
=cut
#**********************************************************
sub portal_newsletter_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('portal_newsletters', $attr);

  return $self;
}

#**********************************************************
=head2 function portal_newsletter_change() - change newsletter options

  Arguments:
    $attr
      id                - id;
      portal_article_id - article id;
      send_method       - id of sender;
      status            - 3 in process; 2: error, 1: success; 0: created;
      sent              - count sent messages

  Returns:
    $self object
=cut
#**********************************************************
sub portal_newsletter_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'portal_newsletters',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 function portal_newsletter_change() - change newsletter options

  Arguments:
    $attr
      id                - id;
      portal_article_id - article id;
      send_method       - id of sender;
      status            - 3 in process; 2: error, 1: success; 0: created;
      sent              - count sent messages

  Returns:
    $self object
=cut
#**********************************************************
sub portal_newsletter_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('portal_newsletters', $attr);

  return $self;
}

#TODO: fully rewrite to search_expr
#**********************************************************
=head2 function portal_newsletter_list($attr) - get newsletter list

  Arguments:
    $attr

  Returns:
    $list_array_ref

=cut
#**********************************************************
sub portal_newsletter_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = (defined $attr->{DESC}) ? $attr->{DESC} : 'desc';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  if (defined($attr->{ID})) {
    push @WHERE_RULES, "pa.id='$attr->{ID}' OR pa.permalink='$attr->{ID}'";
  }
  if (defined($attr->{ARTICLE_ID})) {
    push @WHERE_RULES, "pa.portal_menu_id='$attr->{ARTICLE_ID}' and pa.status = 1";
  }
  if (defined($attr->{ARCHIVE})) {
    push @WHERE_RULES, "pa.archive = '$attr->{ARCHIVE}'";
  }
  if (defined($attr->{STATUS})) {
    push @WHERE_RULES, "pn.status = '$attr->{STATUS}'"
  }
  if (defined($attr->{NEWSLETTER_ID})) {
    push @WHERE_RULES, "pn.id = '$attr->{NEWSLETTER_ID}'"
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    "SELECT
      pn.id,
      pa.title,
      pn.send_method,
      pn.status,
      pn.sent,
      pn.start_datetime,
      DATE(pa.date) as date,
      pa.id AS article_id,
      pa.short_description,
      pa.content,
      pa.on_main_page,
      pa.archive,
      pa.importance,
      pa.gid,
      pa.domain_id,
      pa.tags,
      pa.street_id,
      pa.district_id,
      pa.build_id,
      pa.address_flat,
      pa.permalink,
      DATE(pa.end_date) as end_date,
      UNIX_TIMESTAMP(pa.end_date) as etimestamp,
      UNIX_TIMESTAMP(pa.date) as utimestamp,
      pa.portal_menu_id,
      pa.picture,
      pm.name,
      pa.deeplink
      FROM `portal_newsletters` pn
      LEFT JOIN `portal_articles` pa ON (pa.id=pn.portal_article_id)
      LEFT JOIN `portal_menu` pm ON (pm.id=pa.portal_menu_id)
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total
    FROM portal_newsletters pn
    LEFT JOIN `portal_articles` pa ON (pa.id=pn.portal_article_id)
    LEFT JOIN `portal_menu` pm ON (pm.id=pa.portal_menu_id)
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 function attachment_add()

  Arguments:
    $attr

  Returns:
    @list

=cut
#**********************************************************
sub attachment_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('portal_attachments', $attr);

  return $self;
}

#TODO: search_expr
#**********************************************************
=head2 function attachment_info() - attachment info by id

  Arguments:
    $attr

  Returns:
    @list

=cut
#**********************************************************
sub attachment_info {
  my $self = shift;
  my ($id) = @_;

  $self->query(
    "SELECT * FROM portal_attachments WHERE id = ?;",
    undef,
    {
      INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 function attachment_list()

  Arguments:
    $attr

  Returns:
    @list

=cut
#**********************************************************
sub attachment_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = $attr->{SORT} ? $attr->{SORT} : 'pa.id';
  my $DESC = $attr->{DESC} ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',            'INT',   'pa.id',                                      1 ],
    [ 'FILENAME',      'STR',   'pa.filename',                                1 ],
    [ 'FILE_SIZE',     'INT',   'pa.file_size',                                       1 ],
    [ 'FILE_TYPE',     'STR',   'pa.file_type',                                       1 ],
    [ 'UPLOADED_AT',   'DATE',  "DATE(pa.uploaded_at) as uploaded_at",        1 ],
  ], { WHERE => 1 });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} pa.id
      FROM portal_attachments pa
      $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM portal_attachments pa
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 function attachment_del() - attachment info by id

  Arguments:
    $attr

  Returns:
    @list

=cut
#**********************************************************
sub attachment_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('portal_attachments', { ID => $id });

  return $self;
}

1;
