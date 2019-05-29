=head1 NAME PON_Calculator

  Calculate signal

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw\_bp\;
use JSON;
use Encode;

our ($db, $admin, %conf, $html, %lang, $index, %FORM, $base_dir);

#************************************************************
=head2 calculator_main() - main function

  Returns: 1
=cut
#************************************************************
sub calculator_main {

  if ($FORM{generate_input}) {
    generate_input();
    return 1;
  }

  my $type_input = $html->form_select('TYPE', {
    SEL_HASH => { 5 => 'SFP C+', 7 => 'SFP C++' },
    NO_ID    => 1,
  });

  my $length_input = $html->form_input('LENGTH', '0', { TYPE => 'number', class => 'form-control' });
  my $count_input = $html->form_input('COUNT', '0', { TYPE => 'number', class => 'form-control' });

  $html->tpl_show(_include('equipment_calculator', 'Equipment'), {
    TYPE   => $type_input,
    LENGTH => $length_input,
    COUNT  => $count_input
  });
  return 1;
}
#************************************************************
=head2 generate_input() - show input with data

=cut
#************************************************************
sub generate_input {
  my $input;
  if ($FORM{TYPE} == 1) {
    $FORM{DATA} =~ s/\\"/"/g;
    $input = $html->form_select($FORM{NAME}, {
      SEL_HASH => decode_json($FORM{DATA}),
      NO_ID    => 1,
    });

  }
  elsif ($FORM{TYPE} == 2) {
    $input = $html->form_input($FORM{NAME}, $FORM{DATA}, {
      EX_PARAMS => 'readonly'
    });
  }
  $html->tpl_show(_include('equipment_calculator_input', 'Equipment'), {
    LABEL => decode_utf8($FORM{LABEL}),
    INPUT => $input,
  });

  return 1;
}

1;