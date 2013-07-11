package Reports;
# Reports module
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.01;
@ISA     = ('Exporter');

@EXPORT = qw(
);

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

#**********************************************************
# Init
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
# Default values
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr);

  $self->query2("INSERT INTO reports_wizard (name, comments, query, query_total, fields, date, aid) 
           values ('$DATA{NAME}', '$DATA{COMMENTS}', '$DATA{QUERY}', '$DATA{QUERY_TOTAL}',
           '$DATA{FIELDS}', curdate(), '$admin->{AID}');", 'do'
  );

  return $self;
}

#**********************************************************
# del $user, $id
#**********************************************************
sub del {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("DELETE FROM reports_wizard WHERE id='$id';", 'do');

  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $WHERE;
  my $list;

  $self->query2("SELECT name, comments, id
    FROM reports_wizard
    $WHERE 
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", 
  undef, 
  $attr
  );

  $list = $self->{list};  

  $self->query2("SELECT count(id) AS total FROM reports_wizard $WHERE",
  undef, { INFO => 1 });

  return $list;
}

#**********************************************************
# mk()
#**********************************************************
sub mk {
  my $self = shift;
  my ($attr) = @_;

  my $SORT   = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC   = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE;
  my $list;
  delete ($self->{COL_NAMES_ARR});

  $attr->{QUERY}=~s/%PG%/$PG/;
  $attr->{QUERY}=~s/%PAGE_ROWS%/$PAGE_ROWS/;
  $attr->{QUERY}=~s/%SORT%/$SORT/;
  $attr->{QUERY}=~s/%DESC%/$DESC/;
  $attr->{QUERY}=~s/%PAGES%/LIMIT $PG, $PAGE_ROWS/;

  $self->query2("$attr->{QUERY};", undef, $attr);
  $list = $self->{list};  
  
  if ($attr->{QUERY_TOTAL}) {
    $self->query2("$attr->{QUERY_TOTAL};", 
    undef, 
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT 
      id,
      name, 
      comments, 
      query, 
      query_total,
      fields, 
      date, 
      aid
     FROM reports_wizard
     WHERE id='$attr->{ID}';",
   undef,
   { INFO => 1 }
  );

  return $self;
}


#**********************************************************
# change()
#**********************************************************
sub change {
  my $self   = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'reports_wizard',
      DATA            => $attr,
    }
  );

  return $self;
}

1
