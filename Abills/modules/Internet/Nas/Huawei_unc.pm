package Internet::Nas::Huawei_unc;
#**********************************************************
=head1 Huawei UNC  managment system


  VERSION: 0.16
  DATE: 20260205

=cut
#**********************************************************
use strict;
use warnings FATAL => 'all';
use Abills::Fetcher;
use POSIX q(strftime);
use base 'Exporter';
use Math::BigInt;

# our @EXPORT = qw(
#   online_filter
# );

our @EXPORT_OK = qw(
  online_filter
);
my $ident_field = 'CID';

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $CONF, $attr) = @_;

  my $self = {
    conf         => $CONF,
    unc_host     => $attr->{HOST} || $CONF->{INTERNET_SERVICE_HOST} || 'http://10.10.10.10:8002/',
    unc_login    => $CONF->{INTERNET_SERVICE_LOGIN} || $attr->{LOGIN} || 'abills',
    unc_password => $CONF->{INTERNET_SERVICE_PASSWORD} || $attr->{PASSWORD} || 'password',
    debug        => $attr->{DEBUG} || $CONF->{INTERNET_SERVICE_DEBUG} || 0,
    DEBUG_FILE   => $attr->{DEBUG_FILE} || $CONF->{INTERNET_SERVICE_DEBUG_FILE},
    AID          => ($attr->{ADMIN} && $attr->{ADMIN}->{AID}) ? $attr->{ADMIN}->{AID} : 0
  };

  bless($self, $class);

  my $mod_return = Abills::Base::load_pmodule('XML::Simple', { SHOW_RETURN => 1 });
  if ($mod_return) {
    $self->{error} = 1111111111;
    $self->{error} = "INSTALL XML::Simple";
    print "No xml module";
    exit;
  }


  if($CONF->{INTERNET_HUAWEI_UNC_IDENT}) {
    $ident_field = $CONF->{INTERNET_HUAWEI_UNC_IDENT};
  }

  return $self;
}

#**********************************************************
=head2 test()

=cut
#**********************************************************
sub test {
  my $self = shift;

  print "test OK";
  $self->getSubscriberAllInf({ $ident_field => '401100000001008' });

  return $self;
}

#**********************************************************
=head2 auth()

=cut
#**********************************************************
sub auth {
  my $self = shift;

  my $auth_request = << "REQ";
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:rm="rm:soap">
 <soapenv:Header/>
 <soapenv:Body>
      <rm:LGI>
         <inPara>
            <Login>
               <attribute>
                  <key>OPNAME</key>
                  <value>$self->{unc_login}</value>
               </attribute>
               <attribute>
                  <key>PWD</key>
                  <value>$self->{unc_password}</value>
               </attribute>
            </Login>
         </inPara>
      </rm:LGI>
 </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($auth_request, { SKIP_NOTIFY => 1 });

  return $self;
}


#**********************************************************
=head2 methods()

=cut
#**********************************************************
sub methods {
  my $self = shift;

  my %methods = (
    system  => {
      getGroupMemberList => 'GROUPS',
    },
    user_ll => {
      getSubscriberAllInf      => 'All Subcribes', #
      addSubscriber            => 'addSubscriber',
      delSubscriber            => 'delSubscriber',
      getSubscriber            => 'getSubscriber',
      updateSubscriberQuota    => 'updateSubscriberQuota',

      subscribeService         => 'subscribeService',
      unSubscribeService       => 'unSubscribeService',
      getSubscriberAllService  => 'getSubscriberAllService',
      getSubscriberSpecService => 'getSubscriberSpecService',

      resetSubscriberQuota     => 'resetSubscriberQuota',
      getSubscriberAllQuota    => 'getSubscriberAllQuota',
      getSubscriberSpecQuota   => 'getSubscriberSpecQuota',

      getSubscriberAccount     => 'getSubscriberAccount',
    },
    user    => {
      user_add          => 'Create subscriber and Tariff',
      user_info         => 'Maintenance of subscriber',
      user_change       => 'Change Service (Tariff)',
      user_change_quota => 'Quota modification',
      user_del          => 'Remove Subscriber'
    }
  );

  return \%methods;
}

#**********************************************************
=head2 user_del($request)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub user_del {
  my ($self, $attr) = @_;

  $self->delSubscriber($attr);

  return $self;
}

