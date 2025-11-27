=head2 NAME

  Expert User portal

=cut

use warnings;
use strict;

our (
  $db,
  $admin,
  %conf,
  %lang,
);

our Users $user;
our Abills::HTML $html;
my Abills::HTML $table;

my $Expert = Expert->new($db, $admin, \%conf);

#**********************************************************
=head2 expert_user_faq()

=cut
#**********************************************************
sub expert_user_faq {

  my $faq_info = $Expert->faq_list({
    TITLE        => '_SHOW',
    BODY         => '_SHOW',
    COLS_NAME => 1,
  });

  $table = $html->table({
    width               => '100%',
    caption             => $lang{FAQ},
    border              => 1,
    title               => [ $lang{QUESTION}, $lang{REPLY} ],
    pages               => $Expert->{TOTAL},
    ID                  => 'EXPERT_USER_PORTAL',
    DATA_TABLE          => 1,
  });

  foreach my $faq (@$faq_info) {
    $table->addrow($html->b($faq->{title}), $faq->{body});
  }

  print $table->show();

  return 1;
}

1;