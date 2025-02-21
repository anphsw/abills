package Userside::Import;
=head1 NAME

  Userside fetcher

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Fetcher;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($CONF)  = shift;

  my $self = {
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}


#**********************************************************
=head2 fetch($params);

  Arguments:
    $point
    $attr

  Results:
    $result

=cut
#**********************************************************
sub fetch {
  my $self = shift;
  my ($point, $attr) = @_;

  my $us_link      = $self->{conf}{USERSIDE_API_URL}  || $attr->{URL} || 'http://demo.userside.eu';
  my $us_apikey    = $self->{conf}{USERSIDE_API_KEY} || 'keyus';
  my $us_cat       = $self->{conf}{USERSIDE_CAT}    || 'module';
  my $request_timeout = $self->{conf}{USERSIDE_TIMEOUT} || 60;
  my $debug        = $self->{debug} || 0;

  my $request_link = "$us_link/api.php?key=$us_apikey&cat=$us_cat&request=$point";

  my $result = web_request($request_link, {
    JSON_RETURN => 1,
    CURL        => 1,
    JSON_UTF8   => 1,
    DEBUG       => ($debug > 4) ? 1 : 0,
    TIMEOUT     => $request_timeout,
    #FILE_CURL   => $conf{FILE_CURL}
  });

  if (! $result) {
    print "ERROR: No result\n";
  }
  elsif($result && $result->{errno}) {
    print "ERROR: Request error: ". ($result->{errstr} || q{});
    return {};
  }

  return $result;
}

1;