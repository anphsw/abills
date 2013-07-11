package Customers;

# Accounts manage functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw(
);

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use Companies;
my ($admin, $CONF);

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
# Account
#**********************************************************
sub company {
  my $self = shift;
  my $Companies = Companies->new($self->{db}, $admin, $CONF);

  return $Companies;
}

1
