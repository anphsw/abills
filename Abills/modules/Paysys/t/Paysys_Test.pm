=head1 Paysys_Test

  Paysys_Base - module for payments
  DATE:11.06.2019

=cut

use strict;
use warnings;
use Abills::Fetcher qw/web_request/;

our (
  $admin,
  $db,
  %conf,
  %PAYSYS_PAYMENTS_METHODS,
  %lang,
  $base_dir
);

our Abills::HTML $html;

#**********************************************************
=head2 paysys_main_test()

=cut
#**********************************************************
sub paysys_main_test {

  my %debug_list = (
    '' => '',
    1  => 1,
    2  => 2,
    3  => 3,
    4  => 4,
    5  => 5,
    6  => 6,
    7  => 7,
    8  => 8,
    9  => 9);

  my $debug_select = q{};

  if (!$FORM{MODULE}) {
    $html->message("err", "No such payment system.");
    return 1;
  }
  elsif ($FORM{MODULE} !~ /^[A-za-z0-9\_]+\.pm$/) {
    $html->message('err', "Wrong module name.");
  }
  elsif (!$FORM{PAYSYSTEM_ID}) {
    $html->message('err', "There is not paysys system id.");
  }

  my $templates = q{};
  my $test_params = paysys_get_params({
    MODULE => $FORM{MODULE},
  });

  my $fn_index = get_function_index('paysys_test');

  foreach my $action (sort keys %{$test_params}) {
    my $inputs = q{};
    foreach my $request_key (sort keys %{$test_params->{$action}}) {
      next if ($request_key eq 'result' || $request_key eq 'result_type');
      my $ex_params = $test_params->{$action}{$request_key}{ex_params} || '';
      my $tooltip = $test_params->{$action}{$request_key}{tooltip} || '';
      my $type = $test_params->{$action}{$request_key}{type} || '';
      my $val = $test_params->{$action}{$request_key}{val} || '';

      my $input_form = $html->form_input($request_key, $val,
        { class     => 'form-control',
          TYPE      => $type,
          EX_PARAMS => "NAME='$request_key' $ex_params data-tooltip-position='bottom' data-tooltip='$tooltip'" });

      if ($request_key eq '_POST_') {
        $input_form = $html->form_textarea($request_key, $val,
          { class     => 'form-control',
            EX_PARAMS => "NAME='$request_key' $ex_params data-tooltip-position='bottom' data-tooltip='$tooltip'"
          });
      }

      my $input = $html->element('label', "$request_key: ", { class => 'col-md-3 control-label' })
        . $html->element('div',
        $input_form,
        { class => 'col-md-9' });

      $input = $html->element('div', $input, { class => 'form-group row' });
      $inputs .= $input;
    }

    $debug_select = $html->form_select(
      'DEBUG',
      {
        SELECTED => '',
        SEL_HASH => \%debug_list,
        NO_ID    => 1,
        ID       => $action
      }
    );

    $templates .= $html->tpl_show(_include('paysys_test_action', 'Paysys'), {
      INPUTS       => $inputs,
      INDEX        => $fn_index,
      MODULE       => $FORM{MODULE},
      ACTION       => $action,
      SELECT_DEBUG => $debug_select
    }, { OUTPUT2RETURN => 1 });
  }

  $debug_select = $html->form_select(
    'DEBUG',
    {
      SELECTED => '',
      SEL_HASH => \%debug_list,
      NO_ID    => 1,
    }
  );

  $templates = $html->tpl_show(_include('paysys_test_action', 'Paysys'), {
    INPUTS       => $html->form_textarea('ROW_TEST', $FORM{ROW_TEST}),
    INDEX        => $fn_index,
    MODULE       => $FORM{MODULE},
    ACTION       => 'ROW_TEST',
    SELECT_DEBUG => $debug_select
  }, { OUTPUT2RETURN => 1 }) . $templates;

  $html->tpl_show(_include('paysys_main_test', 'Paysys'), { FORMS => $templates });

  return 1;
}

#**********************************************************
=head2 paysys_test($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub paysys_test {
  if (!$FORM{module}) {
    print qq{NO_MODULE};
    return 1;
  }

  my $params = paysys_get_params({ MODULE => $FORM{module} });

  my $responce = q{};
  my $url = $conf{PAYSYS_TEST_URL} || qq{$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi?};
  my @request_params = ();
  my %request_params = ();

  if ($FORM{ROW_TEST}) {
    if ($FORM{ROW_TEST} =~ /\s=>\s/) {
      my @content = split(/\r?\n/, $FORM{ROW_TEST});
      foreach my $line (@content) {
        my ($param, $value) = split(/\s?=>\s?/, $line, 2);
        $value =~ s/[\r\n]+//g;
        push @request_params, "$param=$value";
      }
    }
    else {
      $request_params{POST} = $FORM{ROW_TEST};
    }
  }
  elsif ($FORM{_POST_}) {
    $request_params{POST} = $FORM{_POST_};
  }
  else {
    foreach my $key (sort keys %FORM) {
      next if (in_array($key, [ '__BUFFER', 'language', 'qindex', 'header', 'module', '_action', 'DEBUG' ]));
      next if (!$FORM{$key});
      push @request_params, "$key=$FORM{$key}";
    }
    if ($conf{PAYSYS_TEST_SYSTEM}) {
      push @request_params, "PAYSYS_TEST_SYSTEM=$FORM{module}";
    }
  }

  $url .= join('&', @request_params);

  $responce = Abills::Fetcher::web_request("$url", {
    INSECURE => 1,
    DEBUG    => $FORM{DEBUG},
    TIMEOUT  => 5,
    CURL     => 1,
    %request_params
  });

  if (!$responce) {
    $html->message('err', $lang{ERROR}, $lang{NO_DATA});
  }
  else {
    #return 0;
    if ($responce =~ /500 Internal Server Error/) {
      $responce = "paysys_check.cgi SCRIPT ERROR\n Check apache (Web server) log\n\n" . $responce;
    }
  }

  #my $params = paysys_get_params({ MODULE => $FORM{module} });
  #my $test_result = q{};

  if ($params->{$FORM{_action}}{result}) {
    foreach my $item (@{$params->{$FORM{_action}}{result}}) {
      if ($responce =~ /$item/) {
        $item =~ s/</&lt;/g;
        $item =~ s/>/&gt;/g;
        print $html->element('div', $html->element('strong',
          "Успешно! Результат правильный\n"),
          { class => 'alert alert-success' });
        #$test_result .= "$responce => $item / OK\n======\n";
      }
      else {
        $item =~ s/</&lt;/g;
        $item =~ s/>/&gt;/g;
        print $html->element('div', $html->element('strong',
          $lang{ERR_TRANSACTION_ERROR}),
          { class => 'alert alert-danger' });
        #$test_result .= "$responce => $item / ERROR\n======\n";
      }
    }
  }

  print $html->element('textarea', $responce, {
    name  => 'results',
    rows  => '10',
    class => 'form-control'
  });

  return 1;
}

#**********************************************************
=head2 paysys_get_params($attr)

  Arguments:
    $attr -
      MODULE
      NAME
      ID

  Returns:

=cut
#**********************************************************
sub paysys_get_params {
  my ($attr) = @_;

  my $module = $attr->{MODULE} || '';
  my $required_module = _configure_load_payment_module($module);

  my $Module = $required_module->new($db, $admin, \%conf, {
    CUSTOM_NAME => $attr->{NAME} || '',
    CUSTOM_ID   => $attr->{ID} || '',
    HTML        => $html
  });

  my $test_params = $Module->has_test(\%FORM);

  return $test_params;
}


1;