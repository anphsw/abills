package Abills::TextFormat;

use strict;
use warnings FATAL => 'all';

use Encode;

use Abills::Base qw(json_former);

our @EXPORT = qw(
  hide_text
);
our @EXPORT_OK = qw(
  hide_text
);

my $conf;
my Abills::HTML $html;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    $attr
      HTML: html object
      functions: hash of available functions

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  $conf = shift;
  $html = shift;

  my $self = {
    conf      => $conf,
    html      => $html,
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 text_editor($attr)

  Arguments:
    INPUT_ID: str  - input id where need to store content during send of form
    FORM_ID: str   - form id where need to add content
    TOOLBAR: array - custom toolbar config
    $attr
      HTML: html object
      functions: hash of available functions

  Returns:
    object

=cut
#**********************************************************
sub text_editor {
  my $self = shift;
  my ($attr) = @_;

  $attr->{INPUT_ID} //= 'BODY';
  $attr->{FORM_ID} //= 'form';
  $attr->{TOOLBAR} //= ['bold', 'italic', 'underline'];

  $attr->{TOOLBAR_CONF} = json_former($attr->{TOOLBAR});

  return $html->tpl_show(::templates('input_text_editor'), $attr, {
    OUTPUT2RETURN => 1,
  });
}

#**********************************************************
=head2 hide_text($text) - Hide text string

  Arguments:
     $text

  Returns:
    $hidden_text

=cut
#**********************************************************
sub hide_text {
  my ($text) = @_;

  my $hidden_text = '';
  if (!$text) {
    return q{};
  }

  my @join_test = ();
  $text =~ s/\s+$//xgm;
  $text =~ s/\'/_/xg;
  $text =~ s/&|%//xg;
  my $str_utf8 = decode('UTF-8', $text);

  my @split_fio = split(/ /, $str_utf8);
  my @split_word = ();
  foreach my $key (@split_fio) {
    @split_word = split(//, $key);
    for (my $i = 0; $i < @split_word; $i++) {
      if ($i != 0 && ($i % 2 == 0 || $i % 3 == 0)) {
        $split_word[$i] = '*';
      }
    }
    my $hidden = join('', @split_word);
    push(@join_test, $hidden);
  }

  $hidden_text = encode('UTF-8', join(' ', @join_test));

  return $hidden_text;
}

1;
