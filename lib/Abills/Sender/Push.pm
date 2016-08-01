package Abills::Sender::Push;

use strict;
use warnings;

our (
  $db,
  $admin,
  $CONF,
    %conf,
    %lang,
  $VERSION,
  @ISA,
  @EXPORT,
  @EXPORT_OK,
  %EXPORT_TAGS
);

$VERSION = 1.00;
@ISA = ('Exporter');

@EXPORT = qw( send_message );

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

BEGIN {
  unshift @INC, "../../";
};

my $gcm_server_url = 'https://gcm-http.googleapis.com/gcm/send';
my $auth_key = '';

use Users;
my Users $users;

use Abills::Base;
do "Abills/Misc.pm";
use Abills::Defs;

my $GCM_TYPE_ID = 10;

#**********************************************************
=head2 new($db, $admin, $conf) - constructor for GCM_PUSH

  Attributes:
    $db, $admin, $conf - default attributes for instance

  Returns:
    object - new GCM_PUSH instance

=cut
#**********************************************************
sub new {
  my $class = shift;

  ($db, $admin, $CONF) = @_;

  my $self = {
      db    => $db,
      admin => $admin,
      conf  => $CONF,
  };

  $users = Users->new(@_);

  $auth_key = $CONF->{GOOGLE_API_KEY} || 'UNDEFINED $conf{GOOGLE_API_KEY}';

  bless( $self, $class );
  return $self;
}

#**********************************************************
=head2 send_message($attr)

  Arguments:
    $attr - hash_ref
      UID     - user ID
      MESSAGE - string. CANNOT CONTAIN DOUBLE QUOTES \"

  Returns:
    1 if success, 0 otherwise

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  my ($uid, $message) = ($attr->{UID}, $attr->{MESSAGE});
  return 0 unless ($uid && $message);

  my $loaded_json_result = load_pmodule( "JSON", { RETURN => 1 } );
  if ( $loaded_json_result ) {
    print $loaded_json_result;
    return 0;
  }
  my $json = JSON->new->utf8( 0 );

  my $user_contacts = $users->contacts_info( {UID => $uid, TYPE_ID => $GCM_TYPE_ID} );

  my $registration_id = $user_contacts->{VALUE};
  # Return if client is not registered
  return 0 unless (defined $registration_id);

  my $data = $json->encode( {
          "data" => {
              "uid"     => $uid,
              "message" => $message
          },
          "to"   => $registration_id
      } );

  $data =~ s/"/\\\"/g;

  my $result = web_request( $gcm_server_url, {
          POST        => $data,
          RETURN_JSON => 1,
          HEADERS     => [ "Content-Type: application/json", "Authorization:key=$auth_key" ],
          DEBUG       => $attr->{DEBUG}
      } );

  if ( $result =~ /^{"/ ) {
    my $response = $json->decode( $result );
    return $response->{success};
  }
  elsif ( $result =~ /Unauthorized/ ) {
    print "\n\n AUTHORIZATION ERROR: Invalid \$conf{GOOGLE_API_KEY} key \n";
    return 0;
  }

  return 1;
}



1;