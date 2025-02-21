package Internet::Api::user::Sessions;

=head1 NAME

  User Internet Sessions

  Endpoints:
    /user/internet/sessions/
    /user/internet/session/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array mk_unique_value/;
use Control::Errors;
use Internet::Sessions;

my Internet::Sessions $Sessions;
my Control::Errors $Errors;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Sessions = Internet::Sessions->new($self->{db}, $self->{admin}, $self->{conf});
  $Sessions->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_internet_session_active($path_params, $query_params)

  Endpoint GET /user/internet/session/active/

=cut
#**********************************************************
sub get_user_internet_session_active {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $sessions = $Sessions->online({
    CLIENT_IP          => '_SHOW',
    CID                => '_SHOW',
    DURATION_SEC2      => '_SHOW',
    ACCT_INPUT_OCTETS  => '_SHOW',
    ACCT_OUTPUT_OCTETS => '_SHOW',
    UID                => $path_params->{uid}
  });

  my @result = ();

  foreach my $session (@{$sessions}) {
    push @result, {
      duration => $session->{duration_sec2},
      cid      => $session->{cid},
      input    => $session->{acct_input_octets},
      output   => $session->{acct_output_octets},
      ip       => $session->{client_ip}
    }
  }

  return \@result;
}

#**********************************************************
=head2 get_user_internet_sessions($path_params, $query_params)

  Endpoint GET /user/internet/sessions/

=cut
#**********************************************************
sub get_user_internet_sessions {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $sessions = $Sessions->list({
    UID          => $path_params->{uid},
    TP_NAME      => '_SHOW',
    TP_ID        => '_SHOW',
    IP           => '_SHOW',
    SENT         => '_SHOW',
    RECV         => '_SHOW',
    DURATION_SEC => '_SHOW',
    PAGE_ROWS    => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    COLS_NAME    => 1
  });

  my @result = ();

  foreach my $session (@{$sessions}) {
    push @result, {
      duration => $session->{duration_sec},
      input    => $session->{recv},
      output   => $session->{sent},
      ip       => $session->{ip},
      tp_name  => $session->{tp_name},
      tp_id    => $session->{tp_id},
    }
  }

  return \@result;
}

1;