#**********************************************************
=head2 user_change($request)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub user_change {
  my ($self, $attr) = @_;

  $self->unSubscribeService($attr);
  $self->subscribeService($attr);

  return $self;
}

#**********************************************************
=head2 user_change_quota($request)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub user_change_quota {
  my ($self, $attr) = @_;

  $self->updateSubscriberQuota($attr);

  return $self;
}


#**********************************************************
=head2 user_info($request)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub user_info {
  my ($self, $attr) = @_;

  $self->getSubscriberAllService($attr);
  if (!$self->{error}) {
    $self->getSubscriberSpecService($attr);
  }

  return $self;
}

#**********************************************************
=head2 user_add($request)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub user_add {
  my ($self, $attr) = @_;

  $self->addSubscriber($attr);
  if (!$self->{error} || $self->{error} == 12339) {
    if ($self->{error} && $self->{error} == 12339) {
      $self->unSubscribeService({ %$attr, SKIP_FILTER => 1 });
    }

    delete $self->{error};
    $self->subscribeService($attr);
  }

  return $self;
}

#**********************************************************
=head2 _get($request)

  Arguments:
    $request
    $attr
      LIST_SECTION - List section Default: subscriber
      AUTH_HEADER  - Add auth header

  Results:

=cut
#**********************************************************
sub _request {
  my ($self, $request, $attr) = @_;

  $request =~ s/\"/\\\"/xg;
  my $host = $self->{unc_host};
  $attr->{AUTH_HEADER} = 1;
  if ($attr->{AUTH_HEADER}) {
    my $auth_header = << "REQ";
<soapenv:Header>
      <header>
         <authentication>
            <userPass>
               <username>$self->{unc_login}</username>
               <password>$self->{unc_password}</password>
            </userPass>
         </authentication>
      </header>
   </soapenv:Header>
REQ

    $request =~ s/<soapenv:Header\/>/$auth_header/xg;
  }
  else {
    if (!$self->{unc_session_id} && !$attr->{SKIP_NOTIFY}) {
      $self->auth();
    }

    if ($self->{unc_session_id}) {
      $host = $self->{unc_session_id};
    }
  }

  my ($result, $header) = web_request($host, {
    POST          => $request,
    CURL          => 1,
    DEBUG         => $self->{debug} || 1,
    DEBUG2FILE    => $self->{DEBUG_FILE},
    CURL_OPTIONS  => "--keepalive-time 60 --keepalive",
    #CURL_OPTIONS  => " --keepalive",
    #FILE_CURL => '/usr/bin/curl -k ',
    SKIP_REDIRECT => 1,
    GET_HEADERS   => 1,
    HEADERS       =>
      [
        "Content-Type: text/xml;charset=UTF-8",
        "SOAPAction: " . (($attr->{SKIP_NOTIFY}) ? q{} : 'Notification'),
        "Connection: keep-alive",
        "Keep-Alive: timeout=10, max=100"
        #     # "Content-Length: " . $data_length,
        #     # "SOAPACTION: " . '\"basic_event#SetMultiState\"',
        #     # 'Content-Type: text/xml; charset=\"utf-8\"',
        #     # 'Accept: \"text/xml\"'
      ],
    TIMEOUT       => 30,
    AID           => $self->{AID}
  });

  if ($header->{headers}->{Location}) {
    #$header->{headers}->{Location} =~ /\/([a-z0-9]+)/i;
    $self->{unc_session_id} = $header->{headers}->{Location};
    $self->{unc_session_id} =~ s/[\r\n]+//xg;
  }

  if ($result =~ m/^HTTP/x) {
    (undef, $result) = split(/\r?\n\r?\n/x, $result, 2);
  }

  #my %request_params = ();

  my $_xml = eval {XML::Simple::XMLin($result, forcearray => 1)};
  if ($@) {
    # main::mk_log("CONTENT:\n" . $FORM->{__BUFFER} . "\n-- XML Error:\n" . $@ . "\n--\n",
    #   { PAYSYS_ID => 'Ipay', HEADER => 1 });
    print "XML_ERROR: $result\n $!\n";
    return 0;
  }

  my $request_response = q{};

  if ($_xml->{'SOAP-ENV:Body'}->[0]) {
    ($request_response) = keys %{$_xml->{'SOAP-ENV:Body'}->[0]};
  }

  # if ($self->{debug}) {
  #   print "\n--\nRESULT CODE:";
  #   print $_xml->{'SOAP-ENV:Body'}->[0]->{$request_response}->[0]->{result}->[0]->{resultCode}->[0];
  #   print "\nDESCRIBE: "
  #   ;
  #   print $_xml->{'SOAP-ENV:Body'}->[0]->{$request_response}->[0]->{result}->[0]->{paras}->[0]->{value}->[0];
  #   print "\n";
  # }

  if ($_xml->{'SOAP-ENV:Body'}->[0]->{$request_response}->[0]->{result}->[0]->{resultCode}->[0]) {
    $self->{error} = $_xml->{'SOAP-ENV:Body'}->[0]->{$request_response}->[0]->{result}->[0]->{resultCode}->[0];
    $self->{errstr} = $_xml->{'SOAP-ENV:Body'}->[0]->{$request_response}->[0]->{result}->[0]->{paras}->[0]->{value}->[0];
  }

  my $list_section = $attr->{LIST_SECTION} || 'subscriber';

  my @result_list = ();
  foreach my $data (@{$_xml->{'SOAP-ENV:Body'}->[0]->{$request_response}->[0]->{result}->[0]->{$list_section}}) {
    foreach my $line (@{$data->{attribute}}) {
      push @result_list, { key => $line->{key}->[0], value => $line->{value}->[0] };
      #print "$line->{key}->[0] => $line->{value}->[0] <br>\n";
    }
  }

  $self->{data} = \@result_list;

  return $self;
}


