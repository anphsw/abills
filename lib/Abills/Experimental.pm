package Abills::Experimental;
use strict;
use warnings FATAL => 'all';

do 'Abills/Misc.pm';

our ($html, %lang);

my $instance = undef;
#**********************************************************
=head2 new($html, \%lang) - constructor for Experimental features package

=cut
#**********************************************************
sub new{
  my $class = shift;

  if (!defined $instance){
    my ($HTML, $LANG) = @_;

    $html = $HTML;
    %lang = %$LANG;

    my $self = {};
    bless ($self, $class);

    $instance = $self;
  }

  return $instance;
}

#**********************************************************
=head2 list_to_hash($array_ref, $key_name);

  Arguments:
    $array_ref - [ {}, {}, ...]
    $key_name  -  key for grouping (unique)

  Returns:
    \%hash_ref

=cut
#**********************************************************
sub sort_array_to_hash {
  my ($array_ref, $key_name) = @_;

  my %result_hash = ();
  foreach my $list_row ( @{$array_ref} ) {
    $result_hash{$list_row->{$key_name}} = $list_row;
  }

  return \%result_hash;
}

#**********************************************************
=head2 _show_result($Module, $message) - shows error or success message

  Arguments:
    $Module  - Module DB object
    $message - message to show if no error

  Returns:
    boolean - 1 if success

=cut
#**********************************************************
sub _show_result {
  my ($self, $Module, $caption, $message) =  @_;

  $caption ||= '',
  $message ||= '';

  return 0 if (_error_show($Module, { MESSAGE => '' }));

  $html->message('info', $caption, $message) if ($caption || $message);

  return 1;
}


1;