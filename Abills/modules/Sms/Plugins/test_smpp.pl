#!/usr/bin/perl
#use strict;
#use warnings;
use Net::SMPP::SSL;
#use IO::Socket::SSL;

my $host = '185.233.3.32'; #gate30.edna.ru';
my $port = 14102; # without_tls 14101;  #14102;
my $username = 'ftel1';
my $password = 'tgTALNvp';
my $source_addr = 'FreedomTel';
my $destination = '+77059813049';
my $facil = 0x00010003;  # NF_PDC | GF_PVCY
my $if_vers = 0x34; # 0x34;
my $vers = 0x40;  #4


my $message = qq{Құрметті клиент!
Еске саламыз, 1 тарифіңіз бойынша %TP_MONTH_FEE% тг абоненттік төлем алынады.
Қолдау қызметі: 4000
Уважаемый клиент!
Напоминаем, что 1 спишется абонплата %TP_MONTH_FEE% тг. по Вашему тарифу.
Служба поддержки: 4000
};

# $message = qq{Uvazhaemyj klient!
# Napominaem, chto 1 spishetsya abonplata %TP_MONTH_FEE% tg. po Vashemu tarifu.
# Sluzhba podderzhki: 4000
#
# Құrmetti klient!
# Eske salamyz, 1 tarifiңiz bojynsha %TP_MONTH_FEE% tg abonenttik tөlem alynady.
# Қoldau қyzmeti: 4000
# };

# $message = qq{Unless you wrote your program to be multithreaded or multiprocess, everything will happen in one thread of execution. Thus if you get unbind while doing something else (e.g. checking your spool directory),};

#$message =~ s/\n/ /g;

use Encode;
$message = decode('utf-8',  $message);
$message = encode('UCS-2',  $message);
#$message = decode('UCS-2',  $message);
#print $message . "\n";
print "Host: $host:$port";
my $smpp = Net::SMPP::SSL->new_transmitter(
  $host,
  port              => $port,
  system_id         => $username,
  password          => $password,
  system_type       => "",
  #smpp_version      => $vers,
  interface_version => $if_vers,
  addr_ton          => 0x00,
  addr_npi          => 0x00,
  address_range     => "",

  use_ssl           => 1,     # Enable TLS
  async             => 0,

  # source_addr_ton => 0x09,
  # source_addr_npi => 0x00,
  # dest_addr_ton => 0x09,
  # dest_addr_npi => 0x00,
  system_type => '_001',
  facilities_mask => $facil,
  port => $port,
) or die;

test();
exit;

my $resp_pdu;
my $multimsg_maxparts = 120;
my $multimsg_curpart = 0;

