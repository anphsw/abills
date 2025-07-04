=head1 NAME

  billd plugin - Rwizard info plugin

=head1 DESCRIPTION

  This plugin processes reports through the Rwizard system and handles events
  via dynamically loaded plugins.

=cut

use strict;
use warnings;

our (
  $db,
  $Admin,
  %conf,
  %lang,
  $debug,
  $var_dir,
  $base_dir
);

do "$base_dir/Abills/modules/Rwizard/lng_$conf{default_language}.pl";

use Reports;
use Abills::Base qw(load_pmodule in_array _bp);
use Abills::Loader qw(load_plugin);

my $PLUGIN_EXTENSION = '.pm';

my $Reports = Reports->new($db, $Admin, \%conf);

rwizard_info();

#**********************************************************
=head2 rwizard_info()

=cut
#**********************************************************
sub rwizard_info {

  my $reports = $Reports->list({
    COLS_NAME => 1,
    PAGE_ROWS => 10000
  });

  return '' if (!$Reports->{TOTAL} || $Reports->{TOTAL} < 1);

  my $plugins_folder = "$base_dir" . 'Abills/modules/Rwizard/Plugins/';
  return '' if (!-d $plugins_folder);

  opendir(my $folder, $plugins_folder) or return '';
  my @plugin_files = grep { /$PLUGIN_EXTENSION$/x } readdir($folder);
  closedir $folder;

  return '' if (!@plugin_files);

  my @loaded_plugins;
  foreach my $plugin_file (@plugin_files) {
    my ($plugin_name) = split(/\./, $plugin_file);
    my $plugin_class = "Rwizard::Plugins::$plugin_name";

    my $plugin = load_plugin($plugin_class, {
      SERVICE => $Reports,
      LANG    => \%lang
    });

    if ($plugin && $plugin->can('billd_handle_event')) {
      push @loaded_plugins, $plugin;
    }
  }

  return '' if (!@loaded_plugins);

  foreach my $report (@{$reports}) {
    if (!$report || !$report->{id}) {
      next;
    }

    my $report_info = $Reports->info({ ID => $report->{id} });
    if (!$report_info) {
      next;
    }

    _rwizard_fill_report_query_vars();

    my $list = $Reports->mk({
      QUERY       => $Reports->{QUERY},
      QUERY_TOTAL => $Reports->{QUERY_TOTAL},
      COLS_NAME   => 1
    });

    if (!$list) {
      next;
    }

    foreach my $plugin (@loaded_plugins) {
      $plugin->billd_handle_event($report_info, $list);
    }
  }

  return 1;
}

#**********************************************************
=head2 _rwizard_fill_report_query_vars($attr)

