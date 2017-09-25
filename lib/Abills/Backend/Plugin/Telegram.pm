package Abills::Backend::Plugin::Telegram;
use strict;
use warnings FATAL => 'all';

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Encode;
use utf8;

use Abills::Backend::Plugin::BasePlugin;
use parent 'Abills::Backend::Plugin::BasePlugin';
use Abills::Backend::Plugin::Telegram::API;

our Admins $admin;
our (%conf, $db, $base_dir);

BEGIN {
  use Abills::Backend::Defs;
}

use Abills::Backend::Plugin::Telegram::BotAPI;
use Abills::Backend::Plugin::Telegram::Operation;
use Abills::Backend::Plugin::Telegram::ModuleInterface;

use Contacts;
use Users;
my $Contacts = Contacts->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);

use Data::Dumper;
use Abills::Base qw/_bp/;
_bp('', '', { SET_ARGS => { TO_CONSOLE => 1 } });

use Abills::Backend::Log;
my $log_file = $conf{TELEGRAM_LOG} || (($base_dir || '/usr/abills') . '/var/log/telegram.log');
my $debug = $conf{TELEGRAM_DEBUG} || 3;
my $Log = Abills::Backend::Log->new('FILE', $debug, 'Telegram main', { FILE => $log_file });

my $Bot_API;

my %user_for_chat_id = ();
my %admin_for_chat_id = ();

# Operation will get all messages for client while in 'locked' mode
my %operation_lock_on_chat_id = ();


#**********************************************************
=head2 new()

=cut
#**********************************************************
sub new {
  my $class = shift;
  
  my $self;
  $self = {
    token          => $conf{TELEGRAM_TOKEN},
    last_update_id => 0,
    config         => \%conf,
    debug          => $debug,
    cb             => {
      'default'  => sub {
        $self->action_unknown_command(@_);
      },
      '/balance' => sub {
        my $message = shift;
        $self->send_text("Sorry, but I can't do it now", $message->{chat}->{id});
      },
      '/hello'   => sub {
        my $message = shift;
        $self->action_greetings($message->{chat}->{id});
      }
    }
  };
  
  bless($self, $class);
  return $self;
}

#**********************************************************
=head2 init() - begins Telegram API work

  Returns:
    1
    
=cut
#**********************************************************
sub init {
  my ( $self ) = @_;
  
  $Bot_API = Abills::Backend::Plugin::Telegram::BotAPI->new (\%conf, {
      token => $self->{token},
      debug => $self->{debug}
    });
  
  # Set renew clients every 5 min
  $self->{renew_clients_timer} = AnyEvent->timer(
    after    => 1,
    interval => 600,
    cb       => sub {
      # Get authorized clients
      $Log->info('Renewing contact info');
      $self->load_clients();
    }
  );
  
  if ( $conf{TELEGRAM_LOAD_EXTENSIONS} ) {
    my @extension_files = split(',\s', $conf{TELEGRAM_LOAD_EXTENSIONS});
    foreach my $extension ( @extension_files ) {
      eval {
        require "Abills/Backend/Plugin/Telegram/Extension/$extension.pm";
        "Abills::Backend::Plugin::Telegram::Extension::$extension"->import();
        
        my $add_callback_func = "Abills::Backend::Plugin::Telegram::Extension::$extension\::add_extensions";
        my $ref = \&{$add_callback_func};
        &{$ref}($self);
        
        $Log->info("Loaded $extension extension");
      };
      if ( $@ ) {
        $Log->warning("Can't load $extension extension. $@");
      }
    }
  }
  
  $self->set_timer($self->{config}->{$conf{TELEGRAM_API_REQUEST_INTERVAL}} || 3);
  
  return Abills::Backend::Plugin::Telegram::API->new($self->{config}, $self);
}

#**********************************************************
=head2 set_timer()

