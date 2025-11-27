=head1 NAME

  Msgs delivery


 Arguments:
  CUSTOM_DELIVERY=message_file
  ADDRESS_LIST=address_list
  SLEEP= Sleep after message send
  LOGIN=
  UID=

=head1  EXAMPLES

    billd msgs_delivery CUSTOM_DELIVERY=message_file ADDRESS_LIST=address_list

=cut

use strict;
use warnings;
use Abills::Base qw(sendmail in_array);
use Abills::Sender::Core;
use Msgs::db::Delivery;
use Msgs;
use Users;

our (
  $debug,
  %conf,
  $Admin,
  $var_dir,
  $db,
  $argv,
  %LIST_PARAMS,
);

my $Sender = Abills::Sender::Core->new(
  $db,
  $Admin,
  \%conf
);

my $Log = Log->new($db, $Admin);
my %list_params = %LIST_PARAMS;
my $html = Abills::HTML->new({ CONF => \%conf });
%LIST_PARAMS = %list_params;

if ($debug > 2) {
  $Log->{PRINT} = 1;
}
else {
  $Log->{LOG_FILE} = $var_dir . '/log/msgs_delivery.log';
}

if ($argv->{CUSTOM_DELIVERY}) {
  custom_delivery($argv);
}
else {
  msgs_delivery($argv);
}

#**********************************************************
=head2 custom_delivery($attr) - Msgs delivery function

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub custom_delivery {
  my($attr)=@_;

  my $text = get_content($attr->{CUSTOM_DELIVERY});

  my $addresses = '';
  if ($attr->{ADDRESS_LIST}) {
    $addresses = get_content($attr->{ADDRESS_LIST});
  }
  else {
    print "No address list ADDRESS_LIST=address_list\n";
    exit;
  }

  my $subject = '';

  if ($text =~ s/Subject:\s+(.+)//x) {
    $subject = $1;
  }

  my @address_list = split(/[\n\r]+/x, $addresses);

  foreach my $to_address (@address_list) {
    print "$to_address // $subject \n\n $text \n" if ($debug > 3);

    $Sender->send_message({
      TO_ADDRESS  => $to_address,
      MESSAGE     => $text,
      SUBJECT     => $subject,
      SENDER_TYPE => 'Mail',
    });
  }

  return 1;
}

#**********************************************************
=head2 get_content($attr) - Get content

  Arguments:
    filename
  Results:
    $content

=cut
#**********************************************************
sub get_content {
  my ($filename) = shift;

  my $content = '';

  if (open(my $fh, '<', $filename)) {
    while (<$fh>) {
      $content .= $_;
    }
    close($fh);
  }
  else {
    print "Error: '$filename' $!\n";
  }

  return $content;
}


