package Abills::Sender::Iptv_message;
=head1 NAME

  Send message on Iptv

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Sender::Plugin;
use parent 'Abills::Sender::Plugin';
use Iptv::Init qw/init_iptv_service/;

use Abills::Base qw(_bp);
use Iptv;

my $Iptv;

#**********************************************************
=head2 new($conf, $attr) - Create new Iptv_message object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $attr) = @_ or return 0;

  my $self = {
    conf  => $conf,
    db    => $attr->{db} || {},
    admin => $attr->{admin} || {}
  };

  $Iptv = Iptv->new($self->{db}, $self->{admin}, $conf);

  bless $self, $class;

  return $self;
}

#**********************************************************
=head2 send_message($attr)

  Arguments:
    MESSAGE
    SUBJECT
    PRIORITY_ID
    MAIL_TPL
    UID

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  my $Iptv_user = $Iptv->user_list({
    UID             => $attr->{UID},
    SUBSCRIBE_ID    => '_SHOW',
    SERVICE_ID      => '_SHOW',
    TV_SERVICE_NAME => '_SHOW',
    LOGIN           => '_SHOW',
    COLS_NAME       => 1,
    COLS_UPPER      => 1,
    PAGE_ROWS       => 99999,
  });

  my %Tv_services = ();

  my $total = 0;
  foreach my $user (@{$Iptv_user}) {
    next if $Tv_services{$user->{service_id}} || $user->{SERVICE_STATUS};

    my $tv_service = init_iptv_service($Iptv->{db}, $Iptv->{admin}, $Iptv->{conf}, { SERVICE_ID => $user->{service_id} });
    $Tv_services{$user->{service_id}} = $tv_service;

    next if !$tv_service || !$tv_service->can('send_iptv_message');

    $tv_service->send_iptv_message({ %{$attr}, %{$user} });
    $total += 1;
  }

  return $total;
}

1;