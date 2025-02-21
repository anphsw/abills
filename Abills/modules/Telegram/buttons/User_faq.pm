package Telegram::buttons::User_faq;

use strict;
use warnings FATAL => 'all';

use Encode qw/encode_utf8/;
use Abills::Base qw/is_number/;

my %icons = (
  faq => "\xe2\x9d\x94"
);

#**********************************************************
=head2 new($conf, $bot, $bot_db, $APILayer, $user_config)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $bot, $bot_db, $APILayer, $user_config) = @_;

  my $self = {
    conf        => $conf,
    bot         => $bot,
    bot_db      => $bot_db,
    api         => $APILayer,
    user_config => $user_config
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 enable()

=cut
#**********************************************************
sub enable {
  my $self = shift;

  return $self->{user_config}{expert_faq};
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return "$icons{faq} $self->{bot}{lang}{FAQ}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my ($faqs) = $self->{api}->fetch_api({ PATH => '/user/expert/faqs' });

  if (!$faqs || ref $faqs eq 'HASH' || !scalar(@$faqs)) {
    $self->{bot_db}->del($self->{bot}->{chat_id});
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NO_FAQS} });
    return 0;
  }

  my $message = "$icons{faq} <b>$self->{bot}{lang}{FAQ}</b>\n";
  $message .= "\n";

  my @keyboard = ();
  for my $i (0..$#$faqs) {
    my $faq = $faqs->[$i];
    my $row_index = int($i / 4);
    $keyboard[$row_index] //= [];
    my $number = $i + 1;
    my $button = { text => $number };

    $message .= "<b>$number.</b> $faq->{title}\n";
    push(@{$keyboard[$row_index]}, $button);
  }

  $message .= "\n";
  $message .= "$self->{bot}{lang}{ENTER_FAQ_NUMBER}";

  my $cancel_button = { text => $self->{bot}{lang}{CANCEL_TEXT} };

  push(@keyboard, [$cancel_button]);

  $self->{bot_db}->add({
    USER_ID    => $self->{bot}->{chat_id},
    BUTTON => "User_faq",
    FN     => "choose_faq"
  });

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => 'true'
    }
  });

  return 1;
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub choose_faq {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{message}->{text}) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NOT_EXIST} });
    return 1;
  }

  my $text = $attr->{message}->{text};

  if ($text && encode_utf8($text) eq $self->{bot}{lang}{CANCEL_TEXT}) {
    $self->{bot_db}->del($self->{bot}->{chat_id});
    $self->{bot}->send_message({ text => $self->{bot}{lang}{CANCELED} });
    return 0;
  }

  if (!is_number($text, 0, 1)) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{ENTER_FAQ_NUMBER}});
    return 1;
  };

  my $faq_index = $text;

  my ($faqs) = $self->{api}->fetch_api({ PATH => '/user/expert/faqs' });

  if (!$faqs || ref $faqs eq 'HASH' || !scalar(@$faqs)) {
    $self->{bot_db}->del($self->{bot}->{chat_id});
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NO_FAQS} });
    return 0;
  }

  my $chosen_faq = $faqs->[$faq_index - 1];

  if (!$chosen_faq) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NO_FAQS_AT_THIS_NUM} });
    return 1;
  }

  my $message = "$faq_index. <b>$chosen_faq->{title}</b>\n";
  $message .= "\n";
  $message .= "$chosen_faq->{body}";

  my @keyboard = ();
  for my $i (0..$#$faqs) {
    my $faq = $faqs->[$i];
    my $row_index = int($i / 4);
    $keyboard[$row_index] //= [];
    my $number = $i + 1;
    my $button = { text => $number };
    push(@{$keyboard[$row_index]}, $button);
  }

  my $cancel_button = { text => $self->{bot}{lang}{CANCEL_TEXT} };

  push(@keyboard, [$cancel_button]);

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => 'true'
    }
  });

  return 1;
}

1;
