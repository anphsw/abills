=head NAME


=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array);

our(
  $Iptv,
  %FORM,
  $html,
  %lang,
  $db,
  %conf,
  $admin,
  %permissions,
  @MONTHES_LIT,
  $Tv_service
);

my $Tariffs = Tariffs->new( $db, \%conf, $admin );
#my $Iptv = Iptv->new( $db, $admin, \%conf );

#**********************************************************
=head2 iptv_user($attr) - Users info

=cut
#**********************************************************
sub iptv_user {
  my ($attr) = @_;

  $Iptv->{UID} = $FORM{UID};
  $FORM{CID}   = $FORM{CID2} if ($FORM{CID2});
  $Iptv->{db}{db}->{AutoCommit} = 0;
  $Iptv->{db}->{TRANSACTION} = 1;
  my $sunbscribe_count = 0;
  my $message = q{};

  if ( $FORM{REGISTRATION_INFO} ){
    # Info
    load_module( 'Docs', $html );
    $users   = Users->new( $db, $admin, \%conf );
    $Iptv    = $Iptv->user_info( $Iptv->{ID} );
    my $pi   = $users->pi( { UID => $Iptv->{UID} } );
    my $user = $users->info( $Iptv->{UID}, { SHOW_PASSWORD => $permissions{0}{3} } );

    ($Iptv->{Y}, $Iptv->{M}, $Iptv->{D}) = split( /-/, (($pi->{CONTRACT_DATE}) ? $pi->{CONTRACT_DATE} : $DATE), 3 );
    $pi->{CONTRACT_DATE_LIT} = "$Iptv->{D} " . $MONTHES_LIT[ int( $Iptv->{M} ) - 1 ] . " $Iptv->{Y} $lang{YEAR}";
    $Iptv->{MONTH_LIT} = $MONTHES_LIT[ int( $Iptv->{M} ) - 1 ];

    if ( $Iptv->{Y} =~ /(\d{2})$/ ){
      $Iptv->{YY} = $1;
    }

    if ( !$FORM{pdf} ){
      if ( in_array( 'Mail', \@MODULES ) ){
        load_module( 'Mail', $html );
        my $Mail = Mail->new( $db, $admin, \%conf );
        my $list = $Mail->mbox_list( { UID => $Iptv->{UID} } );
        foreach my $line ( @{$list} ){
          $Mail->{EMAIL_ADDR} = $line->[0] . '@' . $line->[1];
          $user->{EMAIL_INFO} .= $html->tpl_show( _include( 'mail_user_info', 'Mail' ), $Mail, { OUTPUT2RETURN => 1 } );
        }
      }
    }
    print $html->header();
    $Iptv->{PASSWORD} = $user->{PASSWORD} if (!$Iptv->{PASSWORD});
    return $html->tpl_show(
      _include( 'iptv_user_memo', 'Iptv', { pdf => $FORM{pdf} } ),
      {
        %{$user},
        %{$pi},
        DATE => $DATE,
        TIME => $TIME,
        %{$Iptv},
      }
    );
    return 0;
  }
  elsif ( $FORM{send_message} ){
    if ( !$FORM{send} ){
      $user->{IPTV_MODEMS} = $html->tpl_show( _include( 'iptv_send_message', 'Iptv' ), { %{$attr}, %{$user} } );
      return 0;
    }
    #$FORM{chg}=$FORM{ID};
  }
  elsif ( $FORM{new} ) {

  }
  elsif ( $FORM{new_device}) {
    iptv_new_devices();
    return 1;
  }
  elsif ( $FORM{import} ){
    if ( $FORM{add} ){
      my $import_accounts = import_former( \%FORM );
      my $total = $#{ $import_accounts } + 1;

      $html->message( 'info', $lang{INFO},
        "$lang{ADDED}\n $lang{FILE}: $FORM{UPLOAD_FILE}{filename}\n Size: $FORM{UPLOAD_FILE}{Size}\n Count: $total" );

      return 1
    }

    $html->tpl_show( templates( 'form_import' ), {
        IMPORT_FIELDS => 'LOGIN,TP_ID,STATUS,CID',
        CALLBACK_FUNC => 'iptv_user'
      } );

    return 1;
  }
  elsif ( $FORM{add} ){
    if(! iptv_user_add({ %FORM, %{ ($attr) ? $attr : {} } })) {
      if($FORM{SERVICE_ID}) {
        return 0;
      }
      return 1;
    }
  }
  elsif ( $FORM{change} ){
    $Iptv->user_change( \%FORM );

    if($Iptv->{OLD_STATUS} && ! $Iptv->{STATUS}) {
      iptv_user_activate( $Iptv, {
          USER       => $users,
          REACTIVATE => (! $Iptv->{STATUS} ) ? 1 : 0,
        });
    }

    if ( !$Iptv->{errno} ){
      $Iptv->{ACCOUNT_ACTIVATE} = $attr->{USER_INFO}->{ACTIVATE};
      #if ( !$FORM{STATUS} && ($FORM{GET_ABON} || !$FORM{TP_ID}) ){
      #  service_get_month_fee( $Iptv, { SERVICE_NAME => $lang{TV} } );
      #}

      if ( $FORM{change_now} ){
        $Iptv->user_channels( { ID => $FORM{ID} } );
      }
      $message = "$lang{CHANGED}: $FORM{ID}";
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Iptv->user_info($FORM{del});
    if(! $Iptv->{errno}) {
      $Iptv->user_del( { ID => $FORM{del} } );
      if (!$Iptv->{errno}) {
        $Iptv->{ID} = $FORM{del};
        $html->message( 'info', $lang{INFO}, "$lang{DELETED} [ $Iptv->{ID} ]" );
        delete $Iptv->{ID};
      }
    }
  }
  else{
    my $list = $Iptv->user_list( { UID => $FORM{UID}, COLS_NAME => 1 } );
    $sunbscribe_count = $Iptv->{TOTAL};
    if ( $Iptv->{TOTAL} == 1 ){
      $FORM{chg} = $list->[0]->{id};
    }
    elsif ( $Iptv->{TOTAL} == 0 ){
      $FORM{add_form} = 1;
    }
  }

  if ( $FORM{chg} ){
    $Iptv->user_info( $FORM{chg} );
  }

  $Iptv->{SERVICE_ID} //= $FORM{SERVICE_ID};
  $Tv_service = undef;
  if ($Iptv->{SERVICE_ID}) {
    $Tv_service = tv_load_service( $Iptv->{SERVICE_MODULE}, { SERVICE_ID => $Iptv->{SERVICE_ID} } );
  }

  my DBI $db_ = $Iptv->{db}{db};
  if ( !_error_show( $Iptv ) && $Tv_service ){
    my $action_result = iptv_account_action( {
      %FORM,
      ID           => $Iptv->{ID},
      SUBSCRIBE_ID => $FORM{SUBSCRIBE_ID} || $Iptv->{SUBSCRIBE_ID},
      SCREEN_ID    => undef
    } );

    if ( $action_result ){
      _error_show( $Iptv, {
          ID          => 835,
          #MESSAGE     => $Iptv->{errstr},
          MODULE_NAME => $Tv_service->{SERVICE_NAME}
        });

      $db_->rollback();
      $Iptv->{ID} = undef;
    }
    else {
      $html->message('info', $lang{INFO}, $message) if($message);
      if ($FORM{ARTICLE_ID} && in_array( 'Storage', \@MODULES )) {
        load_module( 'Storage', $html );
        storage_hardware({
          ADD_ONLY => 1,
          SERIAL   => $FORM{SERIAL_NUMBER},
          MAC      => $FORM{CID} || $FORM{MAC},
          add      => 1
        });
      }
    }

    delete( $Iptv->{db}->{TRANSACTION} );
    $db_->commit();
    $db_->{AutoCommit} = 1;
  }
  else {
    delete( $Iptv->{db}->{TRANSACTION} );
    $db_->commit();
    $db_->{AutoCommit} = 1;
  }

  if ( $attr->{REGISTRATION} && $FORM{add}){
    return 1;
  }

  my $user;
  #if ( $conf{IPTV_SUBSCRIBE_CMD} ){
  #  $Iptv->{SUBSCRIBE_FORM} = iptv_sel_subscribes( $Iptv );
  #}

  $Iptv->{SUBSCRIBE_FORM} = tv_services_sel({ %$Iptv, FORM_ROW => 1, UNKNOWN => 1 });

  if ( ! $Iptv->{ID} ){
    if ( $attr->{ACTION} ){
      $user->{ACTION} = $attr->{ACTION};
      $user->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else{
      $user->{ACTION} = 'add';
      $user->{LNG_ACTION} = $lang{ACTIVATE};
    }

    $Iptv->{TP_ADD} = $html->form_select(
      'TP_ID',
      {
        SELECTED  => $FORM{TP_ID} || $Iptv->{TP_ID} || '',
        SEL_LIST  => $Tariffs->list( {
          MODULE       => 'Iptv',
          NEW_MODEL_TP => 1,
          COLS_NAME    => 1,
          DOMAIN_ID    => $admin->{DOMAIN_ID},
          SERVICE_ID   => $Iptv->{SERVICE_ID}
        } ),
        SEL_KEY   => 'tp_id',
        SEL_VALUE => 'id,name',
      }
    );

    $Iptv->{TP_DISPLAY_NONE} = "style='display:none'";
  }
  elsif($Iptv->{UID}){
    $Iptv->{REGISTRATION_INFO} = $html->button( $lang{MEMO},
      "qindex=$index&UID=$Iptv->{UID}&ID=$Iptv->{ID}&REGISTRATION_INFO=1",
      { BUTTON => 1, ex_params => 'target=_new' } );

    if ( $conf{DOCS_PDF_PRINT} ){
      $Iptv->{REGISTRATION_INFO_PDF} = $html->button( "$lang{MEMO} (PDF)",
        "qindex=$index&UID=$Iptv->{UID}&ID=$Iptv->{ID}&REGISTRATION_INFO=1&pdf=1",
        { ex_params => 'target=_new', BUTTON => 1 } );
    }

    iptv_user_channels_list( { ID => $FORM{ID}, TP_ID => $Iptv->{TP_ID} } );

    $user->{TP_IDS} = $Iptv->{TP_ID};
    if ( $attr->{ACTION} ){
      $user->{ACTION} = $attr->{ACTION};
      $user->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else{
      $user->{ACTION} = 'change';
      $user->{LNG_ACTION} = $lang{CHANGE};
    }

    $FORM{chg} = $Iptv->{ID} if (!$FORM{chg});
    $user->{CHANGE_TP_BUTTON} = $html->button( $lang{CHANGE},
      'UID=' . $Iptv->{UID} . '&index=' . get_function_index( 'iptv_chg_tp' ) . '&ID=' . $Iptv->{ID}
        .(($Iptv->{SERVICE_ID}) ? "&SERVICE_ID=$Iptv->{SERVICE_ID}": q{}),
      { class => 'change' } );

    if($Tv_service && $Tv_service->{SEND_MESSAGE}) {
      $user->{SEND_MESSAGE} = $html->button( "$lang{SEND} $lang{MESSAGE}",
        "index=$index&ID=$Iptv->{ID}&UID=".$Iptv->{UID}."&send_message=1"
          .(($Iptv->{SERVICE_ID}) ? "&SERVICE_ID=$Iptv->{SERVICE_ID}": q{}),
        { BUTTON => 1 } );
    }
  }

  $Iptv->{STATUS_SEL} = sel_status( { STATUS => $Iptv->{STATUS} } );

  if ( $FORM{chg} || $FORM{USER_CHANNELS} || $FORM{add_form} || $attr->{REGISTRATION} ){
    iptv_users_screens( $Iptv );
    if ( !$FORM{screen} ){
      if ($Tv_service->{SERVICE_USER_FORM}) {
        my $fn = $Tv_service->{SERVICE_USER_FORM};
        &{ \&$fn }( { %{$attr}, %{$user}, %{$Iptv}, SHOW_USER_FORM => 1 } );
      }
      elsif ( $Iptv->{SUBSCRIBE_FORM_FULL} ){
        print  $Iptv->{SUBSCRIBE_FORM_FULL};
      }
      else{
        $html->tpl_show( _include( 'iptv_user', 'Iptv' ), {
            %{ ($attr) ? $attr : {} },
            %{$Iptv},
            %{($user) ? $user : {}} },
          {ID => 'iptv_user'});
      }

      if ( $Iptv->{ID} ){
        iptv_user_channels( { SERVICE_INFO => $Iptv } );
      }
    }

    if($Iptv->{UID}) {
      print $html->button("Get STB",
        "get_index=iptv_user&new_device=1&header=2&UID=$Iptv->{UID}",
        {
          class         => 'btn-xs',
          LOAD_TO_MODAL => 1,
          BUTTON        => 1,
        });
    }

    if ( $attr->{ACCOUNT_INFO} ){
      return 1;
    }
    delete $FORM{chg};
  }

  iptv_users_list( { USER_ACCOUNT => $sunbscribe_count || 1 } );

  return 1;
}


#**********************************************************
=head2 iptv_new_devices($attr) - New devices

=cut
#**********************************************************
sub iptv_new_devices {

  print "New devices";

  return 1;
}

#**********************************************************
=head2 iptv_user_add($attr) - Users add

=cut
#**********************************************************
sub iptv_user_add {
  my($attr) = @_;

  if ( $attr->{REGISTRATION} ) {
    if(! $attr->{TP_ID}) {
      return 0;
    }
    elsif($attr->{skip_step}) {
      return 1;
    }
  }

  if(! $attr->{SERVICE_ID}) {
    my $tp_list = $Tariffs->list({
      INNER_TP_ID=> $attr->{TP_ID},
      SERVICE_ID => '_SHOW',
      COLS_NAME  => 1
    });

    if($Tariffs->{TOTAL}) {
      $FORM{SERVICE_ID}=$tp_list->[0]->{service_id};
    }
  }

  $Iptv->user_add( $attr );
  if ( !$Iptv->{errno} ){
    $Iptv->{ACCOUNT_ACTIVATE} = $attr->{USER_INFO}->{ACTIVATE};
    if (!$FORM{STATUS}) {
      service_get_month_fee($Iptv, { SERVICE_NAME => $lang{TV} });
    }
    $Iptv->{ID} = $Iptv->{INSERT_ID};
    #$message = "$lang{ADDED} ID: $Iptv->{ID}";
    #$FORM{chg} = $Iptv->{ID};
    return $Iptv->{ID};
  }

  return 1;
}

1;