#**********************************************************
=head2 getSubscriberAllInf($request)

  Arguments:
    $request

  Results:

=cut
#**********************************************************
sub getSubscriberAllInf {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};

  my $request = << "REQ";
<?xml version="1.0" encoding="utf-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:rm="rm:soap">
    <soapenv:Header/>
    <soapenv:Body>
        <rm:getSubscriberAllInf>
            <inPara>
                <subscriber>
                    <attribute>
                        <key>usrIdentifier</key>
                        <value>$subscriber_id</value>
                    </attribute>
                </subscriber>
                <subscribedService>
                    <attribute>
                        <key>timeZone</key>
                        <value>30</value>
                    </attribute>
                    <attribute>
                        <key>DSTFlag</key>
                        <value>0</value>
                    </attribute>
                    <attribute>
                        <key>realTimeFlag</key>
                        <value>0</value>
                    </attribute>
                    <attribute>
                        <key>SHOWGRACEPERIOD</key>
                        <value>0</value>
                    </attribute>
                </subscribedService>
            </inPara>
        </rm:getSubscriberAllInf>
    </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request, { LIST_SECTION => 'subscribedService' });

  return $self;
}

#**********************************************************
=head2 getGroupMemberList($request)

  Arguments:
    $request

  Results:

=cut
#**********************************************************
sub getGroupMemberList {
  my $self = shift;

  my $request =<< "REQ";
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:rm="rm:soap">
 <soapenv:Header/>
 <soapenv:Body>
      <rm:getGroupMemberList>
         <inPara>
            <subscriber>
               <attribute>
                  <key>GRPIDENTIFIER</key>
                  <value>420722009813</value>
               </attribute>
            </subscriber>
         </inPara>
      </rm:getGroupMemberList>
 </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request);

  return $self;
}

#**********************************************************
=head2 addSubscriber($attr)

  Arguments:
    $attr
      CPE_MAC || CID

  Results:
    $self

=cut
#**********************************************************
sub addSubscriber {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};

  my $request = <<"REQ";
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:rm="rm:soap">
   <soapenv:Header/>
   <soapenv:Body>
      <rm:addSubscriber>
         <inPara>
            <subscriber>
               <!--Subscriber Information-->
               <attribute>
                  <key>usrIdentifier</key>
                  <value>$subscriber_id</value>
               </attribute>
               <attribute>
                  <key>usrState</key>
                  <value>1</value>
               </attribute>
              <attribute>
                  <key>usrPaidType</key>
                  <value>0</value>
               </attribute>
               <attribute>
                  <key>usrStation</key>
                  <value>1</value>
               </attribute>
               <attribute>
                  <key>usrSubNetType</key>
                  <value>3</value>
               </attribute>
               <attribute>
                  <key>usrContactMethod</key>
                  <value>128</value>
               </attribute>
            </subscriber>
         </inPara>
      </rm:addSubscriber>
   </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request);

  return $self;
}