=cut
#**********************************************************
sub set_timer {
  my ($self, $interval) = @_;
  
  $self->{timer} = AnyEvent->timer(
    after    => 0,
    interval => $interval,
    cb       => sub {
      $Log->debug("Requesting updates");
      
      eval {
        $Bot_API->getUpdates(
          {
            offset  => $self->{last_update_id} + 1,
            timeout => ($interval > 1 ? $interval - 1 : 1)
          },
          sub {
            my $updates = shift;
            
            if ( $updates->{ok} && $updates->{ok} == 1 ) {
              if ( $updates->{result} && ref $updates->{result} eq 'ARRAY' ) {
                $self->process_updates(@{$updates->{result}});
                return;
              }
            }
            
            if ( $updates->{error_code} ) {
              my $text = $updates->{description} || 'Unknown error';
              my $code = $updates->{error_code} || '-1';
              
              $Log->warning("Error on request. $code : $text");
              
              if ( $code eq '401' ) {
                $Log->alert($text . '. Stopping to request Telegram updates');
                $Log->alert('Check $conf{TELEGRAM_TOKEN}');
                delete $self->{timer};
              }
              
              return;
            }
            else {
              $Log->warning('Error on request : Unknown error');
            }
            
          }
        );
        
      };
      if ( $@ ) {
        $Log->error("Can't get updates : " . $@);
      }
    });
  
}

#**********************************************************
=head2 add_callback($message, $cb)

=cut
#**********************************************************
sub add_callback {
  my ($self, $message, $cb) = @_;
  $self->{cb}->{$message} = $cb;
  return 1;
}

#**********************************************************
=head2 remove_callback()

=cut
#**********************************************************
sub remove_callback {
  my ($self, $name) = @_;
  delete $self->{cb}->{$name};
  return 1;
}

#**********************************************************
=head2 process_updates()

