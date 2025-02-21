=head1 NAME

  Information about user services

=cut

use strict;
use warnings FATAL => 'all';

use Tariffs;
use Abills::Base qw(days_in_month);

our (
  $db,
  $admin,
  %conf,
  $html,
  %lang,
  $DATE,
  %FORM,
  $base_dir,
  @MODULES
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
    SERVICE_ID  - TP SErvice ID
    SMALL_DEPOSIT_ACTION
    USER_INFO -
    DOMAIN_ID
    MAIN_MENU -

  Returns:
    \%tp_hash (tp_id => name)

=cut
#**********************************************************
sub sel_tp {
  my ($attr) = @_;

  my $Tariffs = Tariffs->new($db, \%conf, $admin);
  my %params = (MODULE => 'Dv;Internet');
  $params{MODULE} = $attr->{MODULE} if $attr->{MODULE};

  my $users = $attr->{USER_INFO};

  my $tp_gids = $attr->{CHECK_GROUP_GEOLOCATION} ?
    tp_gids_by_geolocation($attr->{CHECK_GROUP_GEOLOCATION}, $Tariffs, $attr->{USER_GID}) : '';

  if ($attr->{TP_ID}) {
    $attr->{TP_ID} = $1 if $attr->{TP_ID} =~ /:(\d+)/;
    $params{INNER_TP_ID} = $attr->{TP_ID} if !$attr->{SHOW_ALL};
  }

  $params{SERVICE_ID} = $attr->{SERVICE_ID} if $attr->{SERVICE_ID};

  my $list = $Tariffs->list({
    NEW_MODEL_TP  => 1,
    DOMAIN_ID     => $users->{DOMAIN_ID} || $admin->{DOMAIN_ID} || $attr->{DOMAIN_ID},
    COLS_NAME     => 1,
    STATUS        => '0',
    TP_GID        => $tp_gids || '_SHOW',
    MONTH_FEE     => '_SHOW',
    DAY_FEE       => '_SHOW',
    COMMENTS      => '_SHOW',
    TP_GROUP_NAME => '_SHOW',
    DESCRIBE_AID  => '_SHOW',
    %params
  });

  if ($attr->{TP_ID} && !$attr->{EX_PARAMS}) {
    return "$list->[0]->{id} : $list->[0]->{name}" if $Tariffs->{TOTAL} && $Tariffs->{TOTAL} > 0;

    return $attr->{TP_ID};
  }

  my %tp_list = ();

  foreach my $line (@$list) {
    next if ($attr->{SKIP_TP} && $attr->{SKIP_TP} == $line->{tp_id});
    next if (!$attr->{SHOW_ALL} && $line->{status});

    my $describe_for_aid = ($line->{describe_aid}) ? ('[' . $line->{describe_aid} . ']') : '';

    if ($attr->{GROUP_SORT}) {
      my $small_deposit = q{};
      if ($users) {
        my $deposit = (defined($users->{DEPOSIT}) && $users->{DEPOSIT} =~ /^[\-0-9,\.\/]+$/) ? $users->{DEPOSIT} : 0;
        $small_deposit = ($deposit + ($users->{CREDIT} || 0) < ($line->{month_fee} || 0) + ($line->{day_fee} || 0)) ?
          ' (' . $lang{ERR_SMALL_DEPOSIT} . ')' : '';
      }

      $tp_list{($line->{tp_group_name} || '')}{ $line->{tp_id} } = "$line->{id} : $line->{name} $describe_for_aid " . $small_deposit;
    }
    else {
      $tp_list{$line->{tp_id}} = $line->{id} . ' : ' . $line->{name} . ' ' . $describe_for_aid;
    }
  }

  if ($attr->{SELECT}) {
    my %EX_PARAMS = ();

    my $element_name = $attr->{SELECT};
    my %extra_options = ('' => '--');
    %extra_options = %{$attr->{SEL_OPTIONS}} if $attr->{SEL_OPTIONS};

    if ($attr->{EX_PARAMS}) {
      %EX_PARAMS = (ref $attr->{EX_PARAMS} eq 'HASH') ? %{$attr->{EX_PARAMS}} : (EX_PARAMS => $attr->{EX_PARAMS});
    }

    if ($attr->{MAIN_MENU}) {
      $EX_PARAMS{MAIN_MENU} = get_function_index($attr->{MAIN_MENU});
      $EX_PARAMS{MAIN_MENU_ARGV} = "chg=" . ($attr->{$element_name} // $FORM{$element_name} || ''),
    }

    return $html->form_select($element_name, {
      SELECTED    => $attr->{$element_name} // $FORM{$element_name},
      SEL_HASH    => \%tp_list,
      SEL_OPTIONS => \%extra_options,
      NO_ID       => 1,
      SORT_KEY    => 1,
      %EX_PARAMS
    });
  }

  return \%tp_list;
}

#**********************************************************
=head get_services($user_info) - Get all user services and info

  Arguments:
    $user_info
      UID
      REDUCTION
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
          if ($attr->{ACTIVE_ONLY} && $status) {
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

#**********************************************************
=head2 sel_plugins($module, $attr) - Select available plugins for a module

  Arguments:
    $module - Name of the module to search for plugins
    $attr   - Extra attributes
       SELECT     - Flag to determine if HTML select should be returned; also serves as the name of the select element
       SELECT_ID  - ID for the HTML select element (optional)
       SELECTED   - Default selected plugin (optional)
       PLUGIN     - Plugin name to be selected by default (optional)
       EX_PARAMS  - Additional parameters for the HTML select element (optional)

  Returns:
   Hash reference of available plugins or HTML select element

  Example:

    # To get a hash reference of plugins
    my $plugins = sel_plugins('Iptv');

    # To get an HTML select element
    my $html_select = sel_plugins('Iptv', { SELECT => 'PLUGIN' });

=cut
#**********************************************************
sub sel_plugins {
  my $module = shift;
  my ($attr) = @_;

  return '' if !$module;

  my $plugins_folder = "$base_dir" . 'Abills/modules/' . $module . '/Plugins/';
  return '' if (!-d $plugins_folder);

  opendir(my $folder, $plugins_folder) or return '';
  my @plugin_files = grep(/\.pm$/, readdir($folder));
  closedir $folder;

  my %plugins_hash = map { $_ =~ /(.+)\.pm/; $1 => $1 } @plugin_files;
  return \%plugins_hash if !$attr->{SELECT};

  return $html->form_select($attr->{SELECT}, {
    ID          => $attr->{SELECT_ID} || (uc($module) . '_PLUGIN'),
    SELECTED    => $attr->{SELECTED} || $attr->{PLUGIN},
    SEL_HASH    => \%plugins_hash,
    SEL_OPTIONS => { '' => '--' },
    NO_ID       => 1,
    EX_PARAMS   => $attr->{EX_PARAMS}
      ? ((ref $attr->{EX_PARAMS} eq 'HASH')
        ? %{$attr->{EX_PARAMS}}
        : (EX_PARAMS => $attr->{EX_PARAMS}))
      : {},
  });
}

1;
