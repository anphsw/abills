=head1 NAME

 billd plugin

 DESCRIBE: Odoo import accounts


 Arguments:
   FIELDS_INFO       - Show field info
   TYPE              - Synsc system type
   SYNCHRON_ODOO_FIELDS  - Odoo sync field
   DOMAIN_ID         - DOmain id
   SKIP_SERVICE      - Skip sync service
   SKIP_WRONG_MAIL


 Config:
   $conf{SYNCHRON_ODOO_FIELDS}='odoo_field:abills_field_id;';





1.	Интеграция с системой Odoo (OpenERP):
  - синхронизация данных при создании клиента (заполнение карточки клиента, изменение данных)
  - создание и/или синхронизация данных по инвойсам
  - синхронизация данных по клиентским платежам
  - формирование SOA по клиенту (отчет о всех инвойсах и платежах, связанных с данным клиентом)

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Abills::Base qw(show_hash);
use Abills::Filters qw(_utf8_encode);
use Synchron::Odoo;
use Frontier::Client;
use Tariffs;
use Users;
use Internet;

our (
  $argv,
  $DATE,
  $TIME,
  $debug,
  $Nas,
  $db,
  $Sessions,
  %conf,
  $Admin,
);

my $Users        = Users->new($db, $Admin, \%conf);
my $import_limit = $argv->{IMPORT_LIMIT} || 1000000000;
my $admin        = $Admin;

if($argv->{FIELDS_INFO}) {
  fields_info();
}
else {
  sync_system()
}

#**********************************************************
=head2 fields_info();

=cut
#**********************************************************
sub fields_info {

  my $type = $argv->{TYPE} || q{odoo};
  my $fn = $type .'_field_info';
  &{ \&$fn }();

  return 1;
}


#**********************************************************
=head2 odoo_import();

=cut
#**********************************************************
sub sync_system {

  my $type = $argv->{TYPE} || q{odoo};
  my $fn = $type .'_import';
  &{ \&$fn }();

  return 1;
}


#**********************************************************
=head2 odoo_field_info();

=cut
#**********************************************************
sub odoo_field_info {

  odoo_import({ FIELDS_INFO => 1 });

  return 1;
}

#**********************************************************
=head2 odoo_import();

=cut
#**********************************************************
sub odoo_import {
  my($attr) = @_;

  my $url      = $conf{SYNCHRON_ODOO_URL} || 'https://demo.odoo.com:8069';
  my $dbname   = $conf{SYNCHRON_ODOO_DBNAME} || 'demo';
  my $username = $conf{SYNCHRON_ODOO_USERNAME} || 'admin';
  my $password = $conf{SYNCHRON_ODOO_PASSWORD} || 'admin';

  $url =~ s/\/$//;

  if($debug) {
    print "Odoo import\n";
    if($debug > 2) {
      print "DOMAIN_ID: $admin->{DOMAIN_ID} URL: $url DB: $dbname USER: $username PASSWORD: $password\n";
    }
  }

  my $Odoo = Synchron::Odoo->new({
    LOGIN    => $username,
    PASSWORD => $password,
    URL      => $url,
    DBNAME   => $dbname,
    DEBUG    => ($debug > 4) ? 1 : 0,
    CONF     => \%conf
  });

  if($Odoo->{errno}) {
    print "ERROR: Odoo $Odoo->{errno} $Odoo->{errstr}\n";
  }

  my $sync_fields = q{};

  if($conf{SYNCHRON_ODOO_FIELDS}) {
    $conf{SYNCHRON_ODOO_FIELDS}=~s/\n//g;

    my @sync_fields_info = split(/;/, $conf{SYNCHRON_ODOO_FIELDS});
    my @sync_fields = ();
    foreach my $line (@sync_fields_info) {
      my($fld, undef)=split(/:/, $line);
      push @sync_fields, $fld;
    }
    $sync_fields = join(',', @sync_fields);
  }

  if($attr->{FIELDS_INFO}) {
    my $fields = $Odoo->fields_info();

    foreach my $key  ( sort keys %{ $fields } ) {
      print "$key : $fields->{$key}\n";
    }
  }
  else {
    my $users_list = $Odoo->user_list({
      FIELDS => $sync_fields
    });

    user_import($users_list);

    if(! $argv->{SKIP_SERVICE}) {
      my $service_list = $Odoo->contracts_list();

      #Service sync
      odoo_service_sync($service_list);
    }
  }

  return 1;
}

#**********************************************************
=head2 user_import($users_list); - Sync users

