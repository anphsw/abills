package Unifi;

=head NAME

  UNIFI API v4

=cut

use strict;
use warnings FATAL => 'all';

BEGIN{
  #use lib ; # Assuming we are in /usr/abills/Abills/modules/Unifi/
  unshift ( @INC, "../../../lib/" );
}
use Abills::Base qw( _bp );
use Abills::Defs;
do "Abills/Misc.pm";


my $debug = 0;
our $VERSION = 0.14;

#Pathes inside API
my %OBJPATH = (
  WLAN  => 'list/wlanconf',
  AP    => 'stat/device',
  USERS => 'stat/sta',
  STATS => 'stat/alluser'
);

load_pmodule('JSON');
my $unifi_version;
my $unifi_sitename;

#***************************************************************
#
#***************************************************************
sub new {
  my $class = shift;
  my ($CONF) = @_;

  my $self = { };
  bless( $self, $class );

  $self->{unifi_url} = $CONF->{UNIFI_URL};
  $self->{login} = $CONF->{UNIFI_USER};
  $self->{password} = $CONF->{UNIFI_PASS};
  $unifi_version = $CONF->{UNIFI_VERSION} || 4;
  $unifi_sitename = $CONF->{UNIFI_SITENAME} || 'default';
  $self->{FILE_CURL} = $CONF->{FILE_CURL};
  $self->{api_path} = "$self->{unifi_url}/api/s/$unifi_sitename";
  $debug = $CONF->{unifi_debug} || 0;
  if ($debug && $debug > 2) {
    $self->{debug} = $debug;
  }
  return $self;
}

#**********************************************************
=head2 get_api_list($api_path, [ params ]) - request list from Unifi

$api_path - as defined in $OBJPATH

=cut
#**********************************************************
sub get_api_list {
  my $self=shift;
  my ($api_path, $params) = @_;

  $self->login();

  my $path = $self->{unifi_url} . "/api/s/$unifi_sitename/" . $api_path;
  $self->mk_request( $path, $params );

  $self->logout();

  return $self->{list};
}

#***************************************************************
=head2 users_list() - Get connected users

=cut
#***************************************************************
sub users_list{
  my $self = shift;
  return $self->get_api_list($OBJPATH{USERS});
}

#**********************************************************
=head2 users_stats() - Get statistics for all users

  Arguments:
    $filters - hash_ref of unifi-specific parameters
      within - filter by time ( default: last 24 hours)

  Returns:
    list

=cut
#**********************************************************
sub users_stats {
  my $self = shift;
  my ($filters) = @_;

  my %default_filters = (
    conn   => 'all',      # type of client connection
    type   => 'guest',    # type of client
    within => 24          # hours
  );

  return $self->get_api_list($OBJPATH{STATS}, { %default_filters, %{ (ref $filters eq 'HASH') ? $filters : {} } });
}

#***************************************************************
=head2 devices_list() - Get device list

=cut
#***************************************************************
sub devices_list{
  my $self = shift;
  return $self->get_api_list($OBJPATH{AP});
}

#********************************************************************
=head2 login($attr) - Device auth

=cut
#********************************************************************
sub login{
  my $self = shift;

  my $login_path = "$self->{unifi_url}/api/login";

  my %request_params = (
    username => $self->{login},
    password => $self->{password},
    login    => 'login'
  );

  return $self->mk_request( $login_path, \%request_params, { LOGIN => 1 } );
}

#***************************************************************
=head2 logout() - Log out from NAS

=cut
#***************************************************************
sub logout{
  my $self = shift;
  return $self->mk_request( "$self->{unifi_url}/logout", undef, { CLEAR_COOKIE => 1 } );
}

#***************************************************************
=head2 mk_request() - Make request to NAS

  Arguments:
    $url             - Request url
    $request_params  - Request params (Hash_ref)
    $attr            - extra attr
      DEBUG
      METHOD         - string (Default: post)

  Result:
    TRUE or FALSE
      $self->{errno}
      $self->{errstr}

=cut
#***************************************************************
sub mk_request{
  my $self = shift;
  my ($url, $request_params, $attr) = @_;

  # authenticate against unifi controller
  my $json_result = web_request( $url, {
      REQUEST_PARAMS_JSON => $request_params,
      DEBUG               => $attr->{DEBUG} || $self->{debug},
      CURL                => 1,
      FILE_CURL           => $self->{FILE_CURL},
      COOKIE              => 1,
      HEADERS             => [ "Content-Type: application/json" ],
      JSON_RETURN         => 1,
      CLEAR_COOKIE        => $attr->{CLEAR_COOKIE},
      GET                 => ($attr->{METHOD} && $attr->{METHOD} eq 'get') ? 1 : undef,
      POST                => ($attr->{METHOD} && $attr->{METHOD} eq 'get') ? undef : 1
    } );

  if ( $attr->{DEBUG} ){
    _bp( "JSON REQUEST DATA", $request_params );
    _bp( "JSON RESULT", $json_result );
  }

  if ( $json_result && ref $json_result eq 'HASH' ){
    if ( $json_result->{meta} && $json_result->{meta}->{rc} && $json_result->{meta}->{rc} eq 'ok' ){
      if ( $attr->{LOGIN} ){
        return 1;
      }
      else{
        $self->{list} = $json_result->{data};
      }

      return 1;
    }

    $self->{errno} = $json_result->{meta}->{rc} || 0;
    $self->{errstr} = $json_result->{meta}->{msg} || q{};
  }

  return 0;
}

