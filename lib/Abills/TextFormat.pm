package Abills::TextFormat;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(json_former);

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

1;
