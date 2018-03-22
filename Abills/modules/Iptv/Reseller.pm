package Iptv::Reseller;

=head1 NAME

  Iptv Reseller interface

=head1 VERSION

  VERSION: 1.01
  REVISION: 20180103

=cut

use strict;
use warnings FATAL => 'all';
use Iptv;
use Tariffs;
use parent qw(Exporter);
use Abills::Base qw/mk_unique_value _bp/;

use Abills::Misc qw/_error_show/;
require Abills::Result_former;

our $VERSION = 1.01;
our (%lang);

our @EXPORT = qw(
  iptv_users_list
  iptv_tp
 );

my $MODULE = 'Reseller';
my Abills::HTML $html;
my $Iptv;
my $Tariffs;
my $FORM;
my $users;
my $admin;
my %conf;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  $admin = $attr->{ADMIN};
  $admin->{MODULE} = $MODULE;
  %lang  = %{ $attr->{LANG} };
  $html  = $attr->{HTML};
  $users = $attr->{USERS};
  %conf  = %{ $attr->{CONF} };
  $FORM  = $html->{HTML_FORM};

  my $self = {
    db              => $attr->{DB},
    conf            => $attr->{CONF},
    admin           => $admin,
    users           => $users,
    SERVICE_NAME    => 'Iptv_Reseller',
    VERSION         => $VERSION
  };

  bless($self, $class);

  
  $self->{debug}    = $attr->{DEBUG} || 0;
  $Iptv = Iptv->new($self->{db}, $self->{admin}, $self->{conf});
  $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  return $self;
}

#**********************************************************
=head2 menu() - menu items

=cut
#**********************************************************
sub menu {
  my $self = shift;

  my %menu = (
    "01:0:TV:iptv_users_list:"              => 1,
    "02:0:TV:iptv_user:UID"                 => 0,
    "03:2:TARIF_PLANS:iptv_chg_tp:UID"      => 11,
    "06:0:TV:null:"                         => 5,
    "07:6:TARIF_PLANS:iptv_tp:"             => 5,
    # "08:7:ADD:iptv_tp:"                     => 5,
    # "09:7:INTERVALS:iptv_intervals:TP_ID"   => 5,
    # "11:7:SCREENS:iptv_screens:TP_ID"       => 5,
    # "10:7:GROUPS:form_tp_groups:"           => 5,
    # "10:7:NASS:iptv_nas:TP_ID"              => 5,
    # "20:0:TV:iptv_online:"                  => 6,
    # "30:0:TV:iptv_use:"                     => 4,
  );

  $self->{menu}=\%menu;

  return $self->{menu};
}

#**********************************************************
=head2 iptv_users_list()

