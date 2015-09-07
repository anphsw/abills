package Abills::Filters;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use POSIX qw(locale_h);


use Exporter;


$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw(
&_expr
);

@EXPORT_OK = qw(
_expr
);

%EXPORT_TAGS = ();

#**********************************************************
# Filter expr
#
#**********************************************************
sub _expr {
  my ($value, $expr_tpl)=@_;

  if (! $expr_tpl) {
    return $value; 
  }

  my @num_expr = split(/;/, $expr_tpl);

  for (my $i = 0 ; $i <= $#num_expr ; $i++) {
    my ($left, $right) = split(/\//, $num_expr[$i]);
    my $r = ($right eq '$1') ? $right : eval "\"$right\"";
    if ($value =~ s/$left/eval $r/e) {
      return $value;
    }
  }

  return $value;
}


1;
