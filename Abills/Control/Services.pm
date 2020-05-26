=head1 NAME

  INternet base functions

=cut

use strict;
use warnings FATAL => 'all';
use Tariffs;
use Abills::Base qw(days_in_month);

our(
  $db,
  $admin,
  %conf,
  $html,
  %lang,
  $DATE
);


#**********************************************************
=head sel_tp($tp_id)

  Arguments:
    MODULE
    TP_ID    - SHow tp name for tp_id
    SELECT   - Select element
    SKIP_TP  - Skip show tp
    SHOW_ALL - Show all tps
    SEL_OPTIONS - Extra sel options (items)
    EX_PARAMS   - Extra sell options
    SMALL_DEPOSIT_ACTION
    DOMAIN_ID

  Returns:
    \%tp_hash (tp_id => name)

=cut
#**********************************************************
sub sel_tp {
  my ($attr) = @_;

  my $Tariffs = Tariffs->new($db, \%conf, $admin);
  my %params = ( MODULE => 'Dv;Internet' );
  if ($attr->{MODULE}) {
    $params{MODULE} = $attr->{MODULE};
  }

  if($attr->{TP_ID}) {
    if($attr->{TP_ID} =~ /:(\d+)/) {
      $attr->{TP_ID} = $1;
    }

    if(! $attr->{SHOW_ALL}) {
      $params{INNER_TP_ID} = $attr->{TP_ID};
    }
  }

  my $list = $Tariffs->list({
    NEW_MODEL_TP => 1,
    DOMAIN_ID    => $users->{DOMAIN_ID} || $admin->{DOMAIN_ID} || $attr->{DOMAIN_D},
    COLS_NAME    => 1,
    STATUS       => '_SHOW',
    %params
  });

  if($attr->{TP_ID} && ! $attr->{EX_PARAMS}) {
    if($Tariffs->{TOTAL}) {
      return "$list->[0]->{id} : $list->[0]->{name}";
    }

    return $attr->{TP_ID};
  }

  my %tp_list = ();

  foreach my $line (@$list) {
    next if($attr->{SKIP_TP} && $attr->{SKIP_TP} == $line->{tp_id});
    next if (!$attr->{SHOW_ALL} && $line->{status});
    $tp_list{$line->{tp_id}} = $line->{id} .' : '. $line->{name};
  }

  if($attr->{SELECT}) {
    my %EX_PARAMS = ();

    my $element_name = $attr->{SELECT};
    my %extra_options = ('' => '--');
    if($attr->{SEL_OPTIONS}) {
      %extra_options = %{ $attr->{SEL_OPTIONS} };
    }

    if($attr->{EX_PARAMS}) {
      %EX_PARAMS = ( EX_PARAMS => $attr->{EX_PARAMS} );
    }

    return $html->form_select(
      $element_name,
      {
        SELECTED    => $attr->{$element_name} // $FORM{$element_name},
        SEL_HASH    => \%tp_list,
        SEL_OPTIONS => \%extra_options,
        NO_ID       => 1,
        %EX_PARAMS
      }
    );
  }

  return \%tp_list;
}

#**********************************************************
=head get_services($user_info) - Get all user services and info

  Arguments:
    $user_info
    $attr
      ACTIVE_ONLY
      SKIP_MODULES

  Returns:
    \%services
       list
         SERVICE_NAME
         SERVICE_DESC
         SUM
       total_sum

=cut
#**********************************************************
sub get_services {
  my ($user_info, $attr) = @_;

  my %result = ();;

  my $cross_modules_return = cross_modules_call('_docs', {
    UID          => $user_info->{UID},
    REDUCTION    => $user_info->{REDUCTION},
    FULL_INFO    => 1,
    SKIP_MODULES => $attr->{SKIP_MODULES}
    #PAYMENT_TYPE => 0
  });

  my $days_in_month = days_in_month({ DATE => $DATE });

  foreach my $module (sort keys %$cross_modules_return) {
    if (ref $cross_modules_return->{$module} eq 'ARRAY') {
      next if ($#{$cross_modules_return->{$module}} == -1);
      foreach my $service_info (@{$cross_modules_return->{$module}}) {
        if (ref $service_info eq 'HASH') {
          #foreach my $mod_info ( @{ $module_return } ) {
          my $status = $service_info->{status} || 0;
          if ($attr->{ACTIVE_ONLY} && $status) {
            next;
          }

          my $day_fee = ($service_info->{day} && $service_info->{day} > 0) ? $service_info->{day} * $days_in_month : 0;
          my $sum = $day_fee + ($service_info->{month} || 0);

          if($service_info->{tp_reduction_fee} && $user_info->{REDUCTION}) {
            if($user_info->{REDUCTION} < 100 ) {
              $sum = $sum * ((100 - $user_info->{REDUCTION}) / 100);
              $service_info->{month} = $service_info->{month} * ((100 - $user_info->{REDUCTION}) / 100);
              $service_info->{day} = $service_info->{day} * ((100 - $user_info->{REDUCTION}) / 100);
            }
            else {
              $sum = 0;
            }
          }

          push @{$result{list}}, {
            MODULE           => $module,
            SERVICE_NAME     => $service_info->{service_name} || q{},
            SERVICE_DESC     => $service_info->{service_desc} || q{},
            SUM              => $sum,
            STATUS           => $status,
            TP_REDUCTION_FEE => $service_info->{tp_reduction_fee} || 0,
          };

          $result{total_sum} += $sum;

          my $day_division = $days_in_month;
          if($service_info->{service_activate} && $service_info->{service_activate} ne '0000-00-00') {
            $day_division = 30;
          }

          if ($service_info->{abon_distribution}) {
            $result{distribution_fee} += $service_info->{month} / $day_division;
          }

          if ($service_info->{day}) {
            $result{distribution_fee} += $service_info->{day};
          }

          #}
        }
        # else {
        #   my ($service_name, $service_desc, $sum, undef, undef, undef, undef, $status) = split(/\|/, $service_info);
        #   push @{$result{list}}, {
        #      MODULE       => $module,
        #      SERVICE_NAME => $service_name,
        #      SERVICE_DESC => $service_desc,
        #      SUM          => $sum,
        #      STATUS       => $status || 0,
        #    };
        #    $result{total_sum} += $sum;
        # }
      }
    }
  }

  return \%result;
}

1;