#**********************************************************
=head2 msgs_delivery($attr) - Msgs delivery function

  Arguments:
    $attr

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub msgs_delivery {
  my ($attr) = @_;

  my $debug_output = '';
  $debug_output .= "Mdelivery\n" if ($debug > 1);

  my $send_methods = $Sender->available_types({ HASH_RETURN => 1 });

  my $Delivery = Msgs::db::Delivery->new($db, $Admin, \%conf);
  my $Msgs = Msgs->new($db, $Admin, \%conf);
  my $SEND_DATE = $attr->{DATE} || $DATE;
  my $SEND_TIME = $TIME;

  if ($attr->{DELIVERY_ID}) {
    $LIST_PARAMS{ID}        = $attr->{DELIVERY_ID} ;
  }
  else {
    $LIST_PARAMS{STATUS} = 0;
    $LIST_PARAMS{SEND_DATE} = "<=$SEND_DATE";
    $LIST_PARAMS{SEND_TIME} = "<=$SEND_TIME" if (! $attr->{DATE});
  }

  $Delivery->{debug} = 1 if ($debug > 6);

  my $delivery_list = $Delivery->delivery_list({ %LIST_PARAMS, COLS_NAME => 1 });

  my $users = Users->new($db, $Admin, \%conf);
  my $Internet;

  if (in_array('Internet', \@MODULES)) {
    require Internet;
    $Internet = Internet->new($db, $Admin, \%conf);
  }

  foreach my $mdelivery (@$delivery_list) {
    $Delivery->delivery_info($mdelivery->{id});

    my $send_method_id = $Delivery->{SEND_METHOD} ? $Delivery->{SEND_METHOD} : 0;

    $LIST_PARAMS{PAGE_ROWS} = 1000000;
    $LIST_PARAMS{MDELIVERY_ID} = $mdelivery->{id};
    delete $LIST_PARAMS{ID};

    my $attachments = $Msgs->attachments_list({
      FILENAME     => '_SHOW',
      CONTENT_TYPE => '_SHOW',
      CONTENT_SIZE => '_SHOW',
      CONTENT      => '_SHOW',
      DELIVERY_ID  => $mdelivery->{id},
      COLS_NAME    => 1
    });

    my @ATTACHMENTS = ();
    if ($Msgs->{TOTAL} > 0) {
      foreach my $attachment (@{$attachments}) {
        push @ATTACHMENTS, {
          ATTACHMENT_ID => $attachment->{id},
          filename      => $attachment->{filename},
          content_type  => $attachment->{content_type},
          filesize      => $attachment->{content_size},
          content       => $attachment->{content},
          FILENAME      => $attachment->{filename},
          CONTENT_TYPE  => $attachment->{content_type},
          FILESIZE      => $attachment->{content_size},
          CONTENT       => $attachment->{content}
        };
      }
    }

    my $user_list = $Delivery->user_list({
      %LIST_PARAMS,
      PASSWORD  => '_SHOW',
      STATUS    => 0,
      COLS_NAME => 1
    });

    foreach my $u (@$user_list) {
      $Delivery->{SENDER} = ($Delivery->{SENDER}) ? $Delivery->{SENDER} : $conf{ADMIN_MAIL};

      $Log->log_print('LOG_DEBUG', $u->{uid}, "Delivery: $mdelivery->{id} Send method: $send_methods->{$send_method_id} ($send_method_id) UID: $u->{uid}");

      $users->info($u->{uid});
      my $user_pi = $users->pi({ UID => $u->{uid} });
      my $internet_info = in_array('Internet', \@MODULES) ? $Internet->user_info($u->{uid}) : {};
      $internet_info->{MONTH_FEE} = $internet_info->{MONTH_ABON};
      $internet_info->{DAY_FEE} = $internet_info->{DAY_ABON};

      if ($internet_info->{MONTH_FEE} && $internet_info->{PERSONAL_TP}) {
        $internet_info->{MONTH_FEE} = $internet_info->{PERSONAL_TP};
        $internet_info->{DAY_FEE} = 0;
      }

      if ($internet_info->{REDUCTION_FEE} && $users->{REDUCTION}) {
        $internet_info->{MONTH_FEE} = $internet_info->{MONTH_FEE} - (($internet_info->{MONTH_FEE} / 100) * $users->{REDUCTION}) if $internet_info->{MONTH_FEE};
        $internet_info->{DAY_FEE} = $internet_info->{DAY_FEE} - (($internet_info->{DAY_FEE} / 100) * $users->{REDUCTION}) if $internet_info->{DAY_FEE};
      }

      my $message = $html->tpl_show($Delivery->{TEXT}, {
        %$user_pi,
        %$internet_info,
        USER_LOGIN => $u->{login},
        PASSWORD   => $u->{password}
      }, { OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });

      if ($debug < 6) {
        if (!$Delivery->{SEND_METHOD}) {
          $Msgs->message_add({
            UID        => $user_pi->{UID},
            STATE      => 6,
            ADMIN_READ => "$DATE $TIME",
            SUBJECT    => $Delivery->{SUBJECT},
            PRIORITY   => $Delivery->{PRIORITY},
            MESSAGE    => $Delivery->{TEXT},
          });
        }
        else {
          my $status = $Sender->send_message({
            SENDER      => $Delivery->{SENDER},
            MESSAGE     => $message,
            SUBJECT     => $Delivery->{SUBJECT},
            SENDER_TYPE => $Delivery->{SEND_METHOD} || 0,
            ATTACHMENTS => ($#ATTACHMENTS > -1) ? \@ATTACHMENTS : undef,
            UID         => $user_pi->{UID}
          });

          $Delivery->user_list_change({
            MDELIVERY_ID => $mdelivery->{id} || '-',
            UID          => $u->{uid},
            STATUS       => $status ? 1 : 2
          });

          if ($Sender->{errno}) {
            $Log->log_print('LOG_DEBUG', $u->{uid}, "Error: $Sender->{errno} $Sender->{errstr}");
          }
        }

        if ($attr->{SLEEP}) {
          sleep int($attr->{SLEEP});
        }
      }
      elsif ($debug > 7) {
        $debug_output .= "TYPE: $Delivery->{SEND_METHOD} TO: " . "$u->{id} " . "$message\n";
      }
    }

    if (!$LIST_PARAMS{LOGIN}) {
      $Delivery->delivery_change({
        ID          => $mdelivery->{id} || '-',
        SENDED_DATE => "$DATE $TIME",
        STATUS      => 2
      });
    }
  }

  $DEBUG .= $debug_output;

  return $debug_output;
}

1;

