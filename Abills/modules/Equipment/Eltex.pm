#Eltex snmp monitoring and managment

#**********************************************************
# http://eltex.nsk.ru/support/knowledge/upravlenie-po-snmp.php
#**********************************************************
sub _eltex_onu_status () {

  my %status = (
    0  => 'free',
    1  => 'allocated',
    2  => 'authInProgress',
    3  => 'cfgInProgress',
    4  => 'authFailed',
    5  => 'cfgFailed',
    6  => 'reportTimeout',
    7  => 'ok',
    8  => 'authOk',
    9  => 'resetInProgress',
    10 => 'resetOk',
    11 => 'discovered',
    12 => 'blocked',
    13 => 'checkNewFw',
    14 => 'unidentified',
    15 => 'unconfigured',
  );

  return \%status;
}


#**********************************************************
#
#**********************************************************
sub _eltex_onu_info  {
  my ($attr) = @_;

  my $cols      = $attr->{COLS};
  my $info_oids = $attr->{INFO_OIDS};

  my %total_info = ();
  my $snmp       = _eltex();
  my $onu_status = _eltex_onu_status();
  my @all_rows   = ();

  my $used_ports = equipments_get_used_ports({ NAS_ID => $FORM{NAS_ID} });

  foreach my $oid_name (@$cols) {
    if (! $snmp->{$info_oids->{$oid_name}}) {
      next;
    }

    my $oid = $snmp->{$info_oids->{$oid_name}};
    my $values = snmp_get({ %$attr,
                            WALK    => 1,
                            OID     => $oid,
                            TIMEOUT => 25
                          });

    foreach my $line ( @$values ) {
      my ($key, $oid_value) = split(/:/, $line);

      if($oid_name eq 'MAC_ONU') {
        $oid_value = join(':', unpack("H2H2H2H2H2H2", $oid_value));
      }
      elsif($oid_name eq 'ONUSTATUS') {
        $oid_value = $onu_status->{$oid_value}. "($oid_value)";
      }
      elsif($oid_name eq 'CUR_TX') {
        $oid_value = sprintf("%.2f", $oid_value / 10);
      }

      #print "$oid_name/ $key, $oid_value<br>";
      $total_info{$oid_name}{$key}=$oid_value;
    }
  }

  my $num = 0;
  foreach my $key (keys %{ $total_info{ONUSTATUS} } ) {
    my @row = ();
    for(my $i=0; $i<=$#{ $cols }; $i++) {
      my $value = '';
      if($cols->[$i] eq 'USERS') {
        foreach my $uinfo (@{ $used_ports->{$total_info{NUM}{$key}} }) {
          next if ($uid =~ /^sw:/);
          my ($uid, $login, $nas_name) = split(/:/, $uinfo);
          $value .= user_ext_menu($uid, $login, { SHOW_LOGIN => 1 });
        }
      }
      else {
        $value = $total_info{$cols->[$i]}{$key};
      }

      push @row, $value;
    }

    push @all_rows, [
            @row,
            $html->button('', "index=$index&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&onuReset=$key", { class => 'glyphicon glyphicon-retweet', TITLE => $lang{REBOOT} }),
            $html->button($lang{ADD}, 'index=15', { class => 'add' }),
            $html->button($lang{INFO}, "index=$index&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&ONU=$key", { class => 'info' })
         ];
    $num++;
  }

  return \@all_rows;
}


#**********************************************************
# http://eltex.nsk.ru/support/knowledge/upravlenie-po-snmp.php
#**********************************************************
sub _eltex () {

  my %snmp =  (
                 'onu_name'    => '.1.3.6.1.4.1.35265.1.21.16.1.1.8.6',
                 'mac_onu'     => '.1.3.6.1.4.1.35265.1.21.25.1.1', # это маки онушек
                 'onu_user_mac'=> '.1.3.6.1.4.1.35265.1.21.25.1.6', # это маки абонентов на ону
                 #'mac_onu'     => '.1.3.6.1.4.1.35265.1.21.16.1.1.1.6',
                 'onustatus'   => '.1.3.6.1.4.1.35265.1.21.6.1.1.6.6',
                 'num'         => '.1.3.6.1.4.1.35265.1.21.6.1.1.7.6',
                 'cur_tx'      => '1.3.6.1.4.1.35265.1.21.6.1.1.15.6', # lazerpower_dbm
                 #cur_tx_db     => '.1.3.6.1.4.1.35265.1.21.6.1.1.15.6', # lazerpower
                 'lazerpower'       => '1.3.6.1.4.1.35265.1.21.6.1.1.8.6',
                 #'lazerpower_dbm'   => '1.3.6.1.4.1.35265.1.21.6.1.1.15.6',
                 'video_power'      => '1.3.6.1.4.1.35265.1.21.6.1.1.16.6',
                 'video_power_dbm'  => '1.3.6.1.4.1.35265.1.21.6.1.1.17.6',
                 'shaper'           => '1.3.6.1.4.1.35265.1.21.16.1.1.5.6',
                 'onuReset'         => '1.3.6.1.4.1.35265.1.21.16.1.1.21.6',
#             onu_info => {
#               'onu_name'    => '.1.3.6.1.4.1.35265.1.21.16.1.1.8.6',
#               'mac_onu'     => '.1.3.6.1.4.1.35265.1.21.16.1.1.1.6',
#               'onustatus'   => '.1.3.6.1.4.1.35265.1.21.6.1.1.6.6',
#               'num'         => '.1.3.6.1.4.1.35265.1.21.6.1.1.7.6',
#               'cur_tx'      => '.1.3.6.1.4.1.35265.1.21.6.1.1.8.6', # lazerpower
#               'cur_tx_db'   => '.1.3.6.1.4.1.35265.1.21.6.1.1.15.6', # lazerpower
#               'lazerpower'       => '1.3.6.1.4.1.35265.1.21.6.1.1.8.6',
#               'lazerpower_dbm'   => '1.3.6.1.4.1.35265.1.21.6.1.1.15.6',
#               'video_power'      => '1.3.6.1.4.1.35265.1.21.6.1.1.16.6',
#               'video_powerв_dbm' => '1.3.6.1.4.1.35265.1.21.6.1.1.17.6',
#             }
  );

  return \%snmp;
}

1