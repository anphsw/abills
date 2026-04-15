# billd plugin
#**********************************************************
=head1

 billd plugin

 Standart execute
    /usr/abills/libexec/billd fees_codefication

=cut
#*********************************************************
use strict;
use warnings FATAL => 'all';
use Fees;

our (
  $argv,
  $db,
  %conf,
);

our Admins $Admin;
our $admin = $Admin;
my $Fees = Fees->new($db, $admin, \%conf);

fees_codefication();

#**********************************************************
=head2 fees_codefication()

=cut
#**********************************************************
sub fees_codefication {
  my $self = shift;

  my $sql = <<'SQL';
UPDATE fees f
  JOIN tarif_plans tp
  ON tp.tp_id = REGEXP_SUBSTR(REGEXP_SUBSTR(f.dsc, '\\(([0-9]+)\\)'), '[0-9]+')
SET f.method = tp.fees_method
WHERE f.dsc LIKE 'Trip%'
SQL

  $Fees->query($sql,'do');

  $sql = <<'SQL';
UPDATE fees f
  JOIN tarif_plans tp
  ON tp.tp_id = REGEXP_SUBSTR(REGEXP_SUBSTR(f.dsc, '\\(([0-9]+)\\)'), '[0-9]+')
SET f.method = tp.fees_method
WHERE f.dsc LIKE 'Inter%'
SQL

  $Fees->query($sql,'do');

  $sql = <<'SQL';
UPDATE fees f
  JOIN abon_tariffs tp
  ON tp.id = REGEXP_SUBSTR(REGEXP_SUBSTR(f.dsc, '\\(([0-9]+)\\)'), '[0-9]+')
SET f.method = tp.fees_type
WHERE f.dsc LIKE 'Дополнитель%'
SQL

  $Fees->query($sql,'do');

  $sql = <<'SQL';
UPDATE fees f
  JOIN abon_tariffs tp
  ON tp.id = REGEXP_SUBSTR(REGEXP_SUBSTR(f.dsc, '\\(([0-9]+)\\)'), '[0-9]+')
SET f.method = tp.fees_type
WHERE f.dsc LIKE 'Периодические%'
SQL

  $Fees->query($sql,'do');

 if ($Fees->{errno}){
   $self->{errno}  = $Fees->{errno};
   $self->{errstr} = $Fees->{errstr};
   return $self;
 }

  return 1;
}

1;