=cut
#**********************************************************
sub iptv_users_list {
  my $self = shift;
  #my ($attr) = @_;

  if($FORM->{add}) {
    iptv_user_add();
  }
  elsif($FORM->{add_payment}) {
    $html->tpl_show('', { UID => $FORM->{add_payment}}, { TPL => 'iptv_reseller_payment', MODULE => 'Iptv' });
  }
  elsif($FORM->{make_payment}) {
    main::_make_payment($FORM->{UID}, $FORM->{SUM});
  }
  elsif($FORM->{chg}) {

  }
  elsif( $FORM->{change_user} ) {
   
  }
  elsif( $FORM->{add_user} ) {
    $Iptv->{TP_ADD} = _tp_sel();
    $Iptv->{ACTION}='add';
    $Iptv->{LNG_ACTION}=$lang{ADD};
    $Iptv->{STATUS_SEL} = main::sel_status( { STATUS => $Iptv->{STATUS} } );
    $html->tpl_show('', $Iptv, { TPL => 'iptv_reseller_user', MODULE => 'Iptv' });
  }
  elsif($FORM->{del} && $FORM->{COMMENTS}) {

  }

  my $list = $Iptv->user_list({
    ID             => '_SHOW',
    UID            => '_SHOW',
    LOGIN          => '_SHOW',
    FIO            => '_SHOW',
    TP_NAME        => '_SHOW',
    DEPOSIT        => '_SHOW',
    SERVICE_STATUS => '_SHOW',
    DOMAIN_ID      => $admin->{DOMAIN_ID},
    PG             => $FORM->{pg},
    COLS_NAME      => 1,
  });

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{USERS},
    title_plain => [ $lang{LOGIN}, $lang{FIO}, $lang{DEPOSIT}, $lang{TARIF_PLAN}, $lang{STATE} ],
    qs          => "",
    pages       => $Iptv->{TOTAL},
    ID          => 'USERS',
    MENU        => "$lang{ADD}:index=$FORM->{index}&add_user=1:btn bg-olive margin;",
    HAS_FUNCTION_FIELDS => 1,
  });

  foreach my $line (@$list) {
    my $payment_button = $html->button($lang{PAYMENTS}, "index=$FORM->{index}&add_payment=$line->{uid}", { class => 'payments' });
    $table->addrow(
      $line->{login},
      $line->{fio},
      $line->{deposit},
      $line->{tp_name},
      $line->{service_status} ? $lang{DISABLED} : $lang{ENABLE},
      "$payment_button",
    );
  }

  print $table->show();

  $table = $html->table({
    width      => '100%',
    rows       => [ [ "$lang{TOTAL}:", $html->b( $Iptv->{TOTAL} )  ] ],
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 iptv_users_add()

=cut
#**********************************************************
sub iptv_user_add {

  my ($sum) = @_;

  my $password = mk_unique_value(6, { EXTRA_RULES => '0:0' });
  $users->add({
    CREATE_BILL => 1,
    PASSWD      => $password,
    %$FORM,
  });
  main::_error_show($users);
  
  my $uid = $users->{INSERT_ID};
  
  if ( $users->{errno} ) {
    $html->message('err', "$lang{ERROR}", "");
    return 0;
  }

  $users->pi_add({ %$FORM, UID => $uid });
  main::_error_show($users);

  reseller_make_payment($uid, $sum);
  
  $Iptv->user_add({ %$FORM, UID => $uid });
  main::_error_show($Iptv);

  if (!$Iptv->{errno}) {
    $html->message('info', $lang{INFO}, $lang{ADDED});
  }

  return 1;
}

#**********************************************************
=head2 reseller_make_payment ()

=cut
#**********************************************************
sub reseller_make_payment  {
  my ($uid) = @_;

  #TODO
  #create card and use card

  return 1;
}

#**********************************************************
=head2 iptv_tp() - Tarif plans

=cut
#**********************************************************
sub iptv_tp {
  
  my $form_info;

  if ( $FORM->{ADD_TP} ){
    $Tariffs->add( { %$FORM, MODULE => 'Iptv' } );
    if ( !$Tariffs->{errno} ){
      $html->message( 'info', $lang{ADDED}, "$lang{ADDED} $Tariffs->{TP_ID}" );
    }
  }
  elsif ( $FORM->{CHANGE_TP} ) {
    $Tariffs->change( $FORM->{TP_ID}, { %$FORM, MODULE => 'Iptv' } );
    if ( !$Tariffs->{errno} ){
      $html->message( 'info', $lang{CHANGED}, "$lang{CHANGED} $Tariffs->{TP_ID}" );
    }
  }
  elsif ( $FORM->{ADD_FORM} ) {
    $form_info->{BTN_ACTION} = 'ADD_TP';
    $form_info->{BTN_NAME} = $lang{ADD};
    $html->tpl_show('', { %$form_info }, { TPL => 'iptv_reseller_tp', MODULE => 'Iptv' });
  }
  elsif ( $FORM->{CHG_FORM} ) {
    $form_info->{BTN_ACTION} = 'CHANGE_TP';
    $form_info->{BTN_NAME} = $lang{CHANGE};
    $html->tpl_show('', { %$form_info, %$Tariffs }, { TPL => 'iptv_reseller_tp', MODULE => 'Iptv' });
  }



  


  return 1;
}

#**********************************************************
=head2 _tp_sel()

=cut
#**********************************************************
sub _tp_sel {
  return $html->form_select(
    'TP_ID',
    {
      SELECTED  => $Iptv->{TP_ID},
      SEL_LIST  => $Tariffs->list( {
        MODULE       => 'Iptv',
        NEW_MODEL_TP => 1,
        COLS_NAME    => 1,
      } ),
      SEL_KEY        => 'tp_id',
      SEL_VALUE      => 'id,name',
    }
  );
}

1