#********************************************************************
=head2 authorize($attr)

=cut
#********************************************************************
sub authorize{
  my $self = shift;
  my ($attr) = @_;

  $self->login();

  my %login_data_json = (
    cmd       => 'authorize-guest',
    'mac'     => $attr->{MAC},
    'minutes' => $attr->{TIME},
    'down'    => $attr->{DOWN},
    'up'      => $attr->{UP}
  );

  my $response = $self->mk_request( "$self->{api_path}/cmd/stamgr", \%login_data_json );

  $self->logout();

  if ( $debug ){
    _bp( "Authorize: Data: ", \%login_data_json );
    _bp( "Authorize: Response: ", $response );
  }

  return $response;
}

#********************************************************************
=head2 deauthorize($attr) - Hangup user

  Arguments:
    $attr
      MAC

  Returns:

=cut
#********************************************************************
sub deauthorize{
  my $self = shift;
  my ($attr) = @_;

  $self->login();

  my %request_params = (
    'cmd' => 'unauthorize-guest',
    'mac' => $attr->{MAC}
  );

  my $response = $self->mk_request( "$self->{api_path}/cmd/stamgr", \%request_params );

  $self->logout();

  if ( $debug ){
    _bp( "Deauthorize: Data: ", \%request_params );
    _bp( "Deauthorize: Response: ", $response );
  }

  return $self;
}

#********************************************************************
=head2 disconnect($attr) -

  Arguments:
    $attr
       MAC

=cut
#********************************************************************
sub disconnect{
  my $self = shift;
  my ($attr) = @_;
  my $usermac = $attr->{MAC} or return 0;

  $self->login();

  my %login_data =
    (
      'cmd' => 'kick-sta',
      'mac' => $usermac
    );

  my $response = $self->mk_request( "$self->{api_path}/cmd/stamgr", \%login_data );

  $self->logout();

  if ( $debug ){
    _bp( "Login data", \%login_data );
    _bp( "Disconnect response", $response );
  }

  return $response;
}

sub restart_ap{
  my $self = shift;
  my ($attr) = @_;

  my $ap_mac = $attr->{MAC} or return 0;

  $self->login();

  my %login_data = (
    'cmd' => 'restart',
    'mac' => $ap_mac
  )
  ;
  my $response = $self->mk_request( "$self->{api_path}/cmd/devmgr", \%login_data );

  $self->logout();

  if ( $debug ){
    _bp( "Login data", \%login_data );
    _bp( "Disconnect response", $response );
  }

  return $response;
}

#********************************************************************
#
# getJSON()
#********************************************************************
#sub getJSON{
#  my $self = shift;
#  my ($list_name) = @_;
#
#  my $path = $OBJPATH{$list_name} || '';
#
#  $self->login();
#
#  my $response = $self->mk_request( "$self->{api_path}/$path" );
#
#  $self->logout();
#
#  if ( $response == 1 && $self->{list} && ref $self->{list} eq 'HASH' ){
#    return $self->convert_result( $response );
#  }
#
#  return { };
#}
#

#********************************************************************
=head2 convert_result($data_hash)

=cut
#********************************************************************
sub convert_result{
  my $self = shift;
  my ($data_hash) = @_;
  my ($lldData);

  my $lldItem = 0;

  foreach my $hashRef ( @{ $data_hash } ){
    $lldData->{'data'}->[$lldItem]->{'{ALIAS}'} = $hashRef->{'model'};
    $lldData->{'data'}->[$lldItem]->{'{NAME}'} = $hashRef->{'_name'};
    $lldData->{'data'}->[$lldItem]->{'{IP}'} = $hashRef->{'ip'};
    $lldData->{'data'}->[$lldItem]->{'{ID}'} = $hashRef->{'_id'};
    $lldData->{'data'}->[$lldItem]->{'{MAC}'} = $hashRef->{'mac'};
    $lldData->{'data'}->[$lldItem]->{'{OUI}'} = $hashRef->{'oui'};
    $lldData->{'data'}->[$lldItem]->{'{SIGNAL}'} = $hashRef->{'signal'};
    $lldData->{'data'}->[$lldItem]->{'{AUTHORIZED}'} = $hashRef->{'authorized'};
    $lldData->{'data'}->[$lldItem]->{'{RECEIVED}'} = $hashRef->{'rx_bytes'};
    $lldData->{'data'}->[$lldItem]->{'{TRANSMIT}'} = $hashRef->{'tx_bytes'};
    $lldData->{'data'}->[$lldItem]->{'{SPEEDDOWN}'} = $hashRef->{'rx_rate'};
    $lldData->{'data'}->[$lldItem]->{'{SPEEDUP}'} = $hashRef->{'tx_rate'};
    $lldData->{'data'}->[$lldItem]->{'{ADOPTED}'} = $hashRef->{'adopted'};
    $lldData->{'data'}->[$lldItem]->{'{HOSTNAME}'} = $hashRef->{'hostname'};
    $lldData->{'data'}->[$lldItem]->{'{UPTIME}'} = $hashRef->{'_uptime'};

    $lldItem++;
  }

  return $lldData;

  if ( $lldData ){
    return to_json( $lldData, { utf8 => 1, pretty => 1, allow_nonref => 1 } );
  }
  else{
    return 0;
  }
}


1;