=cut
#**********************************************************
sub user_import {
  my($users_list)=@_;

  my $count        = 0;
  my $update_count = 0;
  my $domain_id    = 0;

  if($argv->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID}=$argv->{DOMAIN_ID};
    $domain_id=$argv->{DOMAIN_ID};
  }

  if($debug > 3) {
    print "Sync fields\n";
    my $result_fields = $users_list->[0];
    print show_hash($result_fields, { DELIMITER => "\n" });
  }

  foreach my $user_info ( @$users_list ) {
    my $sync_field = 'LOGIN';
    print "Sync field: $sync_field Remote filed: ". (($user_info->{$sync_field}) ? $user_info->{$sync_field} : 'Not defined' )."\n" if ($debug > 1);

    $Users->{debug}=1 if($debug > 6);
    my $user_list = $Users->list({
      $sync_field  => $user_info->{$sync_field},
      REGISTRATION => '_SHOW',
      COLS_NAME    => '_SHOW'
    });

    if ($Users->{TOTAL}) {
      if($debug > 1) {
        print "====> $user_info->{LOGIN} exists UID: $user_list->[0]->{uid} REGISTRATION: $user_list->[0]->{registration}\n";
      }

      $argv->{UPDATE}=1;
      if($argv->{UPDATE}) {
        my $uid = $user_list->[0]->{uid};
        $Users->info($uid);
        $Users->pi({ UID => $uid });

        foreach my $key ( sort keys %$Users ) {
          if(defined($user_info->{$key})) {
            $user_info->{$key} //= q{};
            if(! defined($Users->{$key})) {
              next;
            }

            if($Users->{$key} ne $user_info->{$key}) {
              if(! $Users->{$key} && ! $user_info->{$key} ) {
                next;
              }

              Encode::_utf8_off($user_info->{$key});
              Encode::_utf8_off($Users->{$key});
              print "$key: $Users->{$key} -> $user_info->{$key}\n" if($debug > 2);
              $Users->change($uid, {
                %{ $user_info },
                UID => $uid
              });

              $Users->pi_change({
                %{ $user_info },
                UID => $uid
              });
              $update_count++;
            }
          }
        }

        #sync_internet({
        #  EXT_SYSTEM => $user_info,
        #  UID        => $uid
        #});

        if($debug > 10) {
          print "--------------------------------------------\n\n";
          show_hash($user_info);
          exit;
        }
      }

      next;
    }

    if($debug > 0) {
      print "ADD LOGIN $sync_field: $user_info->{$sync_field}\n";
    }

    if(! $user_info->{PASSWORD}) {
      $user_info->{PASSWORD} //= $user_info->{LOGIN}.'1234567890';
    }

    if ($argv->{SKIP_WRONG_MAIL} && $user_info->{EMAIL}) {
      if ($user_info->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
        delete $user_info->{EMAIL};
      }
    }

    my Users $User = $Users->add({
      %{ $user_info },
      CREATE_BILL => 1,
      DOMAIN_ID   => $domain_id
    });

    if(! $User->{errno}) {
      print "Registred UID: $User->{UID}\n";
      $user_info->{UID}=$User->{UID};
      $User->pi_add($user_info);
    }
    else {
      if($Users->{errno} == 11) {
        print "Error: $User->{errno} $User->{errstr} '$user_info->{EMAIL}'\n";
      }
      else {
        print "Error: $User->{errno} $User->{errstr}\n";
      }
    }

    $count++;
    if($count > $import_limit) {
      exit;
    }
  }

  if($debug > 1) {
    print "Count ADD: $count UPDATE: $update_count\n"
  }

  return 1;
}


##**********************************************************
#=head2 sync_internet($user_info);
#
#  Argumnets:
#    $attr
#      EXT_SYSTEM => $user_info,
#      UID        => $uid
#
#  Returns:
#
#  Examples:
#
#=cut
##**********************************************************
#sub sync_internet {
#  my ($attr)=@_;
#
#  my $user_info = $attr->{EXT_SYSTEM};
#  my $uid       = $attr->{UID};
#
#  my $internet_services = $Internet->list({
#    TP_ID     => '_SHOW',
#    CID       => '_SHOW',
#    IP        => '_SHOW',
#    UID       => $uid,
#    SHOW_COLS => 1
#  });
#
#  foreach my $i_info (@$internet_services) {
#    print "UID: $i_info->{UID} ID: $i_info->{ID} TP_ID: $i_info->{TP_ID} IP: $i_info->{IP}\n";
#
#    foreach my $param (keys %$i_info) {
#      print "$param: $i_info->{$param} <- ". (($user_info) ? $user_info->{$param} : q{})  ."\n";
#    }
#  }
#
#  return 1;
#}


#**********************************************************
=head2 _get_tp($user_info);


=cut
#**********************************************************
sub _get_tp {

  my $Tariffs = Tariffs->new($db, \%conf, $Admin);
  my %tps_list = ();

  my $list = $Tariffs->list({
    NAME      => '_SHOW',
    COLS_NAME => 1
  });

  foreach my $line (@$list) {
    $tps_list{$line->{name}}=$line->{tp_id}
  }

  return \%tps_list;
}