=cut
#**********************************************************
sub process_updates {
  my ($self, @updates) = @_;
  
  # Show message
  foreach my $update ( @updates ) {
    # Sometimes telegram send old (already processed) updates
    next if ( $self->{last_update_id} && $update->{update_id} <= $self->{last_update_id} );
    
    $self->{last_update_id} = $update->{update_id};
    
    my $message = $update->{message};
    #    print Dumper($update) if ( $self->{debug} > 4 );
    #    print Dumper($message) if ( $self->{debug} > 3 );
    #
    #    if ( $message->{contact} ) {
    #      print "Got phone: $message->{contact} $message->{contact}->{phone_number} \n";
    #      next;
    #    }
    
    if ( exists $update->{callback_query}
      && $update->{callback_query}->{from}
      && $update->{callback_query}->{from}->{id}
    ) {
      my $chat_id = $update->{callback_query}->{from}->{id};
      
      my $authorized = $self->is_authenticated($chat_id);
      
      unless ( $authorized ) {
        $Log->debug("Unathorized callback query message from $chat_id");
        return 0;
      };
      
      my $client_type = ($authorized < 0) ? 'UID' : 'AID';
      my $client_id = ($authorized < 0) ? $user_for_chat_id{$chat_id} : $admin_for_chat_id{$chat_id};
      
      $Log->debug("Got callback data request for $client_type#$client_id");
      
      return $self->process_callback_query(
        $update->{callback_query},
        {
          CHAT_ID     => $chat_id,
          CLIENT_TYPE => $client_type,
          CLIENT_ID   => $client_id
        }
      );
    }
    
    $message->{text} //= '';
    my $chat_id = $message->{chat}->{id} || 'unknown_chat_id';
    
    # Check for start command
    if ( $message->{text} =~ /^\/start/ ) {
      if ( $message->{text} =~ /\/start ([ua])_([a-zA-Z0-9]+)/ ) {
        my $type = $1;
        my $sid = $2;
        
        $Log->notice("Auth for $type $sid");
        
        if ( $self->authenticate($type, $sid, $chat_id) ) {
          $Log->notice("Registered $type $chat_id  $sid");
          $self->send_text("You've been registered", $chat_id);
          $Pub->emit('user_authenticated', $chat_id);
          next;
        }
      }
      
      my $username = $message->{from}->{firstname} || $message->{from}->{username} || '';
      $Log->notice("Auth failed for $username ($chat_id)");
      $self->send_text("Sorry, $username, can't authorize you. Please log in to web interface and try again",
        $chat_id);
      
      return 0;
    }
    
    my $authorized = $self->is_authenticated($chat_id);
    # Check if we have such a client
    if ( !$authorized ) {
      $self->send_text("Unauthorized", $chat_id);
    }
    else {
      
      if ( exists $operation_lock_on_chat_id{$chat_id} ) {
        $Log->notice("Sending message to operation ($chat_id)");
        
        my Abills::Backend::Plugin::Telegram::Operation $operation = $operation_lock_on_chat_id{$chat_id};
        
        my $should_finish = ($message->{text} eq '/cancel' || $operation->on_message($message));
        if ( $should_finish ) {
          $operation->on_finish();
          delete $operation_lock_on_chat_id{$chat_id};
          $Log->debug("Finished operation for $chat_id");
        }
        
        return 1;
      }
      
      my $client_type = ($authorized < 0) ? 'UID' : 'AID',;
      my $client_id = ($authorized < 0) ? $user_for_chat_id{$chat_id} : $admin_for_chat_id{$chat_id};
      
      my $message_text = $message->{text} || '';
      
      # Differentiate a command with data
      if ( $message_text =~ /^(\/[a-z]+)/ ) {
        $message_text = $1;
      }
      
      $Log->debug("Message from $chat_id ($client_type#$client_id)");
      
      if ( defined $self->{cb}->{$message_text} ) {
        eval {
          my $res = $self->{cb}->{$message_text}->($message, $chat_id, $client_type, $client_id);
          
          if ($res && $res->isa('Abills::Backend::Plugin::Telegram::Operation')){
            $operation_lock_on_chat_id{$chat_id} = $res;
            $res->start();
          }
        };
        if ( $@ ) {
          $Log->notice("Error happened while processing message : $@");
        }
      }
      else {
        $self->{cb}->{default}->($message, $chat_id, $client_type, $client_id);
      }
      
    }
  };
  
  return $self->{last_update_id};
}

#**********************************************************
=head2 process_callback_query($query) - processes update got from message button

  Arguments:
    $query -
    
  Returns:
  
  
=cut
#**********************************************************
sub process_callback_query {
  my ($self, $query, $attr) = @_;
  
  return 0 unless ( $attr->{CHAT_ID} );
  
  # TODO: Check if already in operation
  
  my $data_raw = $query->{data};
  return 0 unless ( $data_raw );
  
  my (@data) = split(':', $data_raw);
  my $module = shift @data;
  
  return 0 unless ( $module );
  
  $attr->{callback_query_id} = $query->{id};
  my Abills::Backend::Plugin::Telegram::Operation $operation = 0;
  
  if ( uc $module eq 'MSGS' ) {
    $Log->info("Callback query for MSGS");
    $operation = Abills::Backend::Plugin::Telegram::ModuleInterface::process_data($self, \@data, $attr);
  }
  return 0 unless ( $operation );
  
  # Set lock ( all messages will go to operation )
  $operation_lock_on_chat_id{$attr->{CHAT_ID}} = $operation;
  
  $operation->start();
  
  return 1;
}


#**********************************************************
=head2 is_authenticated($chat_id) - checks if is authorized

  Arguments:
    $chat_id - chat_id to check
    
  Returns:
    -1 for user
    1 for admin
    0 if not authorized
    
=cut
#**********************************************************
sub is_authenticated {
  my ($self, $chat_id) = @_;
  
  return - 1 if ( exists $user_for_chat_id{$chat_id} );
  return 1 if ( exists $admin_for_chat_id{$chat_id} );
  
  return 0;
}

