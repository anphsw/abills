package Help;
# Help
#

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
my $MODULE = 'Help';

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;
  my $self = {};
  bless($self, $class);

  $self->{db}=$db;

  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $WHERE = "WHERE function='$attr->{FUNCTION}'";

  $self->query2("SELECT function, title, help
     FROM help
     $WHERE;",
     undef, { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('help', $attr);

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'FUNCTION',
      TABLE        => 'help',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;
  $self->query2("DELETE from help WHERE function='$self->{FUNCTION}';", 'do');
  return $self->{result};
}

1