#**********************************************************
=head2 odoo_service_sync($service_list);


=cut
#**********************************************************
sub odoo_service_sync {
  my ($service_list)=@_;

  my %login2uid = ();
  my $logins_list = $Users->list({
    LOGIN     => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 100000
  });

  foreach my $line (@$logins_list) {
    $login2uid{$line->{login}}=$line->{uid};
  }

  my $tp_ids = _get_tp();
  my $Internet = Internet->new($db, $Admin, \%conf);

  my $i = 0;
  foreach my $info (@$service_list) {
    $i++;
    print $i."- $info->{id}\n" if($debug > 1);
    my %user_tp = ();
    if($info->{partner_id} &&  ref $info->{partner_id} eq 'ARRAY' && $info->{partner_id}->[0] ) {
      print "LOGIN: " . ($info->{partner_id}->[0] || 'n/d')
        . " IP: $info->{ip_antenna} TP_ID: \n" if ($debug > 1);
    }
    else {
      next;
    }

    my $ip = (ref $info->{ip_antenna}  eq '') ? $info->{ip_antenna} : '0.0.0.0';
    my $cid = (ref $info->{mac_antenna}  eq '') ? $info->{mac_antenna} : '';
    my $login = $info->{partner_id}->[0];

    foreach my $tp_name  (@{ $info->{product_id} }) {
      if($tp_ids->{$tp_name}) {
        my $tp_id = $tp_ids->{$tp_name};
        $user_tp{$tp_id}++;
        print "  $tp_name ($tp_id)\n" if($debug>2);
      }
      else {
        print "  $tp_name ('n/d')\n" if($debug>2);
      }
    }

    my $service_count = scalar(keys %user_tp);

    my $internet_list = $Internet->list({
      LOGIN     => $login,
      TP_ID     => '_SHOW',
      ID        => '_SHOW',
      CID       => '_SHOW',
      GROUP_BY  => 'internet.id',
      COLS_NAME => 1
    });

    if($Internet->{TOTAL}) {
      foreach my $list ( @$internet_list ) {
        if($user_tp{$list->{tp_id}}) {
          print "LOGIN: $login TP: $list->{tp_id} !!!!!!!!!!!!!!!!!!!!! exist service\n" if($debug > 1);
          if ($user_tp{$list->{tp_id}} == 1) {
            delete $user_tp{$list->{tp_id}};
          }
          else {
            $user_tp{$list->{tp_id}}--;
          }
        }
        # Change tp on main system
        elsif($service_count == 1) {
          my @tps = keys %user_tp;
          my $new_tp = $tps[0] || 0;
          if($debug > 1) {
            print "CHANGE: $internet_list->[0]->{uid} -> $new_tp\n";
          }

          if($new_tp) {
            $Internet->add({
              UID   => $internet_list->[0]->{uid},
              TP_ID => $new_tp,
              IP    => $ip,
              CID   => $cid,
              CHECK_EXIST_TP => 1
            });

            if($Internet->{errno}) {
              print "ERROR: $Internet->{errno} $Internet->{errstr}\n";
            }
          }

#          print "$login // ". ($internet_list->[0]->{id} || q{-})
#            .", // ". ($internet_list->[0]->{uid} || q{--})
#            .", // ". ($ip || q{---}) ."\n";

          delete $user_tp{$list->{tp_id}};
        }

        $Internet->change({
          ID    => $internet_list->[0]->{id},
          UID   => $internet_list->[0]->{uid},
          CID   => $cid,
          #TP_ID => $new_tp,
          IP    => $ip
        });

      }
    }

    foreach my $tp_id ( keys %user_tp ) {
      if(! $login2uid{$login}) {
        print "Unknow UID for LOGIN: $login\n ";
        next;
      }
      #print "!!! $login // $user_tp{$tp_id} //\n";
      for (my $num=1; $num<=$user_tp{$tp_id} || 0; $num++) {
        if ($debug > 0) {
          print "ADD: " . ($login2uid{$login} || qq{NO UID LOGIN: $login }) . " -> " . ($tp_id || 'n/d') . "\n";
        }

        $Internet->add({
          UID   => $login2uid{$login},
          TP_ID => $tp_id,
          IP    => $ip,
          CID   => $cid,
          CHECK_EXIST_TP => 1
        });

        if($Internet->{errno}) {
          print "ERROR: [$Internet->{errno}] $Internet->{errstr}\n";
        }

        if ($user_tp{$tp_id} == 1) {
          #delete $user_tp{$tp_id};
        }
        else {
          $user_tp{$tp_id}--;
        }
      }
    }
  }

  return 1;
}



1;