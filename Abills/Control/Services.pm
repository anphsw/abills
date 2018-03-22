=head1 NAME

  INternet base functions

=cut

use strict;
use warnings FATAL => 'all';
use Tariffs;

our(
  $db,
  $admin,
  %conf,
  $html,
  %lang,
);


my $Tariffs = Tariffs->new($db, \%conf, $admin);

#**********************************************************
=head sel_tp($tp_id)

  Arguments:
    MODULE
    TP_ID    - SHow tp name for tp_id
    SELECT   - Select element
    SKIP_TP  - Skip show tp
    SHOW_ALL - Show all tps
    SEL_OPTIONS - Extra sel options (items)
    EX_PARAMS   - Extra sell options

=cut
#**********************************************************
sub sel_tp {
  my ($attr) = @_;

  my %params = ( MODULE => 'Dv;Internet' );
  if ($attr->{MODULE}) {
    $params{MODULE} = $attr->{MODULE};
  }

  if($attr->{TP_ID}) {
    if($attr->{TP_ID} =~ /:(\d+)/) {
      $attr->{TP_ID} = $1;
    }

    if(! $attr->{SHOW_ALL}) {
      $params{INNER_TP_ID} = $attr->{TP_ID};
    }
  }

  my $list = $Tariffs->list({
    NEW_MODEL_TP => 1,
    DOMAIN_ID    => $users->{DOMAIN_ID},
    COLS_NAME    => 1,
    %params
  });

  if($attr->{TP_ID} && ! $attr->{EX_PARAMS}) {
    if($Tariffs->{TOTAL}) {
      return "$list->[0]->{id} : $list->[0]->{name}";
    }

    return $attr->{TP_ID};
  }

  my %tp_list = ();

  foreach my $line (@$list) {
    if($attr->{SKIP_TP} && $attr->{SKIP_TP} == $line->{tp_id}) {
      next;
    }
    $tp_list{$line->{tp_id}} = $line->{id} .' : '. $line->{name};
  }

  if($attr->{SELECT}) {
    my %EX_PARAMS = ();

    my $element_name = $attr->{SELECT};
    my %extra_options = ('' => '--');
    if($attr->{SEL_OPTIONS}) {
      %extra_options = %{ $attr->{SEL_OPTIONS} };
    }

    if($attr->{EX_PARAMS}) {
      %EX_PARAMS = ( EX_PARAMS => $attr->{EX_PARAMS} );
    }

    return $html->form_select(
      $element_name,
      {
        SELECTED    => $attr->{$element_name} || $FORM{$element_name},
        SEL_HASH    => \%tp_list,
        SEL_OPTIONS => \%extra_options,
        NO_ID       => 1,
        %EX_PARAMS
      }
    );
  }

  return \%tp_list;
}


1;