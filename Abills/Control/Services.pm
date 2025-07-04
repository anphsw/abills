=head1 NAME

  Information about user services

=cut

use strict;
use warnings FATAL => 'all';

use Tariffs;
use Abills::Base qw(days_in_month);
require Abills::Misc;

our (
  $db,
  $admin,
  %conf,
  $html,
#  %lang,
  $DATE,
  %FORM,
  $base_dir,
  @MODULES
);

#**********************************************************
=head get_services($user_info, $attr) - Get all user services and info

  Arguments:
    $user_info
      UID
      REDUCTION
    $attr
      ACTIVE_ONLY
      SKIP_MODULES
      MODULES

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

  my %result = ();

  my $cross_modules_return = ::cross_modules('docs', {
    %{($attr) ? $attr : {} },
    UID          => $user_info->{UID},
    REDUCTION    => $user_info->{REDUCTION},
    FULL_INFO    => 1,
    SKIP_MODULES => $attr->{SKIP_MODULES},
    FORM         => \%FORM
    #PAYMENT_TYPE => 0
  }) || {};

  my $days_in_month = days_in_month({ DATE => $DATE });

  foreach my $module (sort keys %$cross_modules_return) {
    if (ref $cross_modules_return->{$module} eq 'ARRAY') {
      next if ($#{$cross_modules_return->{$module}} == -1);
      foreach my $service_info (@{$cross_modules_return->{$module}}) {

        if (ref $service_info eq 'HASH') {
          $service_info->{month} //= 0;
          $service_info->{day} //= 0;
          my $status = $service_info->{status} || 0;
          if ($attr->{ACTIVE_ONLY} && $status && ! in_array($status, [ 5 ])) {
            next;
          }

          my $day_fee = ($service_info->{day} && $service_info->{day} > 0) ? $service_info->{day} * $days_in_month : 0;
          my $sum = $day_fee + ($service_info->{month} || 0);

          my $original_sum = $sum;
          if ($service_info->{tp_reduction_fee} && $user_info->{REDUCTION}) {
            if ($user_info->{REDUCTION} < 100) {
              $sum = $sum * ((100 - $user_info->{REDUCTION}) / 100);
              $service_info->{month} = $service_info->{month} * ((100 - $user_info->{REDUCTION}) / 100);
              if ($service_info->{day}) {
                $service_info->{day} = $service_info->{day} * ((100 - $user_info->{REDUCTION}) / 100);
              }
            }
            else {
              $service_info->{month} = 0;
              $service_info->{day} = 0;
              $sum = 0;
            }
          }

          push @{$result{list}}, {
            MODULE           => $module,
            SERVICE_NAME     => $service_info->{service_name} || q{},
            SERVICE_DESC     => $service_info->{service_desc} || q{},
            SUM              => $sum,
            ORIGINAL_SUM     => $original_sum,
            STATUS           => $status,
            TP_REDUCTION_FEE => $service_info->{tp_reduction_fee} || 0,
            ACTIVATE         => $service_info->{service_activate},
            MODULE_NAME      => $service_info->{module_name},
            ID               => $service_info->{id},
            TP_ID            => $service_info->{tp_id} || 0,
            MONTH            => $service_info->{month} || 0,
            ABON_DISTRIBUTION=> $service_info->{abon_distribution} || 0,
            DAY              => $service_info->{day} || 0,
          };

          $result{total_sum} += $sum;

          my $day_division = $days_in_month;
          if ($service_info->{service_activate} && $service_info->{service_activate} ne '0000-00-00') {
            $day_division = 30;
          }

          if ($service_info->{abon_distribution} && $service_info->{month}) {
            $result{distribution_fee} += $service_info->{month} / $day_division;
          }

          if ($service_info->{day}) {
            $result{distribution_fee} += $service_info->{day};
          }
        }
      }
    }
  }

  return \%result;
}

#**********************************************************
=head2 tp_gids_by_geolocation($attr)

  Arguments:
    $location_id
    $Tariffs
    $user_gid

  Return:

