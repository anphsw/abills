package Viber::Buttons;

=head1 NAME

  Viber button

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/gen_time/;

#**********************************************************
=head2 new($attr)

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
=head2 buttons_list()
  
=cut
#**********************************************************
sub buttons_list {
  my $self = shift;
  my @buttons_files = glob "$main::base_dir/Abills/modules/Viber/buttons/*.pm";
  my %BUTTONS = ();
  my $err = '';

  foreach my $file (@buttons_files) {
    my (undef, $button) = $file =~ m/(.*)\/(.*)\.pm/;

    eval {
      require "Viber/buttons/$button.pm";

      my $obj = "Viber::buttons::$button"->new(
        @$self{qw(conf bot bot_db api user_config)}
      );
      if ($obj->can('enable') && $obj->enable()) {
        if ($obj->can('btn_name')) {
          $BUTTONS{$button} = $obj->btn_name();
        }
      }
    };

    if ($@) {
      $err .= $@ . "\n";
      $@ = undef;
    }
  }

  return (\%BUTTONS, $err);
}

#**********************************************************
=head2 viber_button_fn($attr)

  Arguments:
     $attr
       button - button pm file
       fn     - button function

  Return:
    1 or 0

=cut
#**********************************************************
sub viber_button_fn {
  my $self = shift;
  my ($attr) = @_;

  my $button = $attr->{button};
  my $fn = $attr->{fn};

  my $ret = 0;

  eval {
    require "Viber/buttons/$button.pm";
    my $obj = "Viber::buttons::$button"->new($self->{conf}, $self->{bot}, $self->{bot_db}, $self->{api}, $self->{user_config});
    if ($obj->can($fn)) {
      $ret = $obj->$fn($attr);
    }
  };

  if ($@) {
    my $message = "*$self->{bot}{lang}{ERROR}*\n";
    if ($self->{conf}{VIBER_DEBUG}) {
      $message .= "\n";
      $message .= "$@"
    }
    $self->{bot_db}->del($self->{bot}->{receiver});
    $self->{bot}->send_message({ text => $message })
  }

  if ($self->{conf}{USER_FN_BOTS_LOG}) {
    require Log;
    Log->import();
    my $user_fn_log = $self->{conf}{USER_FN_BOTS_LOG};
    my $Log = Log->new($main::db, $self->{conf}, { LOG_FILE => $user_fn_log });
    my $time = gen_time($main::begin_time, { TIME_ONLY => 1 });
    $Log->log_print('LOG_INFO', 'VIBER', "$self->{bot}{receiver}:$button->$fn:$time", { LOG_LEVEL => 6 });
  }

  return $ret;
}

1;