#**********************************************************
=head2 delSubscriber($attr)

  Arguments:
    $attr
      CPE_MAC || CID

  Results:

=cut
#**********************************************************
sub delSubscriber {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};

  my $request =<< "REQ";
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:rm="rm:soap">
    <soapenv:Header/>
    <soapenv:Body>
        <rm:delSubscriber>
            <inPara>
                <subscriber>
                    <attribute>
                        <key>usrIdentifier</key>
                        <value>$subscriber_id</value>
                    </attribute>
                    <attribute>
                        <key>usrForceRmv</key>
                        <value>1</value>
                    </attribute>
                </subscriber>
            </inPara>
        </rm:delSubscriber>
    </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request);

  return $self;
}

#**********************************************************
=head2 getSubscriber($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub getSubscriber {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};

  my $request = << "REQ";
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:rm="rm:soap">
    <soapenv:Header/>
    <soapenv:Body>
        <rm:getSubscriber>
            <inPara>
                <subscriber>
                    <attribute>
                        <key>usrIdentifier</key>
                        <value>$subscriber_id</value>
                    </attribute>
                </subscriber>
            </inPara>
        </rm:getSubscriber>
    </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request);

  return $self;
}

#**********************************************************
=head2 subscribeService($attr)

  Arguments:
    $attr
      CPE_MAC || CID
      TP_FILTER_ID || FILTER_ID

  Results:
    $self

=cut
#**********************************************************
sub subscribeService {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};
  my $srv_name = $attr->{TP_FILTER_ID} || $attr->{FILTER_ID} || 'NO_SERVICE'; #S_1000GB_Quotatest'; # 'S_5Gunlimited_test' 'Service1';
  my $srv_start_date_time = strftime("%Y%m%d%H:%M:%S", localtime(time));;
  $srv_start_date_time =~ s/[-:\s]+//xg;
  # my $srvEndDateTime = '20280522131214';
  # my $srvStatus = 0; # 0 normal 1 - frozen

  my $request =<< "REQ";
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:rm="rm:soap">
    <soapenv:Header/>
    <soapenv:Body>
        <rm:subscribeService>
            <inPara>
                <subscriber>
                    <!--Identifier of the subscriber-->
                    <attribute>
                        <key>usrIdentifier</key>
                        <value>$subscriber_id</value>
                    </attribute>
                </subscriber>
                <subscribedService>
                    <attribute>
                        <key>srvName</key>
                        <value>$srv_name</value>
                    </attribute>
                    <attribute>
                        <key>srvRoamingType</key>
                        <value>1</value>
                    </attribute>
                    <attribute>
                        <key>srvStatus</key>
                        <value>0</value>
                    </attribute>
                </subscribedService>
            </inPara>
        </rm:subscribeService>
    </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request);

  return $self;
}

#**********************************************************
=head2 unSubscribeService($attr)

  Arguments:
    $attr
      CPE_MAC || CID
      FILTER_ID

  Results:

=cut
#**********************************************************
sub unSubscribeService {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};
  my $srv_name = $attr->{TP_FILTER_ID} || $attr->{FILTER_ID} || q{};

  if ($attr->{SKIP_FILTER}) {
    $srv_name = q{};
  }

  if (!$srv_name) {
    $self->getSubscriberAllService($attr);
    foreach my $line (@{$self->{data}}) {
      if ($line->{key} eq 'SRVNAME') {
        $srv_name = $line->{value};
      }
    }
  }

  if (!$srv_name) {
    return $self;
  }

  my $request = << "REQ";
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:rm="rm:soap">
    <soapenv:Header/>
    <soapenv:Body>
        <rm:unSubscribeService>
            <inPara>
                <subscriber>
                    <attribute>
                        <key>usrIdentifier</key>
                        <value>$subscriber_id</value>
                    </attribute>
                </subscriber>
                <subscribedService>
                    <attribute>
                        <key>srvName</key>
                        <value>$srv_name</value>
                    </attribute>
                    <attribute>
                        <key>TermInd</key>
                        <value>1</value>
                    </attribute>
                    <attribute>
                        <key>srvDeleteSubscriber</key>
                        <value>0</value>
                    </attribute>
                </subscribedService>
            </inPara>
        </rm:unSubscribeService>
    </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request);

  return $self;
}

