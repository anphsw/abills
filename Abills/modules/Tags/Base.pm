package Tags::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my Abills::HTML $html;
my $lang;
my Tags $Tags;

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

  use Tags;
  $Tags = Tags->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#*******************************************************************
=head2 tags_user_del($uid) - Delete user from module

=cut
#*******************************************************************
sub tags_user_del {
  my $self = shift;
  my ($attr) = @_;

  return 0 if !$attr->{USER_INFO} || !$attr->{USER_INFO}{UID};

  $Tags->{UID} = $attr->{USER_INFO}{UID};
  $Tags->user_del({ UID => $attr->{USER_INFO}{UID}, COMMENTS => $attr->{USER_INFO}{COMMENTS} });

  return 1;
}

1