package Api::Base;

use strict;
use warnings FATAL => 'all';

use parent 'Exporter';

use Abills::Backend::API;

our $VERSION = 0.01;

my ($admin, $CONF, $db);
my Abills::HTML $html;
my $lang;

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

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 extreceipt_payments_maked($attr)

=cut
#**********************************************************
sub api_payments_maked {
  shift;
  my ($attr) = @_;

  if ($CONF->{USER_MOBILE_PUSH_NOTIFY}) {
    my $Sender = Abills::Sender::Core->new($db, $admin, $CONF);

    $Sender->send_message({
      UID         => $attr->{USER_INFO}->{UID},
      SENDER_TYPE => 'Mobile_push',
      TITLE       => "Made payment: $attr->{PAYMENT_ID}",
      MESSAGE     => "Successful payment SUM: $attr->{SUM}",
      PARAMS      => {
        UID        => $attr->{USER_INFO}->{UID},
        LOGIN      => $attr->{USER_INFO}->{LOGIN},
        PAYMENT_ID => $attr->{PAYMENT_ID},
        SUM        => $attr->{SUM},
        AMOUNT     => $attr->{AMOUNT}
      },
      TYPE        => 1
    });
  }

  return 1;
}

1;