#**********************************************************
=head2 getSubscriberAllService($attr)

  Arguments:
    $attr
      CPE_MAC || CID

  Results:

=cut
#**********************************************************
sub getSubscriberAllService {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};

  my $request =<< "REQ";
<?xml version="1.0" encoding="utf-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:rm="rm:soap">
    <soapenv:Header/>
    <soapenv:Body>
        <rm:getSubscriberAllService>
            <inPara>
                <subscriber>
                    <attribute>
                        <key>usrIdentifier</key>
                        <value>$subscriber_id</value>
                    </attribute>
                </subscriber>
                <subscribedService>
                    <attribute>
                        <key>timeZone</key>
                        <value>30</value>
                    </attribute>
                    <attribute>
                        <key>DSTFlag</key>
                        <value>0</value>
                    </attribute>
                    <attribute>
                        <key>SHOWGRACEPERIOD</key>
                        <value>0</value>
                    </attribute>
                </subscribedService>
            </inPara>
        </rm:getSubscriberAllService>
    </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request, { LIST_SECTION => 'subscribedService' });

  return $self;
}

#**********************************************************
=head2 getSubscriberAllService($attr)

  Arguments:
    $attr
      CPE_MAC || CID
      TP_FILTER_ID || FILTER_ID

  Results:
    $self

=cut
#**********************************************************
sub getSubscriberSpecService {
  my ($self, $attr) = @_;

  my $srv_name = $attr->{TP_FILTER_ID} || $attr->{FILTER_ID} || 'NO_SERVICE';
  my $subscriber_id = $attr->{$ident_field} || q{};
  if (!$srv_name) {
    $self->getSubscriberAllService($attr);
    foreach my $line (@ {$self->{data}}) {
      if ($line->{key} eq 'SRVNAME') {
        $srv_name = $line->{value};
      }
    }
  }

  my $request =<< "REQ";
<?xml version="1.0" encoding="utf-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:rm="rm:soap">
    <soapenv:Header/>
    <soapenv:Body>
        <rm:getSubscriberSpecService>
            <inPara>
                <subscriber>
                    <attribute>
                        <key>usrIdentifier</key>
                        <value>$subscriber_id</value>
                    </attribute>
                </subscriber>
                <subscribedService>
                    <attribute>
                        <key>srvName</key>
                        <value>$srv_name</value>
                    </attribute>
                    <attribute>
                       <key>showQuota</key>
                       <value>1</value>
                    </attribute>
            </subscribedService>
        </inPara>
    </rm:getSubscriberSpecService>
</soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request, { LIST_SECTION => 'subscribedService' });

  return $self;
}


sub resetSubscriberQuota {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};

  my $request =<< "REQ";
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:rm="rm:soap">
    <soapenv:Header/>
    <soapenv:Body>
        <rm:resetSubscriberQuota>
            <inPara>
                <subscriber>
                    <attribute>
                        <key>usrIdentifier</key>
                        <value>$subscriber_id</value>
                    </attribute>
                </subscriber>
                <subscriberQuota>
                    <attribute>
                        <key>qtaName</key>
                        <value>daily5M</value>
                    </attribute>
                </subscriberQuota>
            </inPara>
        </rm:resetSubscriberQuota>
    </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request, { LIST_SECTION => 'subscriberQuota' });

  return $self;
}

sub getSubscriberAllQuota {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};

  my $request =<< "REQ";
<?xml version="1.0" encoding="utf-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"xmlns:rm="rm:soap">
    <soapenv:Header/>
    <soapenv:Body>
        <rm:getSubscriberAllQuota>
            <inPara>
                <subscriber>
                    <attribute>
                        <key>usrIdentifier</key>
                        <value>$subscriber_id</value>
                    </attribute>
                </subscriber>
                <subscriberQuota>
                    <attribute>
                        <key>realTimeFlag</key>
                        <value>0</value>
                    </attribute>
                    <attribute>
                        <key>SHOWGRACEPERIOD</key>
                        <value>0</value>
                    </attribute>
                </subscriberQuota>
            </inPara>
        </rm:getSubscriberAllQuota>
    </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request, { LIST_SECTION => 'subscriberQuota' });

  return $self;
}

#**********************************************************
=head2 getSubscriberSpecQuota($attr)

  Arguments:
    $attr
      CPE_MAC || CID
      QTANAME

  Results:

