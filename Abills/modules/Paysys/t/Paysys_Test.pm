=head1 Paysys_Test

  Paysys_Base - module for payments
  DATE:11.06.2019

=cut

use strict;
use warnings;
use Abills::Base;
use Abills::Fetcher qw/web_request/;

our (
  $admin,
  $db,
  %conf,
  %PAYSYS_PAYMENTS_METHODS,
  %lang,
  $html,
  $base_dir
);

#**********************************************************
=head2 paysys_configure_test()

=cut
#**********************************************************
sub paysys_main_test {
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

  foreach my $action (sort keys %{$test_params}) {
        my $inputs = q{};
        foreach my $key (sort keys %{$test_params->{$action}}) {
          next if ($key eq 'result');
          my $ex_params = $test_params->{$action}{$key}{ex_params} || '';
          my $tooltip = $test_params->{$action}{$key}{tooltip} || '';
          my $type = $test_params->{$action}{$key}{type} || '';
          my $val = $test_params->{$action}{$key}{val} || '';
          my $input = $html->element('label', "$key: ", { class => 'col-md-3 control-label' })
            . $html->element('div',
            $html->form_input($key, $val,
              { class     => 'form-control',
                TYPE      => $type,
                EX_PARAMS => "NAME='$key' $ex_params data-tooltip-position='bottom' data-tooltip='$tooltip'" }),
            { class => 'col-md-9' });
          $input = $html->element('div', $input, { class => 'form-group' });
          $inputs .= $input;
        }
        my $index = get_function_index('paysys_test');
        $templates .= $html->tpl_show(_include('paysys_test_action', 'Paysys'), {
          INPUTS => $inputs,
          INDEX  => $index,
          MODULE => $FORM{MODULE},
          ACTION => $action,
        }, { OUTPUT2RETURN => 1 });
  }
  $html->tpl_show(_include('paysys_main_test', 'Paysys'), {FORMS => $templates});
  return 1;
}

#**********************************************************
=head2 paysys_check_test($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub paysys_test {
  if (!$FORM{module}) {
    print qq{No module};
    return 1;
  }

  my $responce = q{};
  my $url = qq{$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi?};
  foreach my $key (sort keys %FORM) {
    next if (in_array($key, [ '__BUFFER', 'language', 'qindex', 'header', 'module', 'action' ]));
    $url .= "$key=$FORM{$key}&";
  }
  $responce = Abills::Fetcher::web_request("$url", {
    INSECURE => 1,
  });

  my $params = paysys_get_params({MODULE => $FORM{module}});
  if ($params->{$FORM{action}}{result}) {
    foreach my $item (@{$params->{$FORM{action}}{result}} ) {
      if ($responce =~ /$item/) {
        $item =~ s/</&lt;/g;
        $item =~ s/>/&gt;/g;
        print $html->element('div', $html->element('strong', "Успешно! Результат правильный."), {class => 'alert alert-success'});
      }
      else {
        $item =~ s/</&lt;/g;
        $item =~ s/>/&gt;/g;
        print $html->element('div', $html->element('strong', "Ошибка проверки результата. Сообщите в техподдержку!"), {class => 'alert alert-danger'});      }
    }
  }
  print $html->element('textarea', $responce, {
    name  => 'results',
    rows  => '10',
    style => 'width: 100%'
  });
  return 1;
}

#**********************************************************
=head2 paysys_get_params($attr)

  Arguments:
    $attr -

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
  });

  my $test_params = $Module->has_test();

  return $test_params;
}
1;