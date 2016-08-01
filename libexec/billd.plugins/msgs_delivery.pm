=head NAME

  Msgs delivery

=cut

our ($debug, %conf, $admin, $db);

use Abills::Base qw(sendmail);
require Abills::Misc;

msgs_delivery();

#**********************************************************
=head2 msgs_delivery($attr) - Msgs delivery function

=cut
#**********************************************************
sub msgs_delivery {
  my ($attr) = @_;

  $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "Mdelivery\n" if ($debug > 1);

  use Mdelivery;
  my $Mdelivery = Mdelivery->new($db, $admin, \%conf);
  $ADMIN_REPORT{DATE} = $DATE          if (!$ADMIN_REPORT{DATE});
  $LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $LIST_PARAMS{STATUS} = 0;
  $LIST_PARAMS{DATE}   = "<=$ADMIN_REPORT{DATE}";

  my $list = $Mdelivery->list({%LIST_PARAMS, COLS_NAME => 1});
  my @ids;
  foreach my $line (@$list) {
    push @ids, $line->{id};
  }

  foreach my $mdelivery_id (@ids) {
    $Mdelivery->info($mdelivery_id);
    $LIST_PARAMS{PAGE_ROWS}    = 1000000;
    $LIST_PARAMS{MDELIVERY_ID} = $mdelivery_id;

    $Mdelivery->attachment_info({ MSG_ID => $mdelivery_id, COLS_NAME => 1 });

    my @ATTACHMENTS = ();

    if ($Mdelivery->{TOTAL} > 0) {
      foreach my $line (@{ $Mdelivery->{list} }) {
        push @ATTACHMENTS,
        {
          ATTACHMENT_ID => $line->{attachment_id},
          FILENAME      => $line->{filename},
          CONTENT_TYPE  => $line->{content_type},
          FILESIZE      => $line->{filesize},
          CONTENT       => $line->{content}
        };
      }
    }

    my $user_list = $Mdelivery->user_list({ %LIST_PARAMS, 
                                            STATUS    => 0,
                                            COLS_NAME => 1 });
    my @users_ids = ();

    foreach my $u (@$user_list) {
      my $email = ($u->{email} && $u->{email} ne '') ? $u->{email} : ($conf{USERS_MAIL_DOMAIN}) ? $u->{login} . '@' . $conf{USERS_MAIL_DOMAIN} : '';
      if (!$email || $email eq '') {
        print "Login: $u->{login} Don't have mail address. Skip...\n";
        next;
      }

      $Mdelivery->{SENDER} = ($Mdelivery->{SENDER} ne '') ? $Mdelivery->{SENDER} : $conf{ADMIN_MAIL};
      $debug_output .= "LOGIN: $u->{login} E-mail: $email $Mdelivery->{SUBJECT}\n" if ($debug > 0);
      push @users_ids, $u->{uid};

      sendmail("$Mdelivery->{SENDER}", "$email", "$Mdelivery->{SUBJECT}", "$Mdelivery->{TEXT}", "$conf{MAIL_CHARSET}", "$Mdelivery->{PRIORITY} ($MAIL_PRIORITY{$Mdelivery->{PRIORITY}})", { ATTACHMENTS => ($#ATTACHMENTS > -1) ? \@ATTACHMENTS : undef });
    }

    if (!$LIST_PARAMS{LOGIN}) {
      $Mdelivery->user_list_change({ MDELIVERY_ID => $mdelivery_id, UID => join(';', @users_ids) });
      $Mdelivery->change({ ID => $mdelivery_id });
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

1