=cut
#**********************************************************
sub getSubscriberSpecQuota {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};
  my $qtaName = $attr->{QTANAME} || q{};

  if (!$qtaName) {
    $self->getSubscriberAllQuota($attr);
    foreach my $line (@ {$self->{data}}) {
      if ($line->{key} eq 'QTANAME') {
        $qtaName = $line->{value};
      }
    }
  }

  my $request =<< "REQ";
<?xml version="1.0" encoding="utf-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:rm="rm:soap">
    <soapenv:Header/>
    <soapenv:Body>
        <rm:getSubscriberSpecQuota>
            <inPara>
                <subscriber>
                    <attribute>
                        <key>usrIdentifier</key>
                        <value>$subscriber_id</value>
                    </attribute>
                </subscriber>
                <subscriberQuota>
                    <attribute>
                        <key>qtaName</key>
                        <value>$qtaName</value>
                    </attribute>
                    <attribute>
                        <key>realTimeFlag</key>
                        <value>0</value>
                    </attribute>
                    <attribute>
                        <key>SHOWGRACEPERIOD</key>
                        <value>0</value>
                    </attribute>
                </subscriberQuota>
            </inPara>
        </rm:getSubscriberSpecQuota>
    </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request, { LIST_SECTION => 'subscriberQuota' });

  return $self;
}

#**********************************************************
=head2 getSubscriberAccount($attr)

  Arguments:
    $attr
      CPE_MAC || CID

  Results:

=cut
#**********************************************************
sub getSubscriberAccount {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};

  my $request =<< "REQ";
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:rm="rm:soap">
    <soapenv:Header/>
    <soapenv:Body>
        <rm:getSubscriberAccount>
            <inPara>
                <subscriber>
                    <attribute>
                        <key>usrIdentifier</key>
                        <value>$subscriber_id</value>
                    </attribute>
                </subscriber>
            </inPara>
        </rm:getSubscriberAccount>
    </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request, { LIST_SECTION => 'subscriberAccount' });

  return $self;
}


#**********************************************************
=head2 updateSubscriberQuota($attr)

  Arguments:
    $attr
      CPE_MAC || CID
      PREPAID
      QTANAME

  Results:
    $self

=cut
#**********************************************************
sub updateSubscriberQuota {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};
  #my $srvName = $attr->{TP_FILTER_ID} || $attr->{FILTER_ID} || 'NO_SERVICE';
  my $qta_balance = $attr->{PREPAID} || 0;
  my $qta_name = $attr->{QTANAME} || q{};

  if (!$qta_name) {
    $self->getSubscriberAllQuota($attr);
    foreach my $line (@ {$self->{data}}) {
      if ($line->{key} eq 'QTANAME') {
        $qta_name = $line->{value};
      }
    }
  }

  $qta_balance = $qta_balance * 1024 * 1024;

  my $request =<< "REQ";
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:rm="rm:soap">
    <soapenv:Header/>
    <soapenv:Body>
        <rm:updateSubscriberQuota>
            <inPara>
                <subscriber>
                    <attribute>
                        <key>usrIdentifier</key>
                        <value>$subscriber_id</value>
                    </attribute>
                </subscriber>
                <subscriberQuota>
                    <attribute>
                        <key>qtaName</key>
                        <value>$qta_name</value>
                    </attribute>
                    <attribute>
                        <key>qtaBalance</key>
                        <value>$qta_balance</value>
                    </attribute>
                    <attribute>
                        <key>qtaConsumption</key>
                        <value>0</value>
                    </attribute>
                    <attribute>
                        <key>realTimeFlag</key>
                        <value>0</value>
                    </attribute>
                </subscriberQuota>
            </inPara>
        </rm:updateSubscriberQuota>
    </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request);

  return $self;
}

#**********************************************************
=head2 online_filter($value)

  Argumnets:
    $value

  Results:
    $filtered_value

