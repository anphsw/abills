package Employees::Api::admin::Rfid;
=head1 NAME

  Employees Rfid

  Endpoints:
    /employees/rfid/*

=cut
use strict;
use warnings FATAL => 'all';

use Control::Errors;

use Employees;

my Employees $Employees;
my Control::Errors $Errors;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Employees = Employees->new($db, $admin, $conf);
  $Employees->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_employees_rfid_list($path_params, $query_params)

  Endpoint GET /employees/rfid/list/

=cut
#**********************************************************
sub get_employees_rfid_list {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my @allowed_params = (
    'ID',
    'DATETIME',
    'RFID',
    'ADMIN',
    'ADMIN_NAME',
    'AID',
  );

  my %PARAMS = (
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 50,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 5,
  );
  foreach my $param (@allowed_params) {
    next if (!defined($query_params->{$param}));
    $PARAMS{$param} = $query_params->{$param} || '_SHOW';
  }

  $Employees->rfid_log_list({
    %PARAMS,
    COLS_NAME => 1,
  });
}

1;