=cut
#**********************************************************
sub _rwizard_fill_report_query_vars {
  my ($attr) = @_;
  $attr = {} if (!defined $attr);

  $Reports->{QUERY_TOTAL} = '' if (!defined $Reports->{QUERY_TOTAL});

  if ($Reports->{QUERY} =~ m/%DATE_FROM%/x) {
    my $month = $attr->{MONTH} || ($DATE =~ m/^(\d+\-\d+)/x)[0] || '';
    my $date_from = $attr->{DATE_FROM} || $month . '-01';
    my $date_to = $attr->{DATE_TO} || $DATE || '';

    $Reports->{QUERY} =~ s/%DATE_FROM%/$date_from/xg;
    $Reports->{QUERY} =~ s/%DATE_TO%/$date_to/xg;
    $Reports->{QUERY_TOTAL} =~ s/%DATE_FROM%/$date_from/xg;
    $Reports->{QUERY_TOTAL} =~ s/%DATE_TO%/$date_to/xg;
    $Reports->{QUERY} =~ s/%MONTH%/$month/xg;
    $Reports->{QUERY_TOTAL} =~ s/%MONTH%/$month/xg;
  }

  if ($Reports->{QUERY} =~ m/%DOMAIN_ID%/x) {
    my $domain = $Admin->{DOMAIN_ID} || 0;
    $Reports->{QUERY} =~ s/%DOMAIN_ID%/$domain/xg;
    $Reports->{QUERY_TOTAL} =~ s/%DOMAIN_ID%/$domain/xg;
  }

  if ($Reports->{QUERY} =~ m/%GID%/xg) {
    if (!defined($attr->{GID}) || $attr->{GID} eq '' || $attr->{GID} eq '*') {
      $Reports->{QUERY} =~ s/[and]{0,3}\s+[a-z0-9\.\_]+\s?\=\s?\'?%GID%\'?//xig;
      $Reports->{QUERY_TOTAL} =~ s/[and]{0,3}\s+[a-z0-9\.\_]+\s?\=\s?\'?%GID%\'?//xig;
    }
    else {
      if ($attr->{GID} =~ m/,\s?/x) {
        $Reports->{QUERY} =~ s/([a-z0-9\.\_]+)\s?\=\s?\'?%GID%\'?/$1 IN ($attr->{GID})/xig;
        $Reports->{QUERY_TOTAL} =~ s/([a-z0-9\.\_]+)\s?\=\s?\'?%GID%\'?/$1 IN ($attr->{GID})/xig;
      }
      else {
        $Reports->{QUERY} =~ s/%GID%/$attr->{GID}/xg;
        $Reports->{QUERY_TOTAL} =~ s/%GID%/$attr->{GID}/xg;
      }
    }
  }

  if ($Reports->{QUERY} =~ m/%ADMIN_ID%/x) {
    if (!defined($attr->{ADMIN_ID}) || $attr->{ADMIN_ID} eq '') {
      $Reports->{QUERY} =~ s/[and]{0,3}\s+[a-z0-9\.\_]+\s?\=\s?\'?%ADMIN_ID%\'?//xig;
      $Reports->{QUERY_TOTAL} =~ s/[and]{0,3}\s+[a-z0-9\.\_]+\s?\=\s?\'?%ADMIN_ID%\'?//xig;
    }
    else {
      if ($attr->{ADMIN_ID} =~ m/,\s?/x) {
        $Reports->{QUERY} =~ s/([a-z0-9\.\_]+)\s?\=\s?\'?%ADMIN_ID%\'?/$1 IN ($attr->{ADMIN_ID})/xig;
        $Reports->{QUERY_TOTAL} =~ s/([a-z0-9\.\_]+)\s?\=\s?\'?%ADMIN_ID%\'?/$1 IN ($attr->{ADMIN_ID})/xig;
      }
      else {
        $Reports->{QUERY} =~ s/%ADMIN_ID%/$attr->{ADMIN_ID}/xg;
        $Reports->{QUERY_TOTAL} =~ s/%ADMIN_ID%/$attr->{ADMIN_ID}/xg;
      }
    }
  }

  if ($Reports->{QUERY} =~ m/%UID%/x) {
    if (!defined($attr->{UID}) || $attr->{UID} eq '') {
      $Reports->{QUERY} =~ s/[and]{0,3} [a-z0-9\.\_]+\s?\=\s?\'?%UID%\'?//xig;
      $Reports->{QUERY_TOTAL} =~ s/[and]{0,3} [a-z0-9\.\_]+\s?\=\s?\'?%UID%\'?//xig;
    }
    else {
      $Reports->{QUERY} =~ s/%UID%/$attr->{UID}/xg;
      $Reports->{QUERY_TOTAL} =~ s/%UID%/$attr->{UID}/xg;
    }
  }

  my @params_array = ('DEPOSIT', 'PARAMETER');
  foreach my $param_name (@params_array) {
    my $params_expr = '\%' . $param_name . ':?([\S]{0,12})\%';
    if ($Reports->{QUERY} =~ m/$params_expr/xg) {
      my $default_parameters_value = $1 || '';
      if ($attr->{$param_name}) {
        $default_parameters_value = $attr->{$param_name};
      }

      if (!defined($attr->{$param_name}) || $attr->{$param_name} eq '') {
        $Reports->{QUERY} =~ s/[and]{0,3} [a-z0-9\.\_]+\=\'?$params_expr\'?//xig;
        $Reports->{QUERY_TOTAL} =~ s/[and]{0,3} [a-z0-9\.\_]+\=\'?$params_expr\'?//xig;

        $Reports->{QUERY} =~ s/$params_expr/$default_parameters_value/xig;
        $Reports->{QUERY_TOTAL} =~ s/$params_expr/$default_parameters_value/xig;
      }
      else {
        my $prefix = '=';
        if ($attr->{$param_name} && $attr->{$param_name} =~ s/([<=>]+)//xg) {
          $prefix = $1;
        }

        $Reports->{QUERY} =~ s/[=<>]{1}\s?\'?$params_expr\'?/$prefix'$attr->{$param_name}'/xg;
        $Reports->{QUERY_TOTAL} =~ s/[=<>]{1}\s?\'?$params_expr\'?/$prefix'$attr->{$param_name}'/xg;

        $Reports->{QUERY} =~ s/$params_expr/$default_parameters_value/xig;
        $Reports->{QUERY_TOTAL} =~ s/$params_expr/$default_parameters_value/xig;

        delete $attr->{$param_name};
      }
    }
  }

  if ($Reports->{QUERY} =~ m/%ADDRESS%/xg) {
    if (defined($attr->{ADDRESS_DISTRICT}) && $attr->{ADDRESS_DISTRICT} eq '') {
      $Reports->{QUERY} =~ s/\%ADDRESS\%//xig;
      $Reports->{QUERY_TOTAL} =~ s/\%ADDRESS\%//xig;
    }
    else {
      if (defined($attr->{DEPOSIT}) && $attr->{DEPOSIT} eq '') {
        delete $attr->{DEPOSIT};
      }

      my $ADDRESS_QUERY = '';
      my $where_result = $Reports->search_expr_users($attr);
      if ($where_result && $#{$where_result} > -1) {
        $ADDRESS_QUERY = ' AND ' . join(' and ', @$where_result);
      }
      $Reports->{QUERY} =~ s/%ADDRESS%/$ADDRESS_QUERY/xg;
      $Reports->{QUERY_TOTAL} =~ s/%ADDRESS%/$ADDRESS_QUERY/xg;
    }
  }

  if ($Reports->{QUERY} =~ m/%PAYMENT_METHODS%/x) {
    if (!defined($attr->{PAYMENT_METHODS}) || $attr->{PAYMENT_METHODS} eq '') {
      $Reports->{QUERY} =~ s/[and]{0,3} [a-z0-9\.\_]+\=\'%PAYMENT_METHODS%\'//xig;
      $Reports->{QUERY_TOTAL} =~ s/[and]{0,3} [a-z0-9\.\_]+\=\'%PAYMENT_METHODS%\'//xig;
    }
    else {
      $Reports->{QUERY} =~ s/%PAYMENT_METHODS%/$attr->{PAYMENT_METHODS}/xg;
      $Reports->{QUERY_TOTAL} =~ s/%PAYMENT_METHODS%/$attr->{PAYMENT_METHODS}/xg;
    }
  }

  if ($Reports->{QUERY} =~ m/%BUILDS_LIST%/xg) {
    my $build_query = $attr->{BUILD_ID} ?
      "pi.location_id IN ($attr->{BUILD_ID})" :
      "pi.location_id IS NOT NULL";

    $Reports->{QUERY} =~ s/%BUILDS_LIST%/$build_query/xg;
    $Reports->{QUERY_TOTAL} =~ s/%BUILDS_LIST%/$build_query/xg;
  }

  $Reports->{QUERY} =~ s/WHERE\s+AND\s+/WHERE /xig;
  $Reports->{QUERY_TOTAL} = "" if (!defined $Reports->{QUERY_TOTAL});
  $Reports->{QUERY_TOTAL} =~ s/WHERE\s+AND\s+/WHERE /xig;
  $Reports->{QUERY_TOTAL} =~ s/^[\n\r]+$//xg;

  $Reports->{QUERY} =~ s/\bWHERE\s*$//xi;
  $Reports->{QUERY_TOTAL} =~ s/\bWHERE\s*$//xi;

  return 1;
}

1;