#**********************************************************
=head1 NAME

  Plugin for cleaning old FCM tokens
    /usr/abills/libexec/billd push_clean

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';

push @INC, $Bin.'/../', $Bin.'/../Abills/';

our (
  $db,
  $Admin,
  %conf,
  $argv,
);

use Abills::Sender::Push;
use Contacts;

my $Contacts = Contacts->new($db, $Admin, \%conf);
my $Push = Abills::Sender::Push->new(\%conf, { db => $db, admin => $Admin });

my $DEBUG = ($argv && $argv->{DEBUG}) ? $argv->{DEBUG} : 0;

push_clean();

#**********************************************************
=head2 push_clean()

=cut
#**********************************************************
sub push_clean {
  if (!$conf{PUSH_ENABLED} || !$conf{FIREBASE_SERVER_KEY}) {
    return 1;
  }

  my @registration_ids = ();

  my $tokens = $Contacts->push_contacts_list({
    VALUE     => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 1000000,
  });

  foreach my $token (@{$tokens}) {
    push @registration_ids, $token->{value};
  }

  my $result = $Push->dry_run({
    TOKENS        => \@registration_ids,
    RETURN_RESULT => 1,
  });

  return 1 if ($result->{errno});

  my $invalid = 0;
  my $valid = 0;

  print "\nREPORT OF FCM TOKENS STATUS\n" if ($DEBUG);

  for (my $i = 0; $i < scalar @{$result->{results}}; $i++) {
    my $message = '';
    if ($result->{results}->[$i]->{error}) {
      if ($argv->{DELETE_TOKENS}) {
        $Contacts->push_contacts_del({
          ID => $tokens->[$i]->{id} || '--',
        });
        $message .= "TOKEN DELETED. "
      }
      $invalid += 1;
      $message .= "INVALID TOKEN $tokens->[$i]->{value} is invalid with FCM status $result->{results}->[$i]->{error}";
    }
    else {
      $valid += 1;
      $message = "VALID TOKEN $tokens->[$i]->{value}";
    }

    print "$message\n" if ($DEBUG && $DEBUG > 2);
  }

  if ($DEBUG) {
    print "\nVALID TOKENS COUNT: $valid\nINVALID TOKENS COUNT: $invalid\n";
  }

  return 1;
}

1;
