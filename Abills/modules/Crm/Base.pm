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
  my @info = ();

  foreach my $field (@default_search) {
    $LIST_PARAMS{$field} = "*$attr->{SEARCH_TEXT}*";
    push @qs, "$field=*$attr->{SEARCH_TEXT}*";
  }

  $LIST_PARAMS{SKIP_RESPOSIBLE} = 1;

  $Crm->{debug} = 1 if $attr->{DEBUG};

  unless ($attr->{SEARCH_TEXT} =~ m/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/) {
    $Crm->crm_lead_list({ %LIST_PARAMS });
  }

  if ($Crm->{TOTAL}) {
    push @info, {
      'TOTAL'        => $Crm->{TOTAL},
      'MODULE'       => 'Crm',
      'MODULE_NAME'  => $lang->{LEADS},
      'SEARCH_INDEX' => get_function_index('crm_leads') . '&' . join('&', @qs) . "&search=1"
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

#**********************************************************
=head2 crm_send_action_message($attr) - send action message to email

  Arguments:
    $attr
      LEAD_ID
      ACTION_ID

  Returs:
     TRUE/FALSE

=cut
#**********************************************************
sub crm_send_action_message {
  my $self = shift;
  my ($attr) = @_;

  return if !$attr->{LEAD_ID} || !$attr->{ACTION_ID};

  my $action_info = $Crm->crm_actions_info({ ID => $attr->{ACTION_ID} });
  return if !$action_info->{SEND_MESSAGE} || !$action_info->{MESSAGE};

  my $lead_info = $Crm->crm_lead_info({ ID => $attr->{LEAD_ID} });
  return if !$lead_info->{EMAIL};

  while($action_info->{MESSAGE} =~ /\%(\S+)\%/g) {
    my $var = $1;
    next if !$var;

    $lead_info->{$var} //= '';
    $action_info->{MESSAGE} =~ s/%$var%/$lead_info->{$var}/g;
  }
  
  my $is_html = $action_info->{MESSAGE} =~ /\<\S+\>/;
  $action_info->{MESSAGE} =~ s/\n/<br>/g if $is_html;

  require Abills::Sender::Core;
  Abills::Sender::Core->import();
  my $Sender = Abills::Sender::Core->new($db, $admin, $CONF);

  return $Sender->send_message({
    TO_ADDRESS   => $lead_info->{EMAIL},
    MESSAGE      => $action_info->{MESSAGE},
    SUBJECT      => $action_info->{SUBJECT},
    SENDER_TYPE  => 'Mail',
    CONTENT_TYPE => $is_html ? 'text/html' : undef,
  });
}

1;