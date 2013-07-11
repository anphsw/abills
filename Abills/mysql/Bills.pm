package Bills;

# Bills accounts manage functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw();

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
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
    DEPOSIT    => 0.00,
    COMPANY_ID => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub create {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => defaults() });
  $self->query_add('bills', { %DATA, 
  	                          REGISTRATION => 'now()' 
  	                        });

  $self->{BILL_ID} = $self->{INSERT_ID} if (!$self->{errno});

  return $self;
}

#**********************************************************
# Bill add sum to bill
# Type:
#  add
#  take
#**********************************************************
sub action {
  my $self = shift;
  my ($type, $BILL_ID, $SUM, $attr) = @_;
  my $value = '';

  if ($SUM == 0) {
    $self->{errstr} = 'Wrong sum 0';
    return $self;
  }
  elsif ($type eq 'take') {
    $value = "-$SUM";
  }
  elsif ($type eq 'add') {
    $value = "+$SUM";
  }
  else {
    $self->{errstr} = 'Select action';
    return $self;
  }

  $self->query2("UPDATE bills SET deposit=deposit$value WHERE id='$BILL_ID';", 'do');

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    BILL_ID    => 'id',
    UID        => 'uid',
    COMPANY_ID => 'company_id',
    SUM        => 'sum'
  );

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'BILL_ID',
      TABLE        => 'bills',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->bill_info($attr->{BILL_ID}),
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  if (defined($attr->{COMPANY_ONLY})) {
    $WHERE = "WHERE b.company_id>0";
    if (defined($attr->{UID})) {
      $WHERE .= " or b.uid='$attr->{UID}'";
    }
  }

  $self->query2("SELECT b.id, b.deposit, u.id,  c.name, b.uid, b.company_id
     FROM bills b
     LEFT JOIN users u ON  (b.uid=u.uid) 
     LEFT JOIN companies c ON  (b.company_id=c.id) 
     $WHERE 
     GROUP BY 1
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return $self->{list};
}

#**********************************************************
# Bill
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("DELETE FROM bills
    WHERE id='$attr->{BILL_ID}';", 'do'
  );

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT b.id AS bill_id, 
     b.deposit AS deposit, 
     u.id As login, 
     b.uid, 
     b.company_id
    FROM bills b
    LEFT JOIN users u ON (u.uid = b.uid)
    WHERE b.id='$attr->{BILL_ID}';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

1