#**********************************************************
=head2 send_text($text) - sends text to admin

  Arguments:
    $text -
    
  Returns:
    1 if sent
    
=cut
#**********************************************************
sub send_text {
  my ($self, $text, $chat_id, $telegram_message_options, $callback) = @_;
  
  if ( !$chat_id ) {
    print " Have to send response without \$chat_id. No \n" if ( $self->{debug} );
    return;
  }
  
  $Log->debug("Sending message to $chat_id");
  
  my $result_callback = $callback // sub {
    my $res = shift || 0;
    $Log->debug("Sent message to $chat_id : $res");
    
    if ( $callback ) {
      $callback->($res);
    }
  };
  
  $Bot_API->sendMessage({
      chat_id => $chat_id,
      text    => $self->format_text($text),
      %{ $telegram_message_options // {} },
    }, $result_callback
  );
  
}

#**********************************************************
=head2 send_callback_answer($chat_id, $callback_query_id, $text) - answer and close callback query

  Arguments:
    $chat_id
    $callback_query_id
    $text
    
  Returns:
  
  
=cut
#**********************************************************
sub send_callback_answer {
  my ($self, $callback_query_id, $text ) = @_;
  
  if ( !$callback_query_id ) {
    print " Have to send response without \$callback_query_id. No \n" if ( $self->{debug} );
    return;
  }
  
  $Log->debug("Answer to callback");
  
  $Bot_API->answerCallbackQuery({
      callback_query_id => $callback_query_id,
      text              => $self->format_text($text)
    }, sub {
      $Log->debug("Answered to callback");
    }
  );
}

#**********************************************************
=head2 format_text($text, $language) - translation and format text before sending

  Arguments:
    $text, $language -
    
  Returns:
  
  
=cut
#**********************************************************
sub format_text {
  my ($self, $text, $language) = @_;
  
  my $current_language = $conf{default_language} || $language || 'russian';
  
  if ( !exists $self->{languages}->{$current_language} ) {
    my $main_lang_file = ($base_dir || '/usr/abills') . "/language/$current_language.pl";
    $self->load_language_file($current_language, $main_lang_file) || return $text;
  }
  
  while ( $text && $text =~ /\_\{(\w+)\}\_/ ) {
    my $to_translate = $1 or next;
    my $translation = $self->{languages}->{$current_language}->{$to_translate} || "{$to_translate}";
    
    $text =~ s/\_\{$to_translate\}\_/$translation/sg;
  }
  #  Encode::_utf8_off($text);
  
  return $text;
}

#**********************************************************
=head2 load_language_file($lang_name, $file_path) - loads and saves lang hash

  Arguments:
    $lang_name -
    $file_path -
    
  Returns:
    1 if loaded
    
=cut
#**********************************************************
sub load_language_file {
  my ($self, $lang_name, $file_path) = @_;
  
  eval {
    
    our %lang = ();
    $Log->debug("Loading $file_path");
    
    if ( !-f $file_path ) {
      $Log->alert("No such lang file : $file_path");
      return 0;
    }
    
    do $file_path;
    
    if ( exists $self->{languages}->{$lang_name} && ref $self->{languages}->{$lang_name} eq 'HASH' ) {
      $self->{languages}->{$lang_name} = { %{$self->{languages}->{$lang_name}}, %lang };
    }
    else {
      $self->{languages}->{$lang_name} = \%lang;
    }
    
  };
  if ( $@ ) {
    $Log->critical("Can't load $file_path language");
    return 0;
  }
  
  return 1;
}


#**********************************************************
=head2 action_show_message($message_obj) - simply prints to console

  Arguments:
    $message_obj -
    
  Returns:
  
  
=cut
#**********************************************************
sub action_show_message {
  my ($self, $message) = @_;
  
  if ( $self->{debug} > 5 ) {
    print Dumper $message;
    return 1;
  }
  
  eval {
    my $name = ($message->{from}->{username} ? $message->{from}->{username} : "$message->{from}->{first_name}");
    print "#$message->{message_id} $name ($message->{from}->{id}) \n$message->{text} \n";
  };
  if ( $@ ) {
    print $@ . "\n";
  }
  
  return 1;
}


