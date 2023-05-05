package Crm::Base;
use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my Abills::HTML $html;
my $lang;
my $Crm;


#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {};

  require Crm::db::Crm;
  Crm->import();
  $Crm = Crm->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}


#**********************************************************
=head2 internet_search($attr) - Global search submodule

  Arguments:
    $attr
      SEARCH_TEXT
      DEBUG

  Returs:
     TRUE/FALSE

=cut
#**********************************************************
sub crm_search {
  my $self = shift;
  my ($attr) = @_;

  my @default_search = ('FIO', 'PHONE', 'EMAIL', 'COMPANY', 'LEAD_CITY', 'ADDRESS', '_MULTI_HIT');

  my %LIST_PARAMS = ();

  my @qs = ();
  foreach my $field (@default_search) {
    $LIST_PARAMS{$field} = "*$attr->{SEARCH_TEXT}*";
    push @qs, "$field=*$attr->{SEARCH_TEXT}*";
  }

  $LIST_PARAMS{SKIP_RESPOSIBLE}=1;

  if ($attr->{DEBUG}) {
    $Crm->{debug} = 1;
  }

  unless ($attr->{SEARCH_TEXT} =~ m/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/) {
    $Crm->crm_lead_list({
      %LIST_PARAMS,
    });
  }

  my @info = ();

  if ($Crm->{TOTAL}) {
    push @info, {
      'TOTAL'        => $Crm->{TOTAL},
      'MODULE'       => 'Crm',
      'MODULE_NAME'  => $lang->{LEADS},
      'SEARCH_INDEX' => get_function_index('crm_leads')
        . '&' . join('&', @qs) . "&search=1"
    };
  }
  elsif ($attr->{SEARCH_TEXT} =~ /\@/ || $attr->{SEARCH_TEXT} =~ /^\d+$/) {
    my $search_type = 'EMAIL';

    if ($attr->{SEARCH_TEXT} =~ /^\d+$/) {
      $search_type = 'PHONE';
    }

    push @info, {
      'TOTAL'        => 0,
      'MODULE'       => 'Crm',
      'MODULE_NAME'  => $lang->{LEADS},
      'SEARCH_INDEX' => 'crm_leads'
        . '&' . join('&', @qs) . "&search=1",
      EXTRA_LINK     => "$lang->{ADD}|get_index=" . 'crm_leads' . "&add_form=1&full=1&"
        . "$search_type=$attr->{SEARCH_TEXT}"
    };
  }

  return \@info;
}


1;