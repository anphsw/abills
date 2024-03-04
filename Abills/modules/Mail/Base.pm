package Mail::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my Abills::HTML $html;
my $lang;
my Mail $Mail;

use Abills::Base qw/days_in_month in_array next_month/;

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

  use Mail;
  $Mail = Mail->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#*******************************************************************
=head2 mail_user_del($uid) - Delete user from module

=cut
#*******************************************************************
sub mail_user_del {
  my $self = shift;
  my ($attr) = @_;

  return 0 if !$attr->{USER_INFO} || !$attr->{USER_INFO}{UID};

  $Mail->{UID} = $attr->{USER_INFO}{UID};
  $Mail->mbox_del(undef, { UID => $attr->{USER_INFO}{UID}, FULL_DELETE => 1 });

  return 1;
}

1