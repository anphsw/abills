package Abills::Api::Functions;
=head NAME

  Abills::Api::Functions - returns function list for user api config path
  using instead mk_menu, because during running daemon it redefines global variable %functions

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    modules => $attr->{modules} || {},
  };

  bless($self, $class);

  $self->{functions} = ();
  my $type = $attr->{type} || 'user';

  if ($type eq 'user') {
    $self->{functions} = $self->user_functions($attr);
  }

  return $self;
}

#**********************************************************
=head2 user_functions()

=cut
#**********************************************************
sub user_functions {
  my $self = shift;
  my ($attr) = @_;

  my $modules = $self->_user_functions_list($attr);
  my %functions = ();

  foreach my $module (@{$self->{modules}}) {
    next if (!$modules->{$module});
    %functions = (%functions, %{$modules->{$module}->()});
  }

  return \%functions;
}

#**********************************************************
=head2 _user_functions_list()

=cut
#**********************************************************
sub _user_functions_list {
  my $self = shift;
  my ($attr);

  my %modules = (
    Abon       => sub {
      return { abon_client => 1 };
    },
    Cams       => sub {
      return {
        cams_clients_streams         => 1,
        cams_user_streams_management => 1,
        cams_user_info               => 1,
        cams_clients_streams         => 1,
        cams_archives                => 1
      };
    },
    Cards      => sub {
      return { 'cards_user_payment' => {}, }
    },
    Docs       => sub {
      if ($self->{conf}->{DOCS_SKIP_USER_MENU}) {
        return {};
      }

      my %functions = (docs_invoices_list => 1);

      if ($self->{conf}{DOCS_USERPORTAL_INVOICE}) {
        $functions{docs_receipt_list} = 1;
      }

      if ($self->{conf}{DOCS_USERPORTAL_ACT}) {
        $functions{docs_acts_list} = 1;

      }
      return \%functions;
    },
    Equipment  => sub {
      return { equipment_user => 1 };
    },
    Expert     => sub {
      return { expert_faq => 1 }
    },
    Extreceipt => sub {
      $self->{conf}->{EXTRECEIPT_USER_PORTAL} ?
        return { extreceipts_list => 1 } : {};
    },
    Internet   => sub {
      my %functions = ('internet_user_info' => 1);

      if ($self->{conf}->{INTERNET_USER_IPOE_STATS}) {
        $functions{ipoe_sessions} = 1;
      }
      else {
        $functions{internet_user_stats} = 1;
      }
      $functions{internet_user_chg_tp} = 1 if ($self->{conf}->{INTERNET_USER_CHG_TP});

      return \%functions;
    },
    Iptv       => sub {
      my %functions = (iptv_user_info => 1, iptv_portal_service_info => 1);
      $functions{iptv_user_chg_tp} = 1 if ($self->{conf}->{IPTV_USER_CHG_TP});
      return \%functions;
    },
    Msgs       => sub {
      my %functions = (msgs_user => 1);
      $functions{show_user_chat} = 1 if ($self->{conf}->{MSGS_CHAT});
      return \%functions;
    },
    Paysys     => sub {
      require Users;
      Users->import();
      my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
      $Users->info($attr->{uid});
      my $group_info = $Users->group_info($Users->{GID});

      my %functions = ();
      if ((exists $group_info->{DISABLE_PAYSYS} && $group_info->{DISABLE_PAYSYS} == 0) || !$Users->{TOTAL}) {
        %functions = (paysys_payment => 1, paysys_user_log => 1, paysys_subscribe => 1);
      }
      else {
        %functions = (paysys_user_log => 1);
      }
      return \%functions;
    },
    Voip       => sub {
      return { voip_user_info => 1, voip_user_stats => 1, voip_user_routes => 1 };
    },
    Referral   => sub {
      return { add_friend => 1 };
    },
    Portal     => sub {
      return { portal_news => 1 };
    },
    Crm        => sub {
      return { crm_user_leads => 1 }
    }
  );

  return \%modules;
}

1;