=cut
#**********************************************************
sub online_filter {
  my ($self, $value) = @_;

  my $filtered_value = q{};

  if (!$value) {
    return q{};
  }

  $value =~ s/^0x//x;

  my $hex_string = $value;              #'8904f10100290504f101098e4b72c0';  # Input hex string
  my $binary = pack('H*', $hex_string); # Convert hex string to binary data
  my @bytes = unpack('C*', $binary);    # Convert binary to byte array

  # Extract Geographic Location Type
  my $geo_type = sprintf("0x%02X", $bytes[0]);

  # Decode TAI (Tracking Area Identity)
  my $mcc_tai = sprintf("%d%d%d", ($bytes[1] & 0x0F), ($bytes[1] >> 4), ($bytes[2] & 0x0F));

  my $mnc_tai = sprintf("%d%d", ($bytes[3] & 0x0F), ($bytes[3] >> 4));
  $mnc_tai .= sprintf("%d", ($bytes[2] >> 4)) if (($bytes[2] >> 4) != 0xF); # 3-digit MNC handling

  my $tac = sprintf("0x%02X%02X%02X", $bytes[4], $bytes[5], $bytes[6]);

  # Decode MCC and MNC (NCGI)
  my $mcc_ncgi = sprintf("%d%d%d", ($bytes[7] & 0x0F), ($bytes[7] >> 4), ($bytes[8] & 0x0F));
  my $mnc_ncgi = sprintf("%d%d", ($bytes[9] & 0x0F), ($bytes[9] >> 4));
  #  $mnc_ncgi .= sprintf("%d", ($bytes[7] >> 4)) if (($bytes[7] >> 4) != 0xF);

  # Decode NR Cell ID
  my $nr_cell_id = (($bytes[10] << 24) | ($bytes[11] << 16) | ($bytes[12] << 8) | $bytes[13]);
  my $last_section = '0x';

  foreach my $byte (@bytes[10 .. 14]) {
    $last_section .= sprintf('%02x', $byte);
  }
  $last_section =~ s/0$//x;

  #Using Math::Bigint
  $nr_cell_id = Math::BigInt->from_hex($last_section);
  my $tac_dec = Math::BigInt->from_hex($tac);

  my $cell_id    = 0x03da54201;  # example NR Cell ID
  my $gNBId_len  = 28;           # length of gNBId in bits (22..32)

  my $cellLocalId_len = 36 - $gNBId_len;

  my $gNBId       = $cell_id >> $cellLocalId_len;
  my $cellLocalId = $cell_id & ((1 << $cellLocalId_len) - 1);

  # Print results
  $filtered_value .= "Geographic Location Type: $geo_type\n";
  $filtered_value .= "TAI - MCC: $mcc_tai, MNC: $mnc_tai, TAC: $tac_dec ($tac)\n";
  $filtered_value .= "NCGI - MCC: $mcc_ncgi, MNC: $mnc_ncgi, NR Cell ID: $nr_cell_id ($last_section)\n";
  $filtered_value .= sprintf("gNB ID : 0x%X (%d)", $gNBId, $gNBId);
  $filtered_value .= sprintf(" cellLocalId   : 0x%X (%d)\n", $cellLocalId, $cellLocalId);

  if (!$self) {
    $filtered_value =~ s/\n/<br>/xg;
  }

  return $filtered_value;
}



#**********************************************************
=head2 setIp($attr)

  Arguments:
    $attr
      CPE_MAC || CID

  Results:

=cut
#**********************************************************
sub ip_add {
  my ($self, $attr) = @_;

  my $subscriber_id = $attr->{$ident_field} || q{};
  my $ip = $attr->{IP} || q{};

  my $request =<< "REQ";
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:hss="http://www.huawei.com/HSS">
  <soapenv:Header>
      <hss:Username>user</hss:Username>
      <hss:Password>password</hss:Password>
  </soapenv:Header>
  <soapenv:Body>
     <hss:MOD_SMDATA>
     <!--Description: variable CID-->
       <hss:IMSI>$subscriber_id</hss:IMSI>
         <!--Description: fixed for FWA -->
         <hss:SNSSAI>1-000201</hss:SNSSAI>
         <!--Description: obtained from LST_SMDATA -->
         <hss:DNN>fwa</hss:DNN>
         <!--Description: IPv4 provisioning flag -->
         <hss:IPV4IND>TRUE</hss:IPV4IND>
         <!--Description: IPv4 value-->
         <hss:IPV4ADDR>$ip</hss:IPV4ADDR>
         <!--Description: new DNN for static IP service-->
         <hss:NEWDNN>fwa-static</hss:NEWDNN>
  </hss:MOD_SMDATA>
  </soapenv:Body>
</soapenv:Envelope>
REQ

  $self->_request($request);

  return $self;
}




1;