=cut
#**********************************************************
sub tp_gids_by_geolocation {
  my ($location_id, $Tariffs, $user_gid) = @_;

  require Address;
  Address->import();
  my $Address = Address->new($db, $admin, \%conf);
  my $address = $Address->address_info($location_id);

  return 0 if ($Address->{TOTAL} < 1 && !$user_gid);

  my @tp_gids = ();

  my $group_by_build = $Tariffs->tp_geo_list({ TP_GID => '_SHOW', BUILD_ID => $location_id, COLS_NAME => 1 });
  map(push(@tp_gids, $_->{tp_gid}), @{$group_by_build}) if ($Tariffs->{TOTAL} > 0);

  my $group_by_street = $Tariffs->tp_geo_list({ TP_GID => '_SHOW', STREET_ID => $address->{STREET_ID}, COLS_NAME => 1 });
  map(push(@tp_gids, $_->{tp_gid}), @{$group_by_street}) if ($Tariffs->{TOTAL} > 0);

  my $group_by_district = $Tariffs->tp_geo_list({ TP_GID => '_SHOW', DISTRICT_ID => $address->{DISTRICT_ID}, COLS_NAME => 1 });
  map(push(@tp_gids, $_->{tp_gid}), @{$group_by_district}) if ($Tariffs->{TOTAL} > 0);

  my $group_without_location = $Tariffs->tp_geo_list({ TP_GID => '_SHOW', EMPTY_GEOLOCATION => 1, COLS_NAME => 1 });
  map(push(@tp_gids, $_->{gid}), @{$group_without_location}) if ($Tariffs->{TOTAL} > 0);

  my $gids_by_geolocation = join(';', @tp_gids);

  if ($user_gid) {
    my $group_by_users_groups = $Tariffs->tp_group_users_groups_info({
      TP_GID    => $gids_by_geolocation || '_SHOW',
      GID       => $user_gid,
      COLS_NAME => 1
    });

    if ($Tariffs->{TOTAL} > 0) {
      @tp_gids = ();
      map(push(@tp_gids, $_->{tp_gid}), @{$group_by_users_groups});
    }
  }

  my $group_without_users_groups = $Tariffs->tp_group_users_groups_info({
    EMPTY_GROUP => 1,
    TP_GID2     => $gids_by_geolocation || '_SHOW',
    COLS_NAME   => 1
  });
  map(push(@tp_gids, $_->{g_gid}), @{$group_without_users_groups}) if ($Tariffs->{TOTAL} > 0);

  #Add TP without groups
  push @tp_gids, 0;

  return join(';', @tp_gids);
}

#**********************************************************
=head2 service_status_change($uid, $status)

  Arguments:
    $user_info
    $status
    $attr
      DATE
      DEBUG

  Results:

=cut
#**********************************************************
sub service_status_change {
  my ($user_info, $status, $attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  $status =~ /:?(\d+)/;
  $status = $1;

  my @modules = @MODULES;

  if (in_array('Triplay', \@modules)) {
    @modules = ('Triplay');
  }

  foreach my $module (@modules) {
    require "$module/webinterface";
    my $fn = lc($module) . (($status == 3) ? '_service_deactivate' : '_service_activate');
    if (defined(&$fn)) {
      if ($debug > 3) {
        print "run: $fn\n";
      }

      &{\&$fn}({
        USER_INFO   => {
          UID     => $user_info->{UID},
          BILL_ID => $user_info->{BILL_ID}
          #ID  => $service_id,
        },
        # TP_INFO   => {
        #   SMALL_DEPOSIT_ACTION => -1
        # },
        %$attr,
        STATUS      => $status,
        GET_ABON    => 1,
        QUITE       => 1,
        DATE        => $attr->{DATE},
        RECALCULATE => 1,
      });
    }
  }

  my $users = $attr->{USER_INFO};
  $users->change($user_info->{UID}, { DISABLE => $status });

  return 1;
}

#**********************************************************
=head2 service_status_change($uid, $status)

  Arguments:
    service: string - Abon/Internet/Voip
    uid: number     - 123456

  Results:
    user services list

=cut
#**********************************************************
sub get_user_services {
  my ($attr) = @_;

  my $service_name = $attr->{service} || '';
  my $skip_services = $attr->{skip_services} || '';
  my $uid = $attr->{uid} || '--';

  require Users;
  Users->import();
  my $Users = Users->new($db, $admin, \%conf);
  $Users->info($uid);

  my $result = ::cross_modules('user_services', {
    UID                => $uid,
    SKIP_COMPANY_USERS => 1,
    USER_INFO          => $Users,
    MODULES            => $service_name,
    SKIP_MODULES       => $skip_services,
    ACTIVE_ONLY        => $attr->{active_only} ? 1 : 0
  });

  if ($service_name && $result) {
    return $result->{$service_name} || [];
  }

  return $result;
}

1;
