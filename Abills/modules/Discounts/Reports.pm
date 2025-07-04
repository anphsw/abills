=head1 NAME

  Reports

=cut

use warnings FATAL => 'all';
use strict;
use Discounts;

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html,
  $users,
  %FORM,
  $DATE,
);

my $Discounts = Discounts->new($db, $admin, \%conf);

my %MODULES = (
  ''         => $lang{ALL},
  'Triplay'  => 'Triplay',
  'Internet' => $lang{INTERNET},
  'Iptv'     => $lang{IPTV},
  'Voip'     => $lang{VOIP},
);

#**********************************************************
=head2 discounts_report () - show report with multidiscounts of users

=cut
# **********************************************************
sub discounts_report {

  my %discounts_status = (0 => $lang{ENABLE}, 1 => $lang{DISABLED});
  my %discounts_types = (1 => $lang{DISCOUNT_EXCLUSIVE}, 2 => $lang{DISCOUNT_PROMOTIONAL});
  my %report_types = (
    ADMINS         => $lang{ADMINS},
    PER_MONTH      => $lang{PER_MONTH},
  );

  require Control::Services;
  my $user_services = '';
  my %user_service_hash = ();
  $user_services = get_services($users, { MODULES => $Discounts->{MODULE} || $FORM{MODULE} });

  if ($user_services->{list}) {
    foreach my $service (@{$user_services->{list}}) {
      $user_service_hash{$service->{TP_ID}} = $service->{SERVICE_NAME}; # if ($service->{ID});
    }
  }

  my $tags_sel = '';
  if (in_array('Tags', \@MODULES)){
    load_module('Tags', $html);
    $tags_sel = tags_sel({ ID => 'TAGS_SEL' });
  }

  form_search({ TPL => $html->tpl_show(_include('discounts_report_search', 'Discounts'), {
    DATE_PICKER         => $html->form_daterangepicker({
      NAME         => 'FROM_DATE/TO_DATE',
      FORM_NAME    => 'discounts_date',
      VALUE        => $FORM{FROM_DATE_TO_DATE},
      RETURN_INPUT => 1
    }),
    REG_DATE_PICKER     => $html->form_daterangepicker({
      NAME         => 'FROM_REG_DATE/TO_REG_DATE',
      FORM_NAME    => 'discounts_reg_date',
      VALUE        => $FORM{FROM_REG_DATE_TO_REG_DATE},
      RETURN_INPUT => 1
    }),
    DATE_PICKER_CHECKED => $FORM{FROM_DATE_TO_DATE} ? 'checked' : '',
    REG_DATE_PICKER_CHECKED => $FORM{FROM_REG_DATE_TO_REG_DATE} ? 'checked' : '',
    SUM            => $FORM{SUM},
    PERCENT        => $FORM{PERCENT},
    REPORT_TYPE_SEL   => $html->form_select('REPORT_TYPE', {
      SELECTED    => ($FORM{REPORT_TYPE}) ? $FORM{REPORT_TYPE} : 'PER_MONTH',
      SEL_HASH    => \%report_types,
      SORT_KEY    => 1,
      NO_ID       => 1,
    }),
    STATUS_SEL          => $html->form_select('STATUS', {
      SELECTED    => (defined($FORM{STATUS})) ? $FORM{STATUS} : '',
      SEL_OPTIONS => { '' => '' },
      SEL_HASH    => \%discounts_status,
      SORT_KEY    => 1,
      NO_ID       => 1,
    }),
    DISCOUNT_TYPE_SEL  => $html->form_select('TYPE', {
      SELECTED    => $FORM{TYPE} || '',
      SEL_OPTIONS => { '' => '' },
      SEL_HASH    => \%discounts_types,
      SORT_KEY    => 1,
      NO_ID       => 1,
    }),
    ADMIN_SEL     => sel_admins({ SELECTED => $FORM{AID} }),
    GROUP_SEL     => sel_groups({ GID => $FORM{GID} || '', MULTISELECT => 1 }),
    ADDRESS_TPL   => form_address(),
    TAGS_SEL      => $tags_sel,
  }, { OUTPUT2RETURN => 1 }) });

  my $report_type = $FORM{REPORT_TYPE} || 'PER_MONTH';

  if ($FORM{FROM_DATE_TO_DATE}) {
    ($LIST_PARAMS{FROM_DATE}, $LIST_PARAMS{TO_DATE}) = split('/', $FORM{FROM_DATE_TO_DATE});
    $LIST_PARAMS{FROM_DATE} = ">=$LIST_PARAMS{FROM_DATE}";
    $LIST_PARAMS{TO_DATE} = "<=$LIST_PARAMS{TO_DATE}";
  }
  if ($FORM{FROM_REG_DATE_TO_REG_DATE}) {
    ($LIST_PARAMS{FROM_REG_DATE}, $LIST_PARAMS{TO_REG_DATE}) = split('/', $FORM{FROM_REG_DATE_TO_REG_DATE});
    $LIST_PARAMS{FROM_REG_DATE} = "$LIST_PARAMS{FROM_REG_DATE}";
    $LIST_PARAMS{TO_REG_DATE} = "$LIST_PARAMS{TO_REG_DATE}";
  }
  $LIST_PARAMS{PAGE_ROWS} = (defined($FORM{PAGE_ROWS})) ? $FORM{PAGE_ROWS} : 1000;
  $LIST_PARAMS{REPORT_TYPE} = $report_type;
  $LIST_PARAMS{GID} =~ s/,/;/g if $FORM{GID};
  $LIST_PARAMS{TAGS} =~ s/,/;/g if $FORM{TAGS};

  my %ext_titles = (
    'PER_MONTH'     => {
      id           => 'ID',
      module       => $lang{MODULE},
      tp_id        => $lang{TARIF_PLAN},
      percent      => $lang{PERCENT},
      sum          => $lang{SUM},
      from_date    => "$lang{DATE} $lang{FROM}",
      to_date      => "$lang{DATE} $lang{TO}",
      status       => $lang{STATUS},
      type         => $lang{TYPE},
      reg_date     => $lang{DATE_OF_CREATION},
      login        => $lang{LOGIN},
      a_name       => "$lang{ADMIN} $lang{FIO}",
      tags_name    => $lang{TAGS},
      gid_name     => $lang{GROUP},
      address_full => $lang{ADDRESS},
    },
    'ADMINS'         => {
      month           => $lang{MONTH},
      a_login         => "$lang{ADMIN} $lang{LOGIN}",
      a_name          => "$lang{ADMIN} $lang{FIO}",
      count_discounts => $lang{DISCOUNTS_QUANTITY},
      tags_name      => $lang{TAGS},
      gid_name       => $lang{GROUP},
      status         => $lang{STATUS},
      type           => $lang{TYPE},
    },
  );


  my $hidden_fields = 'UID,DISTRICT_ID,STREET_ID,BUILD_ID,TAG_ID,GID,AID';
  my $fields = 'ID,MODULE,PERCENT,SUM,FROM_DATE,TO_DATE,TYPE,STATUS,TP_ID,LOGIN,A_NAME,ADDRESS_FULL,GID,TAGS';

  if ($FORM{REPORT_TYPE} && $FORM{REPORT_TYPE} eq 'ADMINS'){
    $fields = 'MONTH,A_LOGIN,A_NAME,COUNT_DISCOUNTS';
    $hidden_fields = '';
  }

  _discounts_report_chart(\%FORM);

  result_former({
    INPUT_DATA      => $Discounts,
    FUNCTION        => 'reports',
    FUNCTION_INDEX  => $index,
    DEFAULT_FIELDS  => $fields,
    HIDDEN_FIELDS   => $hidden_fields,
    SKIP_USER_TITLE => 1,
    FILTER_VALUES   => {
      status => sub {
        my $status_id = shift;
        return ((defined($status_id)) ? $discounts_status{$status_id} : '');
      },
      type   => sub {
        my $type_id = shift;
        return ((defined($type_id)) ? $discounts_types{$type_id} : '');
      },
      module => sub {
        my $module = shift;
        return (($module) ? $MODULES{$module} : '');
      },
      tp_id  => sub {
        my $tp_id = shift;
        return (($tp_id) ? $user_service_hash{$tp_id} : '');
      },
      login  => sub {
        my (undef, $line) = @_;
        return (($line->{login}) ? $html->b($html->button( ($line->{login} || $line->{uid}), "index=11&UID=$line->{uid}") ) : '');
      },
    },
    EXT_TITLES      => $ext_titles{$report_type},
    TABLE           => {
      width   => '100%',
      caption => $lang{DISCOUNTS},
      qs      => $pages_qs,
      ID      => 'REPORT_DISCOUNTS_LIST',
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1,
  });

  return 1;
}


#**********************************************************
=head2 _discounts_report_chart () - discounts chart

=cut
# **********************************************************
sub _discounts_report_chart {
  my ($attr) = @_;
  $attr->{COLS_NAME} =1;

  my $report_chart = $Discounts->report_chart($attr);
  my @labels_chart = ();
  my @data_chart = ();

  foreach my $line (@$report_chart) {
    push @labels_chart, $line->{month};
    push @data_chart, $line->{quantity};
  }

  print $html->chart({
    TYPE              => 'bar',
    X_LABELS          => \@labels_chart,
    DATA              => {
      $lang{DISCOUNTS_QUANTITY} => \@data_chart,
    },
    BACKGROUND_COLORS => {
      $lang{DISCOUNTS_QUANTITY} => 'rgba(34, 187, 51, 0.8)',
    },
    FILL              => 'false',
    OUTPUT2RETURN     => 1,
    IN_CONTAINER      => 1
  });

}


1;