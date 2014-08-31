package Portal;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw();

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

#**********************************************************
# Init Portal module
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  my $self = {};
  bless($self, $class);

  $self->{db}=$db;

  return $self;
}

#**********************************************************
# Add Portal menu
#**********************************************************
sub portal_menu_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);

  $self->query_add('portal_menu', { %DATA, DATE => 'now()' });

  return 0;
}

#**********************************************************
# Portal menu list
#**********************************************************
sub portal_menu_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';

  if (defined($attr->{ID})) {
    push @WHERE_RULES, "id='$attr->{ID}'";
  }
  if (defined($attr->{NOT_URL})) {
    push @WHERE_RULES, "url=''";
  }
  if (defined($attr->{MENU_SHOW})) {
    push @WHERE_RULES, "status = 1";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT id,
                name,
                url,
                DATE(date) AS date,
                status
                FROM portal_menu
                $WHERE
                ORDER BY $SORT $DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
# Del portal menu
#**********************************************************
sub portal_menu_del {
  my $self        = shift;
  my ($attr)      = @_;
  my @WHERE_RULES = ();
  $WHERE = '';

  if ($attr->{ID}) {
    push @WHERE_RULES, " id='$attr->{ID}' ";
  }

  if ($#WHERE_RULES > -1) {
    $WHERE = join(' and ', @WHERE_RULES);
    $self->query2("DELETE from portal_menu WHERE $WHERE;", 'do');
  }
  return $self->{result};
}

#**********************************************************
# Portal menu info
#**********************************************************
sub portal_menu_info {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);

  $self->query2(
    "SELECT   id,
                name,  
                url,
                DATE(date) AS date,
                status
                FROM portal_menu 
                WHERE id='$attr->{ID}';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# Change portal menu
#**********************************************************
sub portal_menu_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'portal_menu',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# Add Article
#**********************************************************
sub portal_article_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);

  $self->query_add('portal_articles', \%DATA);

  return 0;
}

#**********************************************************
# Portal articles list
#**********************************************************
sub portal_articles_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';

  if (defined($attr->{ID})) {
    push @WHERE_RULES, "pa.id='$attr->{ID}'";
  }
  if (defined($attr->{ARTICLE_ID})) {
    push @WHERE_RULES, "pa.portal_menu_id='$attr->{ARTICLE_ID}' and pa.status = 1";
  }
  if (defined($attr->{MAIN_PAGE})) {
    push @WHERE_RULES, "pa.on_main_page = 1 and pa.status = 1";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2(
    "SELECT   pa.id,
                pa.title,  
                pa.short_description,
                pa.content,
                pa.status,
                pa.on_main_page,
                UNIX_TIMESTAMP(pa.date),
                pa.portal_menu_id,
                pm.name,
                DATE(pa.date)
                FROM portal_articles AS pa
              LEFT JOIN portal_menu pm ON (pm.id=pa.portal_menu_id)   
                $WHERE
                ORDER BY $SORT $DESC;", undef, $attr
  );

  return $self->{list};
}

#**********************************************************
# Del Portal article
#**********************************************************
sub portal_article_del {
  my $self        = shift;
  my ($attr)      = @_;
  my @WHERE_RULES = ();
  $WHERE = '';

  if ($attr->{ID}) {
    push @WHERE_RULES, " id='$attr->{ID}' ";
  }

  if ($#WHERE_RULES > -1) {
    $WHERE = join(' and ', @WHERE_RULES);
    $self->query2("DELETE from portal_articles WHERE $WHERE;", 'do');
  }

  return $self->{result};
}

#**********************************************************
# Portal article info
#**********************************************************
sub portal_article_info {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);

  $self->query2(
    "SELECT   pa.id,
                pa.title,
                pa.short_description,
                pa.content,
                pa.status,
                pa.on_main_page,
                DATE(pa.date) AS date,
                pa.portal_menu_id
                FROM portal_articles AS pa 
                WHERE pa.id='$attr->{ID}';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# Change portal article
#**********************************************************
sub portal_article_change {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{ON_MAIN_PAGE}) {
    $attr->{ON_MAIN_PAGE} = 0;
  }

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'portal_articles',
      DATA         => $attr,
    }
  );
  return $self;
}

1