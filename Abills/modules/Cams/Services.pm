=head1 NAME

  Cams services

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Filters qw(_utf8_encode);
use Abills::Base qw(_bp);
use Cams;

our (
  $html,
  %lang,
  $db,
  $admin,
  %conf,
  %FORM,
  $pages_qs,
  $index
);

my $Cams = Cams->new($db, $admin, \%conf);

#**********************************************************
=head2 cams_services($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub cams_services {

  $Cams->{ACTION} = 'add';
  $Cams->{LNG_ACTION} = $lang{ADD};

  if ($FORM{extra_params}) {
    _service_extra_params();
    return 1;
  }
  elsif ($FORM{add}) {
    $Cams->services_add({ %FORM });
    if (!$Cams->{errno}) {
      $html->message('info', $lang{SCREENS}, $lang{ADDED});
      cams_service_info($Cams->{INSERT_ID});
    }
  }
  elsif ($FORM{change}) {
    $Cams->services_change(\%FORM);
    if (!_error_show($Cams)) {
      $html->message('info', $lang{SCREENS}, $lang{CHANGED});
      cams_service_info($FORM{ID});
    }
  }
  elsif ($FORM{chg}) {
    cams_service_info($FORM{chg});
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Cams->services_del($FORM{del});
    if (!$Cams->{errno}) {
      $html->message('info', $lang{SCREENS}, $lang{DELETED});
    }
  }
  _error_show($Cams);

  $Cams->{USER_PORTAL_SEL} = $html->form_select(
    'USER_PORTAL',
    {
      SELECTED => $Cams->{USER_PORTAL} || $FORM{USER_PORTAL} || 0,
      SEL_HASH => {
        0 => '--',
        1 => $lang{INFO},
        2 => $lang{CONTROL} || 'Control'
      },
      NO_ID    => 1
    }
  );

  $Cams->{DEBUG_SEL} = $html->form_select(
    'DEBUG',
    {
      SELECTED  => $Cams->{DEBUG} || $FORM{DEBUG} || 0,
      SEL_ARRAY => [ 0, 1, 2, 3, 4, 5, 6, 7 ],
    }
  );

  $html->tpl_show(_include('cams_services_add', 'Cams'), { %FORM, %$Cams });

  result_former({
    INPUT_DATA        => $Cams,
    FUNCTION          => 'services_list',
    DEFAULT_FIELDS    => 'NAME,MODULE,STATUS,COMMENT,LOGIN',
    FUNCTION_FIELDS   => 'change,del',
    EXT_TITLES        => {
      name    => $lang{NAME},
      module  => 'Plug-in',
      status  => $lang{STATUS},
      comment => $lang{COMMENTS},
    },
    SKIP_USERS_FIELDS => 1,
    TABLE             => {
      width   => '100%',
      caption => "$lang{CAMERAS} $lang{SERVICES}",
      qs      => $pages_qs,
      ID      => 'CAMS SERVICES',
      MENU    => "$lang{ADD}:index=" . get_function_index('cams_services') . "&add_form=1:add"
    },
    MAKE_ROWS         => 1,
    TOTAL             => 1,
  });

  return 1;
}

#**********************************************************
=head2 cams_service_info($id)

  Arguments:
    $id

  Results:

=cut
#**********************************************************
sub cams_service_info {
  my ($id, $attr) = @_;

  $Cams->services_info($id);
  if (!$Cams->{errno}) {
    $FORM{add_form} = 1;
    $Cams->{ACTION} = 'change';
    $Cams->{LNG_ACTION} = $lang{CHANGE};
    $html->message('info', $lang{SCREENS}, $lang{CHANGING});

    if ($Cams->{MODULE}) {
      my $Cams_service = cams_load_service($Cams->{MODULE}, { SERVICE_ID => $Cams->{ID}, SOFT_EXCEPTION => 1 });
      if ($Cams_service && $Cams_service->{VERSION}) {
        $Cams->{MODULE_VERSION} = $Cams_service->{VERSION};
      }

      if ($Cams_service && $Cams_service->can('test')) {
        if ($FORM{test}) {
          my $result = $Cams_service->test();
          if (!$Cams_service->{errno}) {
            $html->message('info', $lang{INFO}, "$lang{TEST}\n$result");
          }
          else {
            _error_show($Cams_service, { MESSAGE => 'Test:' });
          }
        }

        $Cams->{SERVICE_TEST} = $html->button($lang{TEST}, "index=$index&test=1&chg=$Cams->{ID}",
          { class => 'btn btn-default btn-info' });
      }
    }
  }

  $Cams->{USER_PORTAL} = ($Cams->{USER_PORTAL}) ? 'checked' : '';
  $Cams->{STATUS} = ($Cams->{STATUS}) ? 'checked' : '';

  return 1;
}

#**********************************************************
=head2 cams_load_service($service_name, $attr) - Load service module

  Argumnets:
    $service_name  - service modules name
    $attr
       SERVICE_ID
       SOFT_EXCEPTION

  Returns:
    Module object

=cut
#**********************************************************
sub cams_load_service {
  my ($service_name, $attr) = @_;
  my $api_object;

  my $Cams_service = Cams->new($db, $admin, \%conf);
  if ($attr->{SERVICE_ID}) {
    $Cams_service->services_info($attr->{SERVICE_ID});
    $service_name = $Cams_service->{MODULE} || q{};
  }

  if (!$service_name) {
    return $api_object;
  }

  $service_name = 'Cams::' . $service_name;

  eval " require $service_name; ";
  if (!$@) {
    $service_name->import();

    if ($service_name->can('new')) {
      $api_object = $service_name->new($Cams->{db}, $Cams->{admin}, $Cams->{conf}, {
        %$Cams_service,
      });
    }
    else {
      $html->message('err', $lang{ERROR}, "Can't load '$service_name'. Purchase this module http://abills.net.ua");
      return $api_object;
    }
  }
  else {
    print $@ if ($FORM{DEBUG});
    $html->message('err', $lang{ERROR}, "Can't load '$service_name'. Purchase this module http://abills.net.ua");
    if (!$attr->{SOFT_EXCEPTION}) {
      die "Can't load '$service_name'. Purchase this module http://abills.net.ua";
    }
  }

  return $api_object;
}

#**********************************************************
=head2 cams_services_sel($attr)

  Arguments:
     SERVICE_ID
     FORM_ROW
     USER_PORTAL
     HASH_RESULT
     ALL
     SKIP_DEF_SERVICE
     UNKNOWN

  Returns:

=cut
#**********************************************************
sub cams_services_sel {
  my ($attr) = @_;

  my %params = ();

  if ($attr->{ALL} || $FORM{search_form}) {
    $params{SEL_OPTIONS} = { '' => $lang{ALL} };
  }

  if ($attr->{UNKNOWN}) {
    $params{SEL_OPTIONS}->{0} = $lang{UNKNOWN};
  }

  my $active_service = $attr->{SERVICE_ID} || $FORM{SERVICE_ID};

  my $service_list = $Cams->services_list({
    STATUS      => 0,
    NAME        => '_SHOW',
    USER_PORTAL => $attr->{USER_PORTAL},
    COLS_NAME   => 1,
    PAGE_ROWS   => 1
  });

  if ($attr->{HASH_RESULT}) {
    my %service_name = ();

    foreach my $line (@$service_list) {
      $service_name{$line->{id}} = $line->{name};
    }

    return \%service_name;
  }

  if ($Cams->{TOTAL} && $Cams->{TOTAL} == 1) {
    delete $params{SEL_OPTIONS};
    $Cams->{SERVICE_ID} = $service_list->[0]->{id};
  }

  my $result = $html->form_select(
    'SERVICE_ID',
    {
      SELECTED       => $active_service,
      SEL_LIST       => $service_list,
      EX_PARAMS      => "onchange='autoReload()'",
      MAIN_MENU      => get_function_index('cams_services'),
      MAIN_MENU_ARGV => ($active_service) ? "chg=$active_service" : q{},
      %params
    }
  );

  if (!$active_service && $service_list->[0] && !$FORM{search_form} && !$attr->{SKIP_DEF_SERVICE}) {
    $FORM{SERVICE_ID} = $service_list->[0]->{id};
  }

  if ($attr->{FORM_ROW}) {
    $result = $html->tpl_show(templates('form_row'), {
      ID    => 'SERVICE_ID',
      NAME  => $lang{SERVICE},
      VALUE => $result
    }, { OUTPUT2RETURN => 1 });
  }

  return $result;
}

#**********************************************************
=head2 cams_tariffs_sel($attr)

  Arguments:
     SERVICE_ID
     FORM_ROW
     USER_PORTAL
     HASH_RESULT
     ALL
     SKIP_DEF_SERVICE
     UNKNOWN

  Returns:

=cut
#**********************************************************
sub cams_tariffs_sel {
  my ($attr) = @_;

  my %params = ();

  if ($attr->{ALL} || $FORM{search_form}) {
    $params{SEL_OPTIONS} = { '' => $lang{ALL} };
  }

  if ($attr->{UNKNOWN}) {
    $params{SEL_OPTIONS}->{0} = $lang{UNKNOWN};
  }

  my $active_tariff = $attr->{TP_ID} || $FORM{TP_ID};

  my $tariffs = $Cams->_list({
    ID           => '_SHOW',
    TP_ID        => '_SHOW',
    TP_NAME      => '_SHOW',
    SERVICE_NAME => '_SHOW',
    TARIFF_ID    => '_SHOW',
    UID          => $attr->{UID},
    STATUS       => 0,
    SERVICE_ID   => '_SHOW',
    COLS_NAME    => 1,
    PAGE_ROWS    => 1
  });

  if ($attr->{HASH_RESULT}) {
    my %tariff_name = ();

    foreach my $line (@$tariffs) {
      $tariff_name{$line->{id}} = $line->{name};
    }

    return \%tariff_name;
  }

  if ($Cams->{TOTAL} && $Cams->{TOTAL} == 1) {
    delete $params{SEL_OPTIONS};
    $Cams->{TP_ID} = $tariffs->[0]->{id};
  }

  my $result = $html->form_select('TP_ID', {
    SELECTED       => $active_tariff,
    SEL_LIST       => $tariffs,
    EX_PARAMS      => "onchange='autoReload()'",
    SEL_VALUE      => 'service_name,tp_name',
    SEL_KEY        => 'tariff_id',
    NO_ID          => 1,
    MAIN_MENU      => get_function_index("cams_tp"),
    MAIN_MENU_ARGV => ($active_tariff) ? "chg=$active_tariff" : q{},
    %params
  });

  if (!$active_tariff && $tariffs->[0] && !$FORM{search_form} && !$attr->{SKIP_DEF_SERVICE}) {
    $FORM{SERVICE_ID} = $tariffs->[0]->{id};
  }

  return $result;
}

1;