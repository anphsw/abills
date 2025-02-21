package Viber::buttons::User_faq;

use strict;
use warnings FATAL => 'all';

use Encode qw/encode_utf8/;
use Abills::Base qw/is_number/;

my %icons = (
  faq => "\xe2\x9d\x94"
);

#**********************************************************
=head2 new($Botapi)

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
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NO_FAQS} });
    return 0;
  }

  my $pre_message = "$icons{faq} *$self->{bot}{lang}{FAQ}* \n";
  $pre_message .= "\n";
  my ($keyboard, $message) = $self->_create_faq_keyboard($faqs, $pre_message);
  $message .= "\n";
  $message .= "$self->{bot}{lang}{CHOOSE_FAQ_NUMBER}";

  $self->{bot}->send_message({
    text         => $message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => $keyboard,
    }
  });

  return 1;
}

#**********************************************************
=head2 choose_faq($attr)

=cut
#**********************************************************
sub choose_faq {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{argv}->[0]) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NOT_EXIST} });
    return 1;
  }

  my $text = $attr->{argv}->[0];

  if ($text && encode_utf8($text) eq $self->{bot}{lang}{CANCEL_TEXT}) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{CANCELED} });
    return 0;
  }

  if (!is_number($text, 0, 1)) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{CHOOSE_FAQ_NUMBER}});
    return 1;
  };

  my $faq_index = $text;

  my ($faqs) = $self->{api}->fetch_api({ PATH => '/user/expert/faqs' });

  if (!$faqs || ref $faqs eq 'HASH' || !scalar(@$faqs)) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NO_FAQS} });
    return 0;
  }

  my $chosen_faq = $faqs->[$faq_index - 1];

  if (!$chosen_faq) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NO_FAQS_AT_THIS_NUM} });
    return 1;
  }

  my $message = "$faq_index. *$chosen_faq->{title}* \n";
  $message .= "\n";
  $message .= "$chosen_faq->{body}";

  my ($keyboard, undef) = $self->_create_faq_keyboard($faqs, '');

  $self->{bot}->send_message({
    text         => $message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => $keyboard,
    }
  });

  return 1;
}

#**********************************************************
=head2 cancel()

=cut
#**********************************************************
sub cancel {
  my $self = shift;
  $self->{bot}->send_message({ text => "$self->{bot}->{lang}->{SEND_CANCEL}" });

  return 0;
}

#**********************************************************
=head2 _create_faq_keyboard($faqs, $message)

=cut
#**********************************************************
sub _create_faq_keyboard {
  my $self = shift;
  my ($faqs, $message) = @_;

  my @keyboard = ();
  my $columns = scalar(@$faqs) > 4 ? 2 : 3;
  for my $i (0..$#$faqs) {
    my $faq = $faqs->[$i];
    my $number = $i + 1;
    my $button = {
      Columns    => $columns,
      Rows       => 1,
      Text       => "#$number",
      ActionType => 'reply',
      ActionBody => "fn:User_faq&choose_faq&$number",
      TextSize   => 'regular'
    };

    $message .= "$number. *$faq->{title}* \n";
    push(@keyboard, $button);
  }

  my $cancel_button = {
    Text => $self->{bot}{lang}{CANCEL_TEXT},
    ActionType => 'reply',
    ActionBody => 'fn:User_faq&cancel',
    TextSize   => 'regular'
  };

  push(@keyboard, $cancel_button);

  return (\@keyboard, $message);
}

1;
