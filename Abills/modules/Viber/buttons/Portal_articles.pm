package Viber::buttons::Portal_articles;

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

  my $message = "$icons{article} *$self->{bot}{lang}{NEWS}*\n";
  $message .= "\n";

  my ($keyboard, $edited_message) = $self->_create_articles_keyboard(\@news, $message);

  $self->{bot}->send_message({
    text                     => $edited_message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => $keyboard,
    }
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
    $self->{bot}->send_message({ text => $self->{bot}{lang}{ENTER_NEWS_NUMBER}});
    return 1;
  };

  my $article_index = $text;

  my ($res) = $self->{api}->fetch_api({ PATH => '/user/portal/news' });

  if ($res->{errno} || !scalar(@{$res->{news}})) {
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
      keyboard => {
        Type          => 'keyboard',
        DefaultHeight => 'true',
        Buttons       => $keyboard,
      }
    });
    return 1;
  }

  my ($chosen_topic) = grep { $_->{id} == $chosen_article->{topic_id} } @$topics;

  my $title_icon = $chosen_article->{importance} ? $icons{pin} : $icons{title};
  my $message = "$title_icon *$chosen_article->{title}*\n";
  $message .= "$icons{topic} *$chosen_topic->{name}*\n";
  $message .= "$icons{date} ```$chosen_article->{date}```\n";
  $message .= "\n";
  if ($chosen_article->{short_description}) {
    $message .= "$chosen_article->{short_description}\n";
    $message .= "\n";
  }
  $message .= "$icons{link} $self->{bot}{lang}{LINK_TO_ARTICLE}\n";
  $message .= $chosen_article->{url};

  my $props = {
    text         => $message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => $keyboard,
    }
  };
  if ($chosen_article->{picture} && _check_picture_link($chosen_article->{picture})) {
    $props->{media} = $chosen_article->{picture};
    $props->{type} = 'picture';
  }

  $self->{bot}->send_message($props);
  
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
  my $columns = scalar(@$news) > 4 ? 2 : 3;

  for my $i (0..$#$news) {
    my $article = $news->[$i];
    my $number = $i + 1;
    my $button = {
      Columns    => $columns,
      Rows       => 1,
      Text       => "#$number",
      ActionType => 'reply',
      ActionBody => "fn:Portal_articles&choose_article&$number",
      TextSize   => 'regular'
    };

    my $pin = $article->{importance} ? $icons{pin} : '';
    $message .= "*$number.* $pin *$article->{title}*\n";
    $message .= "$icons{date} ```$article->{date}```\n";
    $message .= "\n";
    push(@keyboard, $button);
  }

  $message .= "\n";
  $message .= "$self->{bot}{lang}{CHOOSE_NEWS_NUMBER}";

  my $cancel_button = {
    Text => $self->{bot}{lang}{CANCEL_TEXT},
    ActionType => 'reply',
    ActionBody => 'fn:Portal_articles&cancel',
    TextSize   => 'regular'
  };
  push (@keyboard, $cancel_button);

  return (\@keyboard, $message);
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
=head2 _check_picture_link($picture_link)

=cut
#**********************************************************
sub _check_picture_link {
  my ($picture_link) = @_;

  # Viber allow pictures only from main http/s port.
  if ($picture_link =~ ':\d+') {
    return 0;
  }

  return 1;
}

1;
