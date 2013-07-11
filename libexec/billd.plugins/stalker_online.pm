# billd plugin
#
# DESCRIBE: Add active users to online list
#
#**********************************************************

stalker_online();

#**********************************************************
#
#
#**********************************************************
sub stalker_online {
  my ($attr)=@_;

  use POSIX;  
  use Iptv;
  use Tariffs;
  use Users;
  use Shedule;
  
  my $users   = Users->new($db, $admin, \%conf);
  my $Iptv    = Iptv->new($db, $admin, \%conf);
  my $Tariffs = Tariffs->new($db, \%conf, $admin);
  my $Shedule = Shedule->new($db, $admin);
  
  print "Stalker STB online\n" if ($debug > 1);

  if ($debug > 7) {
    $nas->{debug}= 1 ;
    $Dv->{debug} = 1 ;
    $sessions->{debug}=1;
  }

  eval { require "modules/Iptv/Stalker_api.pm"; };

  if (!$@) {
    eval { require "modules/Iptv/Stalker_api.pm"; };
    Stalker_api->import();
    $Stalker_api = Stalker_api->new($db, $admin, \%conf);
  }
  else {
    print $@;
    $html->message('err', $_ERROR, "Can't load 'Stalker_api'. Purchase this module http://abills.net.ua");
    exit;
  }

  $admin->{MODULE}='Iptv';
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

  $LIST_PARAMS{LOGIN}     = $ARGV->{LOGINS} if ($ARGV->{LOGINS});

  # Get accounts
  my %USERS_LIST = ();
  $Iptv->{debug}=1 if ($debug > 6);
  $list = $Iptv->user_list({ PAGE_ROWS      => 1000000, 
                             COLS_NAME      => 1,
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
                             %LIST_PARAMS
                           });

  foreach my $line (@$list) {
    $line->{cid} =~ s/[\n\r ]//g;
    foreach my $cid (split(/;/, $line->{cid})) {
      $USERS_LIST{$cid}=$line;
      #"$line->{uid};$line->{tp_id};$line->{activate}";
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
    $USERS_ONLINE_LIST{$line->{CID}}="$line->{uid}:$line->{acct_session_id}";
  }
 
  #Get stalker info  
  $Stalker_api->send_request({ ACTION => "STB",
                             });

  if ($Stalker_api->{error}) {
    $html->message('err', $_ERROR, "$Stalker_api->{error}/$Stalker_api->{errstr} ");
  }

  foreach my $account_hash ( @{ $Stalker_api->{RESULT}->{results} } ) {
    my @row = ();
    while( ($key, $val)=each %{ $account_hash } ) {
      Encode::_utf8_off($account_hash->{name}) if ($account_hash->{name});

      if ( ref $val eq 'ARRAY') {
        my $col_values = '';
        foreach my $v (@$val) {
          if (ref $v eq 'HASH') {
            while(my($k, $v) = each %$v) {
              $col_values .= " $k - $v". $html->br();
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
    
    if (! $account_hash->{online}) {
      next;
    }
    
    #block with negative deposite
    if (! $USERS_LIST{$account_hash->{mac}}) {
      print "Unknown mac: $account_hash->{mac} add mac to account '$account_hash->{login}'" if ($debug > 0);
      
      #Hangup modem
      if (! $account_hash->{mac}) {
         #$Stalker_api->send_request({ ACTION => "STB",
        #                     });
        print "Skip" if ($debug > 1);
      }
      #Add mac to account
      elsif ($account_hash->{login}) {
        my $u_list = $users->list({ LOGIN => "$account_hash->{login}", COLS_NAME => 1 });
        if ($users->{TOTAL}) {
          $Iptv->user_change({ UID => $u_list->[0]->{uid},
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
    elsif ($account_hash->{mac} && $USERS_ONLINE_LIST{$account_hash->{mac}}) {
      print "UPDATE online: $USERS_ONLINE_LIST{$account_hash->{mac}} mac: $account_hash->{mac}\n" if ($debug > 2);
      
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

      if (($TP_INFO{$user->{tp_id}}->{PAYMENT_TYPE}==0 && $user->{deposit}+$credit < 0)
          || $user->{login_status}
          || $user->{iptv_status}
          || $expire_unixdate
      ) {
        
        if ($account_hash->{status} == 0) {
          next;
        }
        
        $admin->action_add("$user->{uid}", "$account_hash->{mac}", { TYPE => 15 });
        print "Disable STB LOGIN: $user->{login} MAC: $account_hash->{mac} Expire: $expire_unixdate DEPOSIT: $user->{deposit}+$credit STATUS: $user->{disable}/$user->{iptv_status}\n";
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
           CID             => $account_hash->{mac}
        });


        if ($account_hash->{status} == 0) {
          $Stalker_api->user_action({ UID    => $user->{uid},
                                    FIO    => $user->{fio},
                                    LOGIN  => $user->{login},
                                    STATUS => 0,
                                    change => 1 });
        }

        delete $USERS_ONLINE_LIST{$account_hash->{mac}};
      }
    }
    #add online
    else {
       my $user = $USERS_LIST{$account_hash->{mac}};
        
       if (! $user->{tp_id}) {
         print "ADD online: Login: $USERS_LIST{$account_hash->{mac}}->{login} MAC: $account_hash->{mac} Unknown TP\n" if ($debug > 0);
       }
       else {
         $Iptv->online_add({ 
              UID    => $user->{uid},
              IP     => '0.0.0.0',
              NAS_ID => 0,
              STATUS => 1,
              TP_ID  => $user->{tp_id},
              CID    => $account_hash->{mac},
              ACCT_SESSION_ID=> mk_unique_value(12),
          });
        print "ADD online: Login: $user->{login} MAC: $account_hash->{mac} Online: $account_hash->{online}\n" if ($debug > 1);
        
        if ($TP_INFO{$user->{tp_id}}->{AGE} && $user->{expire} eq '0000-00-00') {
          my $expire_date = strftime "%Y-%m-%d", localtime(time + $TP_INFO{$user->{tp_id}}->{AGE} * 86400);
          print "ADD EXPIRE: $expire_date TP_AGE: $TP_INFO{$user->{tp_id}}->{AGE}\n" if ($debug > 2);
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
                COMMENTS     => "$_FROM: $user->{tp_id}:$TP_INFO->{TP_NAME}",
                ADMIN_ACTION => 1,
                MODULE       => 'Iptv'
              }
            );            
          }
          else {
            $Iptv->user_change({ UID    => $user->{uid}, 
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
    $Iptv->online_del({ CID => join(',', keys %USERS_ONLINE_LIST) });
  }

}




1
