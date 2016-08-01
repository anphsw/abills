# billd plugin
=head1 NAME

  DESCRIBE: Add active users to online list

=cut
#**********************************************************

use Abills::Base qw(mk_unique_value);
our(
  $db,
  $Admin,
  %conf,
  $var_dir
);

stalker_online();

#**********************************************************
=head2 stalker_online($attr)

=cut
#**********************************************************
sub stalker_online {
  #my ($attr)=@_;

  use POSIX;
  use Iptv;
  use Tariffs;
  use Users;
  use Shedule;

  #my $users   = Users->new($db, $admin, \%conf);
  my $Iptv    = Iptv->new($db, $Admin, \%conf);
  my $Tariffs = Tariffs->new($db, \%conf, $Admin);
  my $Shedule = Shedule->new($db, $Admin);
  my $Log     = Log->new($db, $Admin);
  $Log->{LOG_FILE} = $var_dir . '/log/stalker_online.log';
  my %hangup_desr = ();
  print "Stalker STB online\n" if ($debug > 1);

  #eval { require Iptv::Stalker_api; };
  use Iptv::Stalker_api;

#  if (!$@) {
#    Stalker_api->import();
#    $Stalker_api = Stalker_api->new($db, $Admin, \%conf);
#  }
#  else {
#    print $@;
#    $html->message( 'err', $lang{ERROR}, "Can't load 'Stalker_api'. Purchase this module http://abills.net.ua" );
#    exit;
#  }

  my $Stalker_api = Iptv::Stalker_api->new($db, $Admin, \%conf);
  if ($debug > 7) {
    $nas->{debug}= 1 ;
    $Dv->{debug} = 1 ;
    $Stalker_api->{DEBUG}=1;
  }

  $Admin->{MODULE}='Iptv';
  #Get tp
  my %TP_INFO = ();
  my $list = $Tariffs->list({ AGE             => '_SHOW',
                              NEXT_TARIF_PLAN => '_SHOW',
                              COLS_NAME  => 1,
                              COLS_UPPER => 1,
                            });

  foreach my $line (@$list) {
    $TP_INFO{$line->{TP_ID}}=$line;
  }

  $LIST_PARAMS{LOGIN}     = $argv->{LOGINS} if ($argv->{LOGINS});

  # Get accounts
  my %USERS_LIST = ();
  $Iptv->{debug}=1 if ($debug > 6);
  $list = $Iptv->user_list({
                             COLS_NAME      => 1,
                             LOGIN          => '_SHOW',
                             CID            => '_SHOW',
                             ACTIVATE       => '_SHOW',
                             EXPIRE         => '_SHOW',
                             LOGIN_STATUS   => '_SHOW',
                             SERVICE_STATUS => '_SHOW',
                             NEXT_TARIF_PLAN=> '_SHOW',
                             IPTV_EXPIRE    => '_SHOW',
                             TP_ID          => '_SHOW',
                             CREDIT         => '_SHOW',
                             DEPOSIT        => '_SHOW',
                             %LIST_PARAMS,
                             PAGE_ROWS      => 1000000,
                           });

  foreach my $line (@$list) {
    $line->{cid} =~ s/[\n\r ]//g;
    foreach my $cid (split(/;/, $line->{cid})) {
      $USERS_LIST{$cid}=$line;
    }
  }

  my %USERS_ONLINE_LIST = ();
  $Iptv->{debug}=1 if ($debug > 6);
  $list = $Iptv->online({
                          COLS_NAME       => 1,
                          CID             => '_SHOW',
                          UID             => '_SHOW',
                          ACCT_SESSION_ID => '_SHOW',
                          FIO             => '_SHOW'
                          });

  foreach my $line (@$list) {
    if ($debug > 2) {
      print "$line->{CID} -> $line->{uid}:$line->{acct_session_id}\n";
    }

    if(! $line->{uid}) {
      if ($debug > 0) {
        print "Skip user: No uid, sid: $line->{acct_session_id}\n";
      }
      #next;
    }

    $USERS_ONLINE_LIST{$line->{CID}}="$line->{uid}:$line->{acct_session_id}";
  }

  #Get stalker info
  $Stalker_api->_send_request({ ACTION => "STB",
                               DEBUG  => ($debug > 6) ? $debug : undef
                             });

  if ($Stalker_api->{error}) {
    $Log->log_print('LOG_ERR', '', "Stalker error: $Stalker_api->{error}/$Stalker_api->{errstr}");
    return 0;
  }

  foreach my $account_hash ( @{ $Stalker_api->{RESULT}->{results} } ) {
    my @row = ();
    while( my(undef, $val)=each %{ $account_hash } ) {
      Encode::_utf8_off($account_hash->{name}) if ($account_hash->{name});

      if ( ref $val eq 'ARRAY') {
        my $col_values = '';
        foreach my $v (@$val) {
          if (ref $v eq 'HASH') {
            while(my($k, $v2) = each %$v) {
              $col_values .= " $k - $v2". $html->br();
            }
          }
          else {
            $col_values .= $v . $html->br();
          }
        }

        push @row, $col_values;
      }
      elsif ( ref $val eq 'HASH') {
        my $col_values = '';
        while(my($k, $v) = each %$val) {
          $col_values .= " $k - $v". $html->br();
        }
        push @row, $col_values;
      }
      else {
        push @row, "$val";
      }
    }

    $Log->log_print('LOG_DEBUG', '', "Stalker ls: $account_hash->{ls} IP: $account_hash->{ip} MAC: $account_hash->{mac} Online: $account_hash->{online}");

    if (! $account_hash->{online}) {
      my $user            = $USERS_LIST{$account_hash->{mac}};
      $hangup_desr{$user->{uid}}='User log off' if ($user->{uid});
      next;
    }

    #block with negative deposite
    #Hangup modem
    if (! $account_hash->{mac}) {
      #$Stalker_api->send_request({ ACTION => "STB",
      #                     });
      print "Skip" if ($debug > 1);
    }
    elsif (! $USERS_LIST{$account_hash->{mac}}) {
      $Log->log_print('LOG_WARNING', '', "Unknown mac: '$account_hash->{mac}' add mac to account '$account_hash->{login}'");

      #Add mac to account
      if ($account_hash->{login}) {
        my $u_list = $Iptv->user_list({ LOGIN => "$account_hash->{login}", COLS_NAME => 1 });

        if ($Iptv->{TOTAL}) {
          $Iptv->user_change({ ID => $u_list->[0]->{id},
                               CID => $account_hash->{mac}
                            });
          print " added" if ($debug > 1);
        }
        else {
          print " Not exist" if ($debug > 1);
        }
      }
      print "\n" if ($debug > 0);
    }
    # Update online
    elsif ($USERS_ONLINE_LIST{$account_hash->{mac}}) {
      $Log->log_print('LOG_DEBUG', '', "UPDATE online: $USERS_ONLINE_LIST{$account_hash->{mac}} mac: $account_hash->{mac}");

      my $user            = $USERS_LIST{$account_hash->{mac}};
      my $expire_unixdate = 0;
      if ($user->{expire} ne '0000-00-00') {
        my ($expire_y, $expire_m, $expire_d)=split(/\-/, $user->{expire}, 3);
        $expire_unixdate = mktime(0, 0, 0, $expire_d, ($expire_m-1), ($expire_y - 1900));
        $expire_unixdate = ($expire_unixdate < time) ? 1 : 0;
      }
      elsif ($user->{iptv_expire} ne '0000-00-00') {
        my ($expire_y, $expire_m, $expire_d)=split(/\-/, $user->{iptv_expire}, 3);
        $expire_unixdate = mktime(0, 0, 0, $expire_d, ($expire_m-1), ($expire_y - 1900));
        $expire_unixdate = ($expire_unixdate < time) ? 1 : 0;
      }

      my $credit = ($user->{credit} > 0) ? $user->{credit} : $TP_INFO{$user->{tp_id}}->{CREDIT};
      if (($TP_INFO{$user->{tp_id}}->{PAYMENT_TYPE}==0 && $user->{deposit}+$credit <= 0)
          || $user->{login_status}
          || $user->{iptv_status}
          || $expire_unixdate
      ) {
        $hangup_desr{$user->{uid}}="Neg deposit ". sprintf("%.2f Credit: %.2f", $user->{deposit}, $credit);
        if ($account_hash->{status} == 0) {
          delete($USERS_ONLINE_LIST{$account_hash->{mac}});
          next;
        }
        $Admin->action_add("$user->{uid}", "$account_hash->{mac}", { TYPE => 15 });

        print "Disable STB LOGIN: $user->{login} MAC: $account_hash->{mac} Expire: $expire_unixdate DEPOSIT: $user->{deposit}+$credit STATUS: $user->{login_status}/$user->{service_status}\n";
        $Stalker_api->user_action({ UID    => $user->{uid},
                                    FIO    => $user->{fio},
                                    LOGIN  => $user->{login},
                                    STATUS => 1,
                                    change => 1 });
      }
      else {
        my ($uid, $acct_session_id)=split(/:/, $USERS_ONLINE_LIST{$account_hash->{mac}});
        $Iptv->online_update({
           ACCT_SESSION_ID => $acct_session_id,
           UID             => $uid,
           CID             => $account_hash->{mac},
           GUEST           => ($account_hash->{status} == 0) ? 1 : 0
        });

        if ($account_hash->{status} == 0) {
          $Stalker_api->user_action({ UID    => $user->{uid},
                                      FIO    => $user->{fio},
                                      LOGIN  => $user->{login},
                                      STATUS => 0,
                                      change => 1 
                                    });
        }

        delete $USERS_ONLINE_LIST{$account_hash->{mac}};
      }
    }
    #add online
    else {
      my $user = $USERS_LIST{$account_hash->{mac}};

      if (! $user->{tp_id}) {
        $Log->log_print('LOG_WARNING', $USERS_LIST{$account_hash->{mac}}->{login}, "ADD online: MAC: $account_hash->{mac} Unknown TP");
      }
      else {
        $Iptv->online_add({
             UID    => $user->{uid},
             IP     => $account_hash->{ip} || '0.0.0.0',
             NAS_ID => 0,
             STATUS => 1,
             TP_ID  => $user->{tp_id},
             CID    => $account_hash->{mac},
             ACCT_SESSION_ID=> mk_unique_value(12),
             GUEST  => ($account_hash->{status} == 0) ? 1 : 0
        });

        $Log->log_print('LOG_NOTICE', $user->{login}, "ADD online: MAC: $account_hash->{mac} Online: $account_hash->{online}");

        if ($TP_INFO{$user->{tp_id}}->{AGE} && $user->{expire} eq '0000-00-00') {
          my $expire_date = POSIX::strftime("%Y-%m-%d", localtime(time + $TP_INFO{$user->{tp_id}}->{AGE} * 86400));

          $Log->log_print('LOG_DEBUG', $user->{login}, "ADD EXPIRE: $expire_date TP_AGE: $TP_INFO{$user->{tp_id}}->{AGE}");

          if ($TP_INFO{$user->{tp_id}}->{NEXT_TP_ID}) {
            my ($year, $month, $day)=split(/\-/, $expire_date, 3);

            $Shedule->add(
               {
                UID          => $user->{uid},
                TYPE         => 'tp',
                ACTION       => $user->{tp_id},
                D            => $day,
                M            => $month,
                Y            => $year,
                COMMENTS    => "$lang{FROM}: $user->{tp_id}:$user->{TP_NAME}",
                ADMIN_ACTION => 1,
                MODULE       => 'Iptv'
              }
            );
           }
          else {
            $Iptv->user_change({ UID    => $user->{id},
                                 EXPIRE => $expire_date,
                                });
          }
        }
      }
    }

    print join('; ', @row) . "\n" if ($debug > 5);
  }

  #Del old sessions
  if (scalar %USERS_ONLINE_LIST ) {
    my $del_list = join(',', keys %USERS_ONLINE_LIST) ;
    $Iptv->online_del({ CID => [ keys %USERS_ONLINE_LIST ] });
    $Log->log_print('LOG_DEBUG', undef, "Delete: $del_list");

    foreach my $mac ( keys %USERS_ONLINE_LIST ) {
      my ($uid, $acct_session_id)=split(/:/, $USERS_ONLINE_LIST{$mac});
      #Hangup stb box
      $Stalker_api->_send_request({ ACTION  => "send_event/".$uid,
                                    event   => 'cut_off',
                                  });

      #Disable account
      #$Stalker_api->user_action({ UID    => $uid,
      #                            FIO    => $user->{fio},
      #                            LOGIN  => $user->{login},
      #                            STATUS => 1,
      #                            change => 1 });

      if ($Stalker_api->{errno}) {
        $Log->log_print('LOG_ERR', $uid, "Hangup Error: UID: $uid MAC: $mac [$Stalker_api->{errno}] $Stalker_api->{errstr}");
      }
      else {
     	  $Log->log_print('LOG_INFO', $uid, "Hangup: $mac ($hangup_desr{$uid}) Session: $acct_session_id");
      }
    }
  }

  return 1;
}


1
