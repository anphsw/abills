package Telegram::buttons::Portal_articles;

use strict;
use warnings FATAL => 'all';

use Encode qw/encode_utf8/;
use Abills::Base qw/is_number/;

my %icons = (
  article => "\xf0\x9f\x93\xb0",
  title   => "\xf0\x9f\x93\xb0",
  topic   => "\xf0\x9f\x97\x82",
  date    => "\xf0\x9f\x95\x92",
  link    => "\xf0\x9f\x94\x97",
  pin     => "\xf0\x9f\x93\x8c"
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

  return $self->{user_config}{portal_news};
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return "$icons{article} $self->{bot}{lang}{NEWS}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my ($res) = $self->{api}->fetch_api({ PATH => '/user/portal/news' });

  if ($res->{errno} || !scalar(@{$res->{news}})) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NO_NEWS} });
    return 0;
  }

  my @sorted_by_importance = sort { $b->{importance} <=> $a->{importance} } @{$res->{news}};
  my @news = grep { defined $_ } @sorted_by_importance[0..9];
  my $topics = $res->{topics};

  my $message = "$icons{article} <b>$self->{bot}{lang}{NEWS}</b>\n";
  $message .= "\n";

  my ($keyboard, $edited_message) = $self->_create_articles_keyboard(\@news, $message);

  $self->{bot_db}->add({
    USER_ID    => $self->{bot}->{chat_id},
    BUTTON => "Portal_articles",
    FN     => "choose_article"
  });

  $self->{bot}->send_message({
    text                     => $edited_message,
    reply_markup             => {
      keyboard        => $keyboard,
      resize_keyboard => 'true'
    },
    disable_web_page_preview => 'true'
  });

  return 1;
}

#**********************************************************
=head2 choose_article($attr)

=cut
#**********************************************************
sub choose_article {
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
    $self->{bot}->send_message({ text => $self->{bot}{lang}{ENTER_NEWS_NUMBER}});
    return 1;
  };

  my $article_index = $text;

  my ($res) = $self->{api}->fetch_api({ PATH => '/user/portal/news' });

  if ($res->{errno} || !scalar(@{$res->{news}})) {
    $self->{bot_db}->del($self->{bot}->{chat_id});
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NO_NEWS} });
    return 0;
  }

  my @sorted_by_importance = sort { $b->{importance} <=> $a->{importance} } @{$res->{news}};
  my @news = grep { defined $_ } @sorted_by_importance[0..9];
  my $topics = $res->{topics};

  my ($keyboard, undef) = $self->_create_articles_keyboard(\@news, '');

  my $chosen_article = $news[$article_index - 1];

  if (!$chosen_article) {
    $self->{bot}->send_message({
      text => $self->{bot}{lang}{NO_NEWS_AT_THIS_NUM},
      reply_markup => {
        keyboard        => $keyboard,
        resize_keyboard => 'true'
      }
    });
    return 1;
  }

  my ($chosen_topic) = grep { $_->{id} == $chosen_article->{topic_id} } @$topics;

  my $title_icon = $chosen_article->{importance} ? $icons{pin} : $icons{title};
  my $message = "$title_icon <b>$chosen_article->{title}</b>\n";
  $message .= "$icons{topic} <b>$chosen_topic->{name}</b>\n";
  $message .= "$icons{date} <b>$chosen_article->{date}</b>\n";
  $message .= "\n";
  if ($chosen_article->{short_description}) {
    $message .= "$chosen_article->{short_description}\n";
    $message .= "\n";
  }
  $message .= qq{<a href='$chosen_article->{url}'>$icons{link} $self->{bot}{lang}{LINK_TO_ARTICLE}</a>};

  if ($chosen_article->{picture} && _check_picture_link($chosen_article->{picture})) {
   $self->{bot}->send_photo({
     caption      => $message,
     photo        => $chosen_article->{picture},
     reply_markup => {
       keyboard => $keyboard,
       resize_keyboard => "true",
     },
     disable_web_page_preview => 'true',
   })
  }
  else {
    $self->{bot}->send_message({
      text         => $message,
      reply_markup => {
        keyboard => $keyboard,
        resize_keyboard => "true",
      },
      disable_web_page_preview => 'true',
    });
  }
  return 1;
}

#**********************************************************
=head2 _create_articles_keyboard($news, $message)

=cut
#**********************************************************
sub _create_articles_keyboard {
  my $self = shift;
  my ($news, $message) = @_;

  my @keyboard = ();
  for my $i (0..$#$news) {
    my $article = $news->[$i];
    my $row_index = int($i / 4);
    $keyboard[$row_index] //= [];
    my $number = $i + 1;
    my $button = { text => $number };

    my $pin = $article->{importance} ? $icons{pin} : '';
    $message .= "<b>$number.</b> $pin <a href='$article->{url}'><b>$article->{title}</b></a>\n";
    $message .= "$icons{date} $article->{date}\n";
    $message .= "\n";
    push(@{$keyboard[$row_index]}, $button);
  }

  $message .= "\n";
  $message .= "$self->{bot}{lang}{ENTER_NEWS_NUMBER}";

  my $cancel_button = { text => $self->{bot}{lang}{CANCEL_TEXT} };

  push (@keyboard, [$cancel_button]);

  return (\@keyboard, $message);
}

#**********************************************************
=head2 _check_picture_link($picture_link)

=cut
#**********************************************************
sub _check_picture_link {
  my ($picture_link) = @_;

  # Telegram allow pictures only from main http/s port.
  if ($picture_link =~ ':\d+') {
    return 0;
  }

  return 1;
}

1;