#**********************************************************
=head2 action_greetings($chat_id) - Greets given recipient

  Arguments:
    $chat_id -
    
  Returns:
  
  
=cut
#**********************************************************
sub action_greetings {
  my ($self, $chat_id) = @_;
  
  if ( exists $user_for_chat_id{$chat_id} ) {
    $self->send_text("Hello, user", $chat_id);
  }
  elsif ( exists $admin_for_chat_id{$chat_id} ) {
    $self->send_text("Hello, admin", $chat_id);
  }
  
  return 1;
}

#**********************************************************
=head2 action_unknown_command($message) - actions defined for undefined command

  Arguments:
    $message -
    
  Returns:
  
  
=cut
#**********************************************************
sub action_unknown_command {
  my ($self, $message) = @_;
  
  my $chat_id = $message->{chat}->{id};
  
  # Got 'Wide character ...' without this
  Encode::_utf8_off($message->{text});
  
  $Log->debug("Don't know how should respond for: $message->{text}\n");
  
  $self->action_show_message($message);
  $self->send_text("Sorry, can't understand you", $chat_id);
  
  # Maybe : show commands
  
  return;
}

#**********************************************************
=head2 authenticate($type, $sid) - authenticates new Telegram receiver

  Arguments:
    $type - u|a
    $sid  -
    
  Returns:
  
  
=cut
#**********************************************************
sub authenticate {
  my ($self, $type, $sid, $chat_id) = @_;
  
  if ( $type eq 'u' ) {
    my $uid = $Users->web_session_find($sid);
    
    if ( $uid ) {
      
      # Check if already have an account
      my $list = $Contacts->contacts_list({
        TYPE  => $Contacts::TYPES{TELEGRAM},
        VALUE => $chat_id,
      });
      
      if ( !$Contacts->{TOTAL} || scalar (@{$list}) == 0 ) {
        $Contacts->contacts_add({
          UID      => $uid,
          TYPE_ID  => $Contacts::TYPES{TELEGRAM},
          VALUE    => $chat_id,
          PRIORITY => 0,
        });
      }
      $user_for_chat_id{$chat_id} = $uid;
      return 1;
    }
    return 0;
  }
  elsif ( $type eq 'a' ) {
    my $aid = $admin->online_find($sid);
    
    if ( $aid ) {
      
      my $list = $admin->admins_contacts_list({
        TYPE  => $Contacts::TYPES{TELEGRAM},
        VALUE => $chat_id
      });
      
      if ( !$admin->{TOTAL} || scalar (@{$list}) == 0 ) {
        $admin->admin_contacts_add({
          AID      => $aid,
          TYPE_ID  => $Contacts::TYPES{TELEGRAM},
          VALUE    => $chat_id,
          PRIORITY => 0,
        });
      }
      
      $admin_for_chat_id{$chat_id} = $aid;
      return 1;
    }
    return 0;
  }
  
  return;
}

#**********************************************************
=head2 load_clients() - reads registered contacts from DB (contacts)

=cut
#**********************************************************
sub load_clients {
  
  my $client_telegram_accounts = $Contacts->contacts_list({
    TYPE  => $Contacts::TYPES{TELEGRAM},
    VALUE => '_SHOW',
    UID   => '_SHOW'
  });
  foreach ( @{$client_telegram_accounts} ) {
    $user_for_chat_id{$_->{value}} = $_->{uid};
  }
  
  my $admin_telegram_accounts = $admin->admins_contacts_list({
    TYPE  => $Contacts::TYPES{TELEGRAM},
    VALUE => '_SHOW',
    AID   => '_SHOW'
  });
  foreach( @{$admin_telegram_accounts} ) {
    $admin_for_chat_id{$_->{value}} = $_->{aid};
  }
  
}

1;