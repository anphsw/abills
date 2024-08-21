use strict;
use warnings FATAL => 'all';

=head1 NAME

  Power::Reports - power reports

=cut

our (
  $html,
  %lang,
  %conf,
  $admin,
  $db,
  %permissions,
  $libpath,
  %LIST_PARAMS
);

require Control::Reports;
require Abills::Template;
my $Templates = Abills::Template->new($db, $admin, \%conf, { html => $html, lang => \%lang, libpath => $libpath });

use Power::db::Power;
my $Power = Power::db::Power->new($db, $admin, \%conf);

#***********************************************************
=head2 power_refuels_report()

=cut
#***********************************************************
sub power_refuels_report {

  reports({
    PERIOD_FORM       => 1,
    DATE_RANGE        => 1,
    NO_GROUP          => 1,
    NO_TAGS           => 1,
    NO_MULTI_GROUP    => 1,
    NO_STANDART_TYPES => 1,
    EXT_SELECT        => {
      GENSET_ID => { LABEL => $lang{POWER_GENERATOR}, SELECT => _gensets_sel(\%FORM) },
    }
  });

  $LIST_PARAMS{GENSET_ID} = $FORM{GENSET_ID} if $FORM{GENSET_ID};

  result_former({
    INPUT_DATA      => $Power,
    FUNCTION        => 'power_genset_refuels_list',
    DEFAULT_FIELDS  => 'ID,ADDRESS_FULL,DATE,LITRES,LITRES_BEFORE,LITRES_AFTER,TYPE,GENSET_LITRES',
    HIDDEN_FIELDS   => 'GENSET_ID',
    FILTER_VALUES   => {
      litres_after => sub { return shift || '0'; },
      litres_before => sub { return shift || '0'; }
    },
    EXT_TITLES      => {
      id            => '#',
      date          => $lang{DATE},
      litres        => $lang{POWER_FILLED},
      litres_before => $lang{POWER_WAS},
      litres_after  => $lang{POWER_BECAME},
      genset_litres => $lang{POWER_CAPACITY},
      address_full  => $lang{ADDRESS},
      type          => $lang{POWER_GENERATOR_TYPE},
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => $lang{POWER_REFUELING_GENERATORS},
      qs      => $pages_qs,
      ID      => 'power_genset_refuels_list'
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });
}

#***********************************************************
=head2 power_runs_report()

=cut
#***********************************************************
sub power_runs_report {

  reports({
    PERIOD_FORM       => 1,
    DATE_RANGE        => 1,
    NO_GROUP          => 1,
    NO_TAGS           => 1,
    NO_MULTI_GROUP    => 1,
    NO_STANDART_TYPES => 1,
    EXT_SELECT        => {
      GENSET_ID => { LABEL => $lang{POWER_GENERATOR}, SELECT => _gensets_sel(\%FORM) },
    }
  });

  $LIST_PARAMS{GENSET_ID} = $FORM{GENSET_ID} if $FORM{GENSET_ID};

  result_former({
    INPUT_DATA      => $Power,
    FUNCTION        => 'power_genset_runs_list',
    DEFAULT_FIELDS  => 'ID,ADDRESS_FULL,START_DATE,STOP_DATE,TYPE_ID,RESULT,TYPE',
    HIDDEN_FIELDS   => 'STATE,GENSET_ID',
    FILTER_VALUES   => {
      type_id   => sub {
        my $type_id = shift;
        return $type_id ? $lang{POWER_ELECTRICAL_NETWORK_FAILURE} : $lang{TEST}
      },
      result    => sub {
        my $result = shift;
        return $result ? $lang{POWER_DID_NOT_START} : $lang{POWER_STARTED}
      },
      stop_date => sub {
        my ($stop_date, $line) = @_;

        return !$line->{result} && $line->{state} && $stop_date && $stop_date eq '0000-00-00 00:00:00' ? 'Працює зараз' : $stop_date;
      }
    },
    EXT_TITLES      => {
      id           => '#',
      start_date   => $lang{POWER_START_DATE},
      stop_date    => $lang{POWER_STOP_DATE},
      type_id      => $lang{POWER_START_TYPE},
      result       => $lang{POWER_RESULT},
      address_full => $lang{ADDRESS},
      type         => $lang{POWER_GENERATOR_TYPE},
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => $lang{POWER_GENERATOR_STARTS},
      qs      => $pages_qs,
      ID      => 'power_genset_runs_list'
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });
}

#***********************************************************
=head2 power_services_report()

=cut
#***********************************************************
sub power_services_report {

  my $service_types = $Power->power_service_types_list({
    NAME      => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 100000
  });
  map $_->{name} = _translate($_->{name}), @{$service_types};

  reports({
    PERIOD_FORM       => 1,
    DATE_RANGE        => 1,
    NO_GROUP          => 1,
    NO_TAGS           => 1,
    NO_MULTI_GROUP    => 1,
    NO_STANDART_TYPES => 1,
    EXT_SELECT        => {
      GENSET_ID       => { LABEL => $lang{POWER_GENERATOR}, SELECT => _gensets_sel(\%FORM) },
      SERVICE_TYPE_ID => {
        LABEL  => $lang{POWER_SERVICE_TYPES},
        SELECT => $html->form_select('SERVICE_TYPE_ID', {
          SELECTED     => $FORM{SERVICE_TYPE_ID},
          SEL_LIST     => $service_types,
          SEL_VALUE    => 'name',
          SEL_KEY      => 'id',
          SORT_KEY_NUM => 1,
          NO_ID        => 1,
          SEL_OPTIONS  => { '' => '--' },
        }) },
    }
  });

  $LIST_PARAMS{GENSET_ID} = $FORM{GENSET_ID} if $FORM{GENSET_ID};
  $LIST_PARAMS{SERVICE_TYPE_ID} = $FORM{SERVICE_TYPE_ID} if $FORM{SERVICE_TYPE_ID};

  result_former({
    INPUT_DATA      => $Power,
    FUNCTION        => 'power_genset_services_list',
    DEFAULT_FIELDS  => 'ID,ADDRESS_FULL,SERVICE_DATE,SERVICE_NAME,DESCRIPTION,TYPE',
    HIDDEN_FIELDS   => 'SERVICE_TYPE_ID,GENSET_ID',
    EXT_TITLES      => {
      id           => '#',
      service_name => $lang{POWER_SERVICE_NAME},
      service_date => $lang{DATE},
      description  => $lang{DESCRIBE},
      type         => $lang{POWER_GENERATOR_TYPE},
      address_full => $lang{ADDRESS}
    },
    FILTER_COLS     => { service_name => '_translate' },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => $lang{POWER_GENERATOR_MAINTENANCE},
      qs      => $pages_qs,
      ID      => 'power_genset_services_list'
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });
}

#***********************************************************
=head2 _gensets_sel($attr)

=cut
#***********************************************************
sub _gensets_sel {
  my ($attr) = @_;

  return $html->form_select('GENSET_ID', {
    SEL_LIST     => $Power->power_gensets_list({
      ADDRESS_FULL => '_SHOW',
      TYPE         => '_SHOW',
      COLS_NAME    => 1,
      PAGE_ROWS    => 100000
    }),
    SELECTED     => $attr->{GENSET_ID},
    SEL_VALUE    => 'address_full,type',
    SEL_KEY      => 'id',
    SORT_KEY_NUM => 1,
    NO_ID        => 1,
    SEL_OPTIONS  => { '' => '--' }
  });
}

1;