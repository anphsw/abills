# billd plugin
#**********************************************************
=head1

 billd plugin

 Standart execute
    /usr/abills/libexec/billd internet_pay_tags

    Argv:
      TAG - tag id (required argument)
      PAYMENT_PERIOD - quantity in days
      UNPAYMENT_PERIOD - quantity in days
      GID - group ID of user
      DEBUG

 DESCRIBE:  Add or remove tag to user

 Example:
   /usr/abills/libexec/billd internet_pay_tags TAG=5 PAYMENT_PERIOD=30 UNPAYMENT_PERIOD=60 GID=1 DEBUG=1

=cut
#*********************************************************
use strict;
use warnings FATAL => 'all';
use Payments;
use Tags;
use Abills::Base qw(date_diff);

our (
  $db,
  %conf,
  $argv,
  $DATE
);

our Admins $Admin;
our $admin = $Admin;

my $Payments = Payments->new($db, $admin, \%conf);
my $Tags = Tags->new($db, $admin, \%conf);
my $debug = $argv->{DEBUG} || 0;

if (in_array( 'Tags', \@MODULES )){
  if (!$argv->{TAG}){
    print "Please specify id for argument TAG\n";
    exit;
  }

  get_internet_users_pay();
  get_internet_users_unpay();

}
else {
  print "Module Tags does not active\n";
}


#**********************************************************
=head2 get_internet_users_pay() - adding user's tag if payment exist

=cut
#**********************************************************
sub get_internet_users_pay {
  my $payment_period = $argv->{PAYMENT_PERIOD} ? $argv->{PAYMENT_PERIOD} : 30;

  my $payment_list = $Payments->list({
    UID          => '_SHOW',
    GID          => $argv->{GID} ? $argv->{GID} : '',
    PAYMENT_DAYS => '>' . $payment_period,
    SUM          => '_SHOW',
    PAGE_ROWS    => 10000,
    COLS_NAME    => 1
  });
  return if (!$Payments->{TOTAL});

  print "Payments total: $Payments->{TOTAL}\n" if ($debug);

  my $tags_list = $Tags->tags_list({ TAG_ID => $argv->{TAG}, COLS_NAME => 1 });

  my %hash_users_tag = ();
  my $i = 0;

  if ($Tags->{TOTAL}){
    foreach my $tag (@$tags_list) {
      next if (!$tag->{uid});
      $hash_users_tag{$tag->{uid}} = $tag->{id};
    };
  }

  foreach my $payment (@$payment_list) {
    if (!$hash_users_tag{$payment->{uid}}) {
      $Tags->user_add({
        UID    => $payment->{uid},
        TAG_ID => $argv->{TAG}
      });
      print "Tag added for UID=$payment->{uid}\n" if ($debug );
      $i++;
    }
  }
  print "Added $i users tags\n" if ($debug);
  
  return;
}

#**********************************************************
=head2 get_internet_users_unpay() - removing user's tag if payment doesn't exist

=cut
#**********************************************************
sub get_internet_users_unpay {
  my $unpayment_period = $argv->{UNPAYMENT_PERIOD} ? $argv->{UNPAYMENT_PERIOD} : 60;

  my $tags_list = $Tags->tags_list({ TAG_ID => $argv->{TAG}, COLS_NAME => 1 });
  return if (!$Tags->{TOTAL});

  my $i = 0;

  foreach my $tag (@$tags_list) {
    my $payment_list = $Payments->list({
      UID        => $tag->{uid},
      GID        => $argv->{GID} ? $argv->{GID} : '',
      DATETIME   => '_SHOW',
      PAGE_ROWS  => 100,
      DESC       => 'desc',
      COLS_NAME  => 1
    })->[0];

    my $days = $payment_list->{datetime} ? date_diff($payment_list->{datetime}, $DATE) : 0;

    if ($days >= $unpayment_period || !$payment_list->{datetime}) {
      $Tags->user_del({ UID => $tag->{uid}, TAG_ID => $tag->{id} });
      $i++;
    }
  }
  print "Removed $i users tags\n\n" if ($debug);

  return;
}

1;