if (length($message) > $multimsg_maxparts) {
  my $ref = 160;
  my $origref = $ref;
  my $mymsg = $message;
  my $multimsg = 1;

  #print "FELIX: Now checking length of string: ".length ($mymsg)."\n";
  if (length ($mymsg) > 128) {
    $multimsg_maxparts = int (length ($mymsg) / 128);
    if (length ($mymsg) % 128) {
      $multimsg_maxparts++;
    }
    $multimsg_curpart = 1;
    print "multimsgsparts: $multimsg_maxparts\n";
  }

  my $msgtext = substr ($mymsg, 0, 128, "");
  while (length ($msgtext)) {
    ### See V4, p. 77
    if ($multimsg_curpart) {
      $multimsg = pack ("nCC", $origref, $multimsg_curpart, $multimsg_maxparts);
      printf STDERR "\nI AM SETTING MULTIPART: len=%d\n", $multimsg;
    }
    else {
      $multimsg = undef;
    }

    printf ("Now sending: (multimsg = %.8x) (len: %d) %s\n", $multimsg, length ($msgtext), decode('UCS-2',  $msgtext));
    my $msgref = sprintf("%.8d", $ref);
    print "MESSAGE REFERENCE: $msgref  REF= $ref\n";

    $resp_pdu = $smpp->submit_sm(
      message_class            => 0,
      protocol_id              => 0x20, # telematic_interworking
      validity_period          => 0,    # "default"
      source_addr_ton          => 0x05, #0x09
      source_addr              => $source_addr,
      destination_addr         => $destination,
      #			     msg_reference => '\0',
      msg_reference            => $msgref,
      priority_level           => 3,
      registered_delivery_mode => 0,
      data_coding              => 0x08 || 0x00, # #data_coding => 9,
      short_message            => $msgtext,

      PDC_MessageClass         => "\x20\x00",
      PDC_PresentationOption   => "\x01\xff\xff\xff",
      PDC_AlertMechanism       => "\x01",
      PDC_Teleservice          => "\x04",
      PDC_MultiPartMessage     => $multimsg,
      PDC_PredefinedMsg        => "\0",
      PVCY_AuthenticationStr   => "\x01\x00\x00",

      source_subaddress        => "\x01\x00\x00", # PDC_Originator_Subaddr
      dest_subaddress          => "\x01\x00\x00", # PDC_Destination_Subaddr
    );

    $multimsg_curpart++;
    $msgtext = substr ($mymsg, 0, 120, "");
    $ref++;
  }


  #***********************************
  # my $msgtext = $message;
  # while (length($msgtext)) {
  #   if ($multimsg_maxparts) {
  #     my @udh_ar = map {sprintf "%x", $_} $origref, $multimsg_maxparts, $multimsg_curpart;
  #     my $udh = pack("hhhhhh", 0x05, 0x00, 0x03, @udh_ar);
  #     $resp_pdu = $smpp->submit_sm(
  #       destination_addr => '+77059813049',
  #       short_message    => $udh . $msgtext,
  #       #short_message    => $message,
  #       source_addr_ton  => 0x05,
  #       source_addr_npi  => 0x00,
  #       source_addr      => $source_addr,
  #     );
  #   }
  # }
}
else {
  $resp_pdu = $smpp->submit_sm(
    destination_addr => $destination,
    short_message    => $message,
    source_addr_ton  => 0x05,
    source_addr_npi  => 0x00,
    source_addr      => $source_addr,
    data_coding      => 0x08 || 0x00, # default ok
    # source_addr_ton => 0x00, # default ok
    # source_addr_npi => 0x00, # default ok
    # source_addr => '',       # default ok
  ) or die;
}

die "Response indicated error: " . $resp_pdu->explain_status()
  if $resp_pdu->status;

my $msg_id = $resp_pdu->{message_id};

$resp_pdu = $smpp->query_sm(message_id => $msg_id) or die;
die "Response indicated error: " . $resp_pdu->explain_status()
  if $resp_pdu->status;

print "Message state is $resp_pdu->{message_state}\n";


sub test {

  # my $smpp = Net::SMPP->new_connect(
  #   $host,
  #   port              => $port,
  #   port              => $port,
  #   system_id         => $username,
  #   password          => $password,
  #   version           => 0x34,  # SMPP 3.4
  # );
  #
  # # Bind to SMPP
  # $smpp->bind_transmitter() or die "SMPP bind failed!";

  # Split the message into parts (153 chars per part for 7-bit encoding)
  my @parts = unpack("(A152)*", $message);
  my $total_parts = scalar(@parts);
  my $ref_num = int(rand(256));  # Random reference number

  for my $i (0 .. $#parts) {
    my $part_num = $i + 1;
    # User Data Header (UDH) for concatenation
    my $udh = pack("C6", 5, 0, 3, $ref_num, $total_parts, $part_num);

    # Final message with UDH
    my $sms_part = $udh . $parts[$i];

    # Submit each part separately
    $smpp->submit_sm(
      source_addr      => $source_addr,
      destination_addr => $destination,
      short_message    => $sms_part,
      source_addr_ton  => 0x05,
      data_coding      => 0x08 || 0x00, # #data_coding => 9,
      #data_coding      => 0,  # 0 = GSM 7-bit encoding
      esm_class        => 0x40,  # Indicates UDH presence
    );

    $debug = 1;
    if ($debug) {
      print "Sent part $part_num/$total_parts\n";
      print "$sms_part\n";
      print decode('UCS-2', $sms_part);
      print "\n";
    }
  }

  # Close connection
  $smpp->unbind();

  return 1;
}


1;