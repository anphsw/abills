package Docs::Utils;

use strict;
use warnings FATAL => 'all';

use parent 'Exporter';

use Abills::Base qw(days_in_month);

our @EXPORT = qw(
  next_payment_period
);

our @EXPORT_OK = qw(
  next_payment_period
);

#**********************************************************
=head2 next_payment_period($attr)

  Arguments:
     $attr
       DATE
       PERIOD
       SERVICE_ACTIVATE
       FIXED_FEES_DAY - parameter from conf

  Resturns:
    $from_date, $to_date

=cut
#**********************************************************
sub next_payment_period {
  my ($attr) = @_;

  my $from_date = q{};
  my $to_date   = q{};

  my $next_period = $attr->{PERIOD} || 1;
  my $service_activate = $attr->{SERVICE_ACTIVATE} || q{};
  my $date = ($attr->{DATE} && $attr->{DATE} ne '0000-00-00') ? $attr->{DATE} : $main::DATE;

  my($Y, $M, $D)=split(/-/, $date);

  my $TO_D = 1;

  if ($service_activate && $service_activate ne '0000-00-00' && !$attr->{FIXED_FEES_DAY} ){
    my $start_period_unixtime = (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ));
    ($Y, $M, $D) = split( /-/, POSIX::strftime( "%Y-%m-%d", localtime( (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0,
      0 ) + ((($start_period_unixtime > time) ? 0 : 1) + 30 * (($start_period_unixtime > time) ? 0 : 1)) * 86400) ) ) );
    $from_date = "$Y-$M-$D";

    ($Y, $M, $D) = split( /-/, POSIX::strftime( "%Y-%m-%d", localtime( (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0,
      0 ) + ((($start_period_unixtime > time) ? 1 : (1 * $next_period - 1)) + 30 * (($start_period_unixtime > time) ? 1 : $next_period)) * 86400) ) ) );
    $to_date = "$Y-$M-$D";
  }
  else{
    $M += 1;
    if ( $M > 12 ){
      $M = $M - 12;
      $Y++;
    }

    $from_date = sprintf("%d-%02d-%02d", $Y, $M, 1);

    if ( $service_activate eq '0000-00-00' ){
      $TO_D = days_in_month({ DATE => "$Y-$M" });
    }
    else{
      if ( $attr->{FIXED_FEES_DAY} ){
        $TO_D = ($D > 1) ? ($D - 1) : days_in_month({ DATE => "$Y-$M" });
      }
      else{
        $TO_D = days_in_month({ DATE => "$Y-$M" });
      }
    }

    $to_date = sprintf("%d-%02d-%02d", $Y, $M, $TO_D);
  }

  return $from_date, $to_date;
}

1;
