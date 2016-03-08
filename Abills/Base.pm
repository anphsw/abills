package Abills::Base;

#Base functions
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use POSIX qw(locale_h);


use Exporter;


$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw(
&get_radius_params
&null
&convert
&parse_arguments
&startup_files
&int2ip
&ip2int
&int2byte
&sec2date
&sec2time
&time2sec
&int2ml
&show_log
&mk_unique_value
&decode_base64
&check_time
&sendmail
&in_array
&tpl_parse
&encode_base64
&cfg2hash
&clearquotes
&cmd
&ssh_cmd
&date_diff
&date_format
&_bp
&urlencode
&urldecode
);

@EXPORT_OK = qw(
null
convert
get_radius_params
parse_arguments
startup_files
int2ip
ip2int
int2byte
sec2date
sec2time
time2sec
int2ml
show_log
mk_unique_value
decode_base64
check_time
sendmail
in_array
tpl_parse
encode_base64
cfg2hash
clearquotes
cmd
ssh_cmd
date_diff
date_format
_bp
urlencode
urldecode
);

%EXPORT_TAGS = ();

#**********************************************************
# Null function
#
#**********************************************************
sub null {

  return 1;
}

#**********************************************************
# Convert cft str to hash
#
# cfg format:
#  key:value;key:value;key:value;
#
#**********************************************************
sub cfg2hash {
  my ($cfg, $attr) = @_;
  my %hush = ();

  return \%hush if (!$cfg);
  $cfg =~ s/\n//g;
  my @payments_methods_arr = split(/;/, $cfg);

  foreach my $line (@payments_methods_arr) {
    my ($k, $v) = split(/:/, $line, 2);
    $k =~ s/^\s+//;
    $hush{$k} = $v;
  }

  return \%hush;
}

#**********************************************************
# in_array()
# Check value in array
#**********************************************************
sub in_array($$) {
  my ($value, $array) = @_;

  return 0 if (!defined($value));

  if ( $] <= 5.010 ) {
    if (grep { $_ eq $value } @$array) {
      return 1;
    }
  }
  else {
    if ($value ~~ @$array) {
      return 1;
    }
  }

  return 0;
}

#**********************************************************
# Converter
#   Attributes
#     text2html - convert text to HTML
#     html2text - 
#
#   Transpation
#    win2koi
#    koi2win
#    win2iso
#    iso2win
#    win2dos
#    dos2win
#
# convert($text, $attr)
#**********************************************************
sub convert {
  my ($text, $attr) = @_;

  # $str =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
  if (defined($attr->{text2html})) {
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/\"/&quot;/g;
    $text =~ s/\n/<br\/>\n/gi;
    $text =~ s/\%/\&#37/g;
    $text =~ s/\*/&#42;/g;
    #$text =~ s/\+/\%2B/g;

    if ($attr->{SHOW_URL}) {
      $text =~ s/([https|http]+:\/\/[a-z\.0-9\/\?\&\-\_\#:\=]+)/<a href=\'$1\' target=_new>$1<\/a>/ig;
    }
  }
  elsif (defined($attr->{html2text})) {
  	$text =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
  }
  elsif ($attr->{'from_tpl'}) {
    $text =~ s/textarea/__textarea__/g;
  }
  elsif ($attr->{'2_tpl'}) {
    $text =~ s/__textarea__/textarea/g;
  }
  elsif ($attr->{win2utf8}) { $text = win2utf8($text);}
  elsif ($attr->{utf82win}) { $text = utf82win($text);}
  elsif ($attr->{win2koi})  { $text = win2koi($text); }
  elsif ($attr->{koi2win})  { $text = koi2win($text); }
  elsif ($attr->{win2iso})  { $text = win2iso($text); }
  elsif ($attr->{iso2win})  { $text = iso2win($text); }
  elsif ($attr->{win2dos})  { $text = win2dos($text); }
  elsif ($attr->{dos2win})  { $text = dos2win($text); }

  return $text;
}

sub win2koi {
  my $pvdcoderwin = shift;
  $pvdcoderwin =~
tr/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/\xE1\xE2\xF7\xE7\xE4\xE5\xF6\xFA\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFE\xFB\xFD\xFF\xF9\xF8\xFC\xE0\xF1\xC1\xC2\xD7\xC7\xC4\xC5\xD6\xDA\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDE\xDB\xDD\xDF\xD9\xD8\xDC\xC0\xD1/;
  return $pvdcoderwin;
}

sub koi2win {
  my $pvdcoderwin = shift;
  $pvdcoderwin =~
tr/\xE1\xE2\xF7\xE7\xE4\xE5\xF6\xFA\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFE\xFB\xFD\xFF\xF9\xF8\xFC\xE0\xF1\xC1\xC2\xD7\xC7\xC4\xC5\xD6\xDA\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDE\xDB\xDD\xDF\xD9\xD8\xDC\xC0\xD1\xA6/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF\xB3/;
  return $pvdcoderwin;
}

# возращает перекодированную переменную, вызов win2iso(<переменна€>)
sub win2iso {
  my $pvdcoderiso = shift;
  $pvdcoderiso =~
tr/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/;
  return $pvdcoderiso;
}

sub iso2win {
  my $pvdcoderiso = shift;
  $pvdcoderiso =~
tr/\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/;
  return $pvdcoderiso;
}

# возращает перекодированную переменную, вызов win2dos(<переменна€>)
sub win2dos {
  my $pvdcoderdos = shift;
  $pvdcoderdos =~
tr/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/;
  return $pvdcoderdos;
}

sub dos2win {
  my $pvdcoderdos = shift;
  $pvdcoderdos =~
tr/\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/;
  return $pvdcoderdos;
}

#**********************************************************
# http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1251.TXT
#**********************************************************
sub win2utf8 {
  my ($text) = @_;

  #my $TestLine='јаЅб¬в√гƒд≈е®Є∆ж«з»и…й кЋлћмЌнќоѕп–р—с“т”у‘ф’х÷ц„чЎшўщЏъџы№ьЁэёюя€≥≤';
  my @ChArray = split('', $text);
  my $Unicode = '';
  my $Code    = '';
  for (@ChArray) {
    $Code = ord;

    #return $Code;
    if (($Code >= 0xc0) && ($Code <= 0xff)) { $Unicode .= "&#" . (0x350 + $Code) . ";"; }
    elsif ($Code == 0xa8) { $Unicode .= "&#" . (0x401) . ";"; }
    elsif ($Code == 0xb8) { $Unicode .= "&#" . (0x451) . ";"; }
    elsif ($Code == 0xb3) { $Unicode .= "&#" . (0x456) . ";"; }
    elsif ($Code == 0xaa) { $Unicode .= "&#" . (0x404) . ";"; }
    elsif ($Code == 0xba) { $Unicode .= "&#" . (0x454) . ";"; }
    elsif ($Code == 0xb2) { $Unicode .= "&#" . (0x406) . ";"; }
    elsif ($Code == 0xaf) { $Unicode .= "&#" . (0x407) . ";"; }
    elsif ($Code == 0xbf) { $Unicode .= "&#" . (0x457) . ";"; }
    else                  { $Unicode .= $_; }
  }

  return $Unicode;
}

#**********************************************************
# http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1251.TXT
# http://www.utf8-chartable.de/unicode-utf8-table.pl
#**********************************************************
sub utf82win {
  my ($text) = @_;

  require Encode;
  Encode->import();
  my $win1251 = encode('cp1251', decode('utf8', $text));
  return $win1251;

  #
  #
  #  for(@ChArray){
  #    $Code=ord;
  #    if($Code==0x0406)       { $Unicode.=chr(0xB2); }
  #    elsif($Code==0x0454)    { $Unicode.=chr(0xBA); } #
  #    elsif($Code==0x0456)    { $Unicode.=chr(0xB3); } # CYRILLIC SMALL LETTER BYELORUSSIAN-UKRAINIAN I
  #    elsif($Code==0x0491)    { $Unicode.=chr(0xB4); } #
  #    elsif($Code==0x0457)    { $Unicode.=chr(0xBF); }
  #    elsif(($Code>=0x410)&&($Code<=0xff+0x44f)){$Unicode.=chr($Code-0x350);}
  #    elsif($Code==0x404)     { $Unicode.=chr(0xAA); }
  #    elsif($Code==0x407)     { $Unicode.=chr(0xAF); }
  #    elsif($Code==0x2116)    { $Unicode.=chr(0xB9); }
  #    elsif($Code==0xa8+0x350){$Unicode.=chr(0x401-0x350);}
  #    elsif($Code==0xb8+0x350){$Unicode.=chr(0x451-0x350);}
  #    elsif($Code==0xb3+0x350){$Unicode.=chr(0x456-0x350);}
  #    elsif($Code==0xaa+0x350){$Unicode.=chr(0x404-0x350);}
  #    elsif($Code==0xba+0x350){$Unicode.=chr(0x454-0x350);}
  #    elsif($Code==0xb2+0x350){$Unicode.=chr(0x406-0x350);}
  #    elsif($Code==0xaf+0x350){$Unicode.=chr(0x407-0x350);}
  #    elsif($Code==0xbf+0x350){$Unicode.=chr(0x457-0x350);}
  #
  #    #elsif(($Code>=0x81)&&($Code<=0x200+0x44f)){ $Unicode.=chr($Code - 170); }
  #
  #    #elsif($Code==0x49){ $Unicode.='I';       }
  #    #elsif($Code==0x69){ $Unicode.='i';       }
  #    #elsif($Code==0x3F){ $Unicode.='?';       }
  #    #elsif($Code==0x20){ $Unicode.=' ';       }
  #    #elsif($Code==0x2C){ $Unicode.=',';       }
  #    #elsif($Code==0x2E){ $Unicode.='.';       }
  #    #elsif($Code==0x64){ $Unicode.='d';       }
  #    else{ $Unicode.= $_;
  #      }
  #   }
  #
  #  return $Unicode;
}

#**********************************************************
# Parse comand line arguments
# parse_arguments(@$argv)
#**********************************************************
sub parse_arguments {
  my ($argv) = @_;

  my %args = ();

  foreach my $line (@$argv) {
    if ($line =~ /=/) {
      my ($k, $v) = split(/=/, $line, 2);
      $args{"$k"} = (defined($v)) ? $v : '';
    }
    else {
      $args{"$line"} = 1;
    }
  }
  return \%args;
}

#***********************************************************
# sendmail($from, $to, $subject, $message, $charset, $priority)
# MAil Priorities:
#
# returns
# 1 - error
# 2 - reciever email not specified
#
#***********************************************************
sub sendmail {
  my ($from, $to_addresses, $subject, $message, $charset, $priority, $attr) = @_;
  if ($to_addresses eq '') {
    return 2;
  }
  my $SENDMAIL = (defined($attr->{SENDMAIL_PATH})) ? $attr->{SENDMAIL_PATH} : '/usr/sbin/sendmail';

  if (!-f $SENDMAIL) {
    print "Mail delivery agent not exists";
    return 0;
  }

  if (! $from) {
    return 0;
  }

  my $header = '';
  if ($attr->{MAIL_HEADER}) {
    foreach my $line (@{ $attr->{MAIL_HEADER} }) {
      $header .= "$line\n";
    }
  }

  my $ext_header = '';
  $message =~ s/#.+//g;
  if ($message =~ s/Subject: (.+)[\n\r]+//g) {
    $subject = $1;
  }
  if ($message =~ s/From: (.+)[\n\r]+//g) {
    $from = $1;
  }
  if ($message =~ s/X-Priority: (.+)[\n\r]+//g) {
    $priority = $1;
  }
  if ($message =~ s/To: (.+)[\r\n]+//gi) {
    $to_addresses = $1;
  }

  if ($message =~ s/Bcc: (.+)[\r\n]+//gi) {
    $ext_header = "Bcc: $1\n";
  }

  $to_addresses =~ s/[\n\r]//g;

  if ($attr->{ATTACHMENTS}) {
    my $boundary = "----------581DA1EE12D00AAA";
    $header .= "MIME-Version: 1.0
Content-Type: multipart/mixed;\n boundary=\"$boundary\"\n";

    $message = qq{--$boundary
Content-Type: text/plain; charset=$charset
Content-Transfer-Encoding: quoted-printable

$message};

    foreach my $attachment (@{ $attr->{ATTACHMENTS} }) {
      my $data = encode_base64($attachment->{CONTENT});
      $message .= qq{ 
--$boundary
Content-Type: $attachment->{CONTENT_TYPE};\n name="$attachment->{FILENAME}"
Content-transfer-encoding: base64
Content-Disposition: attachment;\n filename="$attachment->{FILENAME}"

$data}

    }
    $message .= "--$boundary" . "--\n\n";
  }
  
  if ($attr->{TEST})   {
    print "Test mode enable: $attr->{TEST}";
  }

  my @emails_arr = split(/;/, $to_addresses);
  foreach my $to (@emails_arr) {
    if ($attr->{TEST}) {
      print "To: $to\n";
      print "From: $from\n";
      print $ext_header;
      print "Content-Type: text/plain; charset=$charset\n";
      print "X-Priority: $priority\n" if ($priority);
      print $header;
      print "Subject: $subject\n\n";
      print "$message";
    }
    else {
      open(my $mail, "| $SENDMAIL -t") || die "Can't open file '$SENDMAIL' $!\n";
      print $mail "To: $to\n";
      print $mail "From: $from\n";
      print $mail $ext_header;
      print $mail "Content-Type: text/plain; charset=$charset\n" if (!$attr->{ATTACHMENTS});
      print $mail "X-Priority: $priority\n" if ($priority);
      print $mail "X-Mailer: ABillS\n";
      print $mail $header;
      print $mail "Subject: $subject \n\n";
      print $mail "$message";
      close($mail);
    }
  }

  return 1;
}

#**********************************************************
# show log
# show_log($uid, $type, $attr)
#  Attributes
#   PAGE_ROWS
#   PG
#   DATE
#   LOG_TYPE
#**********************************************************
sub show_log {
  my ($login, $logfile, $attr) = @_;

  my $output   = '';
  my @err_recs = ();
  my %types    = ();

  my $PAGE_ROWS = ($attr->{PAGE_ROWS})   ? $attr->{PAGE_ROWS} : 25;
  my $PG        = (defined($attr->{PG})) ? $attr->{PG}        : 1;

  $login =~ s/\*/\[\.\]\{0,100\}/g if ($login ne '');

  open(my $fh, "$logfile") || die "Can't open log file '$logfile' $!\n";
  my ($date, $time, $log_type, $action, $user, $message);
  while (<$fh>) {

    #Old
    #my ($date, $time, $log_type, $action, $user, $message)=split(/ /, $_, 6);
    #new

    if (/(\d+\-\d+\-\d+) (\d+:\d+:\d+) ([A-Z_]+:) ([A-Z_]+) \[(.+)\] (.+)/) {
      $date     = $1;
      $time     = $2;
      $log_type = $3;
      $action   = $4;
      $user     = $5;
      $message  = $6;
    }
    else {
      next;
    }

    if (defined($attr->{LOG_TYPE}) && "$log_type" ne "$attr->{LOG_TYPE}:") {
      next;
    }

    if (defined($attr->{DATE}) && $date ne $attr->{DATE}) {
      next;
    }

    if ($login ne "") {
      if ($user =~ /^[ ]{0,1}$login[ ]{0,1}$/i) {
        push @err_recs, $_;
        $types{$log_type}++;
      }
    }
    else {
      push @err_recs, $_;
      $types{$log_type}++;
    }
  }
  close($fh);

  my $total = $#err_recs;
  my @list;

  return (\@list, \%types, $total) if ($total < 0);
  for (my $i = $total - $PG ; $i >= ($total - $PG) - $PAGE_ROWS && $i >= 0 ; $i--) {
    push @list, "$err_recs[$i]";
  }

  $total++;
  return (\@list, \%types, $total);
}

#**********************************************************
# Make unique value
# mk_unique_value($size)
#**********************************************************
sub mk_unique_value {
  my ($passsize, $attr) = @_;
  my $symbols = (defined($attr->{SYMBOLS})) ? $attr->{SYMBOLS} : "qwertyupasdfghjikzxcvbnmQWERTYUPASDFGHJKLZXCVBNM123456789";

  my $value  = '';
  my $random = '';
  my $i      = 0;
  $passsize = 6 if (int($passsize) < 1);

  my $size = length($symbols);
  srand();
  for ($i = 0 ; $i < $passsize ; $i++) {
    $random = int(rand($size));
    $value .= substr($symbols, $random, 1);
  }

  return $value;
}

#**********************************************************
# Convert integer value to ip
# int2ip($i);
#**********************************************************
sub int2ip {
  my $i = shift;
  my (@d);
  $d[0] = int($i / 256 / 256 / 256);
  $d[1] = int(($i - $d[0] * 256 * 256 * 256) / 256 / 256);
  $d[2] = int(($i - $d[0] * 256 * 256 * 256 - $d[1] * 256 * 256) / 256);
  $d[3] = int($i - $d[0] * 256 * 256 * 256 - $d[1] * 256 * 256 - $d[2] * 256);
  return "$d[0].$d[1].$d[2].$d[3]";
}

#**********************************************************
# Convert ip to int
# ip2int($ip);
#**********************************************************
sub ip2int($) {
  my $ip = shift;
  return unpack("N", pack("C4", split(/\./, $ip)));
}

#***********************************************************
# Time to second
# time2sec()
# return $sec;
#***********************************************************
sub time2sec {
  my ($value, $attr) = @_;
  my $sec;

  my ($H, $M, $S) = split(/:/, $value, 3);

  $sec = ($H * 60 * 60) + ($M * 60) + $S;

  return $sec;
}

#***********************************************************
# Second to date
# sec2time()
# return $sec,$minute,$hour,$day
#***********************************************************
sub sec2time {
  my ($value, $attr) = @_;
  my ($a, $b, $c, $d);

  $a = int($value % 60);
  $b = int(($value % 3600) / 60);
  $c = int(($value % (24 * 3600)) / 3600);
  $d = int($value / (24 * 3600));
  if ($attr->{format}) {
    $c = int($value / 3600);
    return sprintf("%.2d:%.2d:%.2d", $c, $b, $a);
  }
  elsif ($attr->{str}) {
    return sprintf("+%d %.2d:%.2d:%.2d", $d, $c, $b, $a);
  }
  else {
    return ($a, $b, $c, $d);
  }
}

#***********************************************************
# Second to date
# sec2date()
# sec2date();
#***********************************************************
sub sec2date {
  my $secnum = shift;
  return "0000-00-00 00:00:00" if ($secnum == 0);

  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($secnum);
  $year += 1900;
  $mon++;
  $sec  = sprintf("%02d", $sec);
  $min  = sprintf("%02d", $min);
  $hour = sprintf("%02d", $hour);
  $mon  = sprintf("%02d", $mon);
  $mday = sprintf("%02d", $mday);

  return "$year-$mon-$mday $hour:$min:$sec";
}

#***********************************************************
# Convert Integer to byte definision
# int2byte($val, $attr)
# $KBYTE_SIZE - SIze of kilobyte (Standart 1024)
#***********************************************************
sub int2byte {
  my ($val, $attr) = @_;

  my $KBYTE_SIZE = 1024;
  $KBYTE_SIZE = int($attr->{KBYTE_SIZE}) if (defined($attr->{KBYTE_SIZE}));
  my $MEGABYTE = $KBYTE_SIZE * $KBYTE_SIZE;
  my $GIGABYTE = $KBYTE_SIZE * $KBYTE_SIZE * $KBYTE_SIZE;
  $val = int($val);

  if ($attr->{DIMENSION}) {
    if ($attr->{DIMENSION} eq 'Mb') {
      $val = sprintf("%.2f MB", $val / $MEGABYTE);
    }
    elsif ($attr->{DIMENSION} eq 'Gb') {
      $val = sprintf("%.2f GB", $val / $GIGABYTE);
    }
    elsif ($attr->{DIMENSION} eq 'Kb') {
      $val = sprintf("%.2f Kb", $val / $KBYTE_SIZE);
    }
    else {
      $val .= " Bt";
    }
  }
  elsif ($val > $GIGABYTE)   { $val = sprintf("%.2f GB", $val / $GIGABYTE); }     # 1024 * 1024 * 1024
  elsif ($val > $MEGABYTE)   { $val = sprintf("%.2f MB", $val / $MEGABYTE); }     # 1024 * 1024
  elsif ($val > $KBYTE_SIZE) { $val = sprintf("%.2f Kb", $val / $KBYTE_SIZE); }
  else                       { $val .= " Bt"; }

  return $val;
}

#***********************************************************
# integet to money in litteral format
# int2ml($array);
#***********************************************************
sub int2ml {
  my ($array, $attr) = @_;
  my $ret = '';

  my @ones  = @{ $attr->{ONES} };
  my @twos  = @{ $attr->{TWOS} };
  my @fifth = @{ $attr->{FIFTH} };

  my @one     = @{ $attr->{ONE} };
  my @onest   = @{ $attr->{ONEST} };
  my @ten     = @{ $attr->{TEN} };
  my @tens    = @{ $attr->{TENS} };
  my @hundred = @{ $attr->{HUNDRED} };

  my $money_unit_names = $attr->{MONEY_UNIT_NAMES};

  $array =~ s/,/\./g;
  $array =~ tr/0-9,.//cd;
  my $tmp = $array;
  my $count = ($tmp =~ tr/.,//);

  if ($count > 1) {
    $ret .= "bad integer format\n";
    return 1;
  }

  my $second = "00";
  my ($first, $i, @first, $j);

  if (!$count) {
    $first = $array;
  }
  else {
    $first = $second = $array;
    $first  =~ s/(.*)(\..*)/$1/;
    $second =~ s/(.*)(\.)(\d\d)(.*)/$3/;
    $second .= "0" if (length $second < 2);
  }

  $count = int((length $first) / 3);
  my $first_length = length $first;

  for ($i = 1 ; $i <= $count ; $i++) {
    $tmp = $first;
    $tmp   =~ s/(.*)(\d\d\d$)/$2/;
    $first =~ s/(.*)(\d\d\d$)/$1/;
    $first[$i] = $tmp;
  }

  if ($count < 4 && $count * 3 < $first_length) {
    $first[$i] = $first;
    $first_length = $i;
  }
  else {
    $first_length = $i - 1;
  }

  for ($i = $first_length ; $i >= 1 ; $i--) {
    $tmp = 0;
    for ($j = length($first[$i]) ; $j >= 1 ; $j--) {
      if ($j == 3) {
        $tmp = $first[$i];
        $tmp =~ s/(^\d)(\d)(\d$)/$1/;
        $ret .= $hundred[$tmp];

        if ($tmp > 0) {
          $ret .= " ";
        }
      }
      if ($j == 2) {
        $tmp = $first[$i];
        $tmp =~ s/(.*)(\d)(\d$)/$2/;
        if ($tmp != 1) {
          $ret .= $ten[$tmp];
          if ($tmp > 0) {
            $ret .= " ";
          }
        }
      }
      if ($j == 1) {
        if ($tmp != 1) {
          $tmp = $first[$i];
          $tmp =~ s/(.*)(\d$)/$2/;
          if ((($i == 1) || ($i == 2)) && ($tmp == 1 || $tmp == 2)) {
            $ret .= $onest[$tmp];
            if ($tmp > 0) {
              $ret .= " ";
            }
          }
          else {
            $ret .= $one[$tmp];
            if ($tmp > 0) {
              $ret .= " ";
            }
          }
        }
        else {
          $tmp = $first[$i];
          $tmp =~ s/(.*)(\d$)/$2/;
          $ret .= $tens[$tmp];
          if ($tmp > 0) {
            $ret .= " ";
          }
          $tmp = 5;
        }
      }

    }

    $ret .= ' ';
    if ($tmp == 1) {
      $ret .= ($ones[ $i - 1 ]) ? $ones[ $i - 1 ] : $money_unit_names->[0];
    }
    elsif ($tmp > 1 && $tmp < 5) {
      $ret .= ($twos[ $i - 1 ]) ? $twos[ $i - 1 ] : $money_unit_names->[0];
    }
    elsif ($tmp > 4) {
      $ret .= ($fifth[ $i - 1 ]) ? $fifth[ $i - 1 ] : $money_unit_names->[0];
    }
    else {
      $ret .= ($fifth[0]) ? $fifth[0] : $money_unit_names->[0];
    }
    $ret .= ' ';
  }

  if ($second ne '') {
    $ret .= " $second  $money_unit_names->[1]";
  }
  else {
    $ret .= "";
  }

  require locale;
  locale->import();
  my $locale = $attr->{LOCALE} || 'ru_RU.CP1251';
  setlocale(LC_ALL, $locale);
  $ret = ucfirst $ret;
  setlocale(LC_NUMERIC, "");

  return $ret;
}

#**********************************************************
# decode_base64()
#**********************************************************
sub decode_base64($) {
  local ($^W) = 0;    # unpack("u",...) gives bogus warning in 5.00[123]
  my $str = shift;
  my $res = "";

  $str =~ tr|A-Za-z0-9+=/||cd;    # remove non-base64 chars
  $str =~ s/=+$//;                # remove padding
  $str =~ tr|A-Za-z0-9+/| -_|;    # convert to uuencoded format
  while ($str =~ /(.{1,60})/gs) {
    my $len = chr(32 + length($1) * 3 / 4);    # compute length byte
    $res .= unpack("u", $len . $1);            # uudecode
  }

  return $res;
}

#**********************************************************
# encode_base64()
#**********************************************************
sub encode_base64 ($;$) {

  if ($] >= 5.006) {
    require bytes;
    if (bytes::length($_[0]) > length($_[0])
      || ($] >= 5.008 && $_[0] =~ /[^\0-\xFF]/))
    {
      require Carp;
      Carp::croak("The Base64 encoding is only defined for bytes");
    }
  }

  require integer;
  integer->import();

  my $eol = $_[1];
  $eol = "\n" unless defined $eol;

  my $res = pack("u", $_[0]);

  # Remove first character of each line, remove newlines
  $res =~ s/^.//mg;
  $res =~ s/\n//g;

  $res =~ tr|` -_|AA-Za-z0-9+/|;    # `# help emacs
                                    # fix padding at the end
  my $padding = (3 - length($_[0]) % 3) % 3;
  $res =~ s/.{$padding}$/'=' x $padding/e if $padding;

  # break encoded string into lines of no more than 76 characters each
  if (length $eol) {
    $res =~ s/(.{1,72})/$1$eol/g;
  }
  return $res;
}

#**********************************************************
# time check function
# check_time()
#**********************************************************
sub check_time {
  my $begin_time = 0;

  #Check the Time::HiRes module (available from CPAN)
  eval { require Time::HiRes; };
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
  }

  return $begin_time;
}


#**********************************************************
# For clearing quotes
# clearquotes( $text, $attr_hash )
#**********************************************************
sub clearquotes {
  my ($text, $attr) = @_;
  if ($text ne '""') {
    my $extra = $attr->{EXTRA} || '';
    $text =~ s/\"$extra//g;
  }
  else {
    $text = '';
  }
  return $text;
}

#**********************************************************
# tpl_parse($string, \%HASH_REF);
#**********************************************************
sub tpl_parse {
  my ($string, $HASH_REF, $attr) = @_;

  while (my ($k, $v) = each %$HASH_REF) {
    if (!defined($v)) {
      $v = '';
    }
    $string =~ s/\%$k\%/$v/g;
    if ($attr->{SET_ENV}) {
      $ENV{$k}=$v;
    }
  }

  return $string;
}

#**********************************************************
# cmd($cmd, \%HASH_REF);
#**********************************************************
sub cmd {
  my ($cmd, $attr) = @_;

  my $debug   = $attr->{debug} || 0;
  my $timeout = defined($attr->{timeout}) ? $attr->{timeout} : 5;
  my $result  = '';

  my $saveerr;
  my $error_output;
  #Close error output
  if (! $attr->{SHOW_RESULT} && ! $debug) {
    open($saveerr, ">&STDERR");
    close(STDERR);
    #Add o scallar error message
    open STDERR, ">", \$error_output or die "Can't make error scalar variable $!?\n";
  }

  if ($debug > 1) {
    $attr->{PARAMS}{DEBUG}=$debug;
  }

  if ($attr->{PARAMS}) {
    $cmd = tpl_parse($cmd, $attr->{PARAMS}, { SET_ENV => $attr->{SET_ENV} });
  }

  if ($attr->{ARGV}) {
    foreach my $key ( sort keys %{ $attr->{PARAMS} } ) {
      next if (in_array($key, [ 'EXT_TABLES', 'SEARCH_FIELDS', 'SEARCH_FIELDS_ARR', 'SEARCH_FIELDS_COUNT', 
        'COL_NAMES_ARR', 'db', 'list', 'dbo', 'TP_INFO', 'TP_INFO_OLD', 'CHANGES_LOG' ]));
      
      $cmd .= " $key=\"$attr->{PARAMS}->{$key}\""; 
    }
  }

  if($debug>2) {
    print $cmd."\n"; 
    if ($debug > 5) {
      return $result;
    }
  }

  eval {
    local $SIG{ALRM} = sub { die "alarm\n" };    # NB: \n required
    
    if ($timeout) {
      alarm $timeout;
    }

    #$result = system($cmd);
    $result = `$cmd`;
    alarm 0;
  };

  if ($@) {
    die unless $@ eq "alarm\n";                  # propagate unexpected errors
    print "timed out\n" if ($debug>2);
  }
  else {
    print "NO errors\n" if ($debug>2);
  }
  
  if ($debug) {
    print $result;
  }

  if ($saveerr) {
    close(STDERR);
    open(STDERR, ">&", $saveerr);
  }

  return $result;
}

#**********************************************************
# get_ssh_value($cmd, \%HASH_REF);
#**********************************************************
sub ssh_cmd {
  my ($cmd, $attr) = @_;

  my @mng_array = split(/:/, $attr->{NAS_MNG_IP_PORT});

  my $nas_host =  $mng_array[0];
  my $nas_port = 22;

  if ($#mng_array < 1) {
    $nas_port=22;
  }
  else {
 	  $nas_port=$mng_array[$#mng_array];
  }

  my $base_dir  = $attr->{BASE_DIR}    || '/usr/abills/';
  my $nas_admin = $attr->{NAS_MNG_USER}|| 'abills_admin';
  my $SSH       = $attr->{SSH_CMD}     || "/usr/bin/ssh -p $nas_port -o StrictHostKeyChecking=no -i $base_dir/Certs/id_dsa." . $nas_admin;

  my @value = ();
  $cmd =~ s/[\r\n]/ /g;
  my $cmds = "$SSH $nas_admin\@$nas_host '$cmd'";
  
  if ($attr->{DEBUG}) {
  	print $cmds;
  }
  
  open(my $CMD, "$cmds |") || die "Can't open '$cmds' $!\n";
    @value = <$CMD>;
  close($CMD);

  return \@value;  
}

#**********************************************************
# days = date_diff(from_date, to_date)
# 
#**********************************************************
sub date_diff {
	my ($from_date, $to_date) = @_;

  my ($from_year, $from_month, $from_day) = split(/-/, $from_date, 3);
  my ($to_year,   $to_month,   $to_day)   = split(/-/, $to_date,   3);
  my $from_seltime = POSIX::mktime(0, 0, 0, $from_day, ($from_month - 1), ($from_year - 1900));
  my $to_seltime   = POSIX::mktime(0, 0, 0, $to_day,   ($to_month - 1),   ($to_year - 1900));

  my $days = int(($to_seltime - $from_seltime) / 86400);	
	
	return $days;
}

#**********************************************************
# convert date to other date format
#**********************************************************
sub date_format {
  my ($date, $format, $attr) = @_; 

  my $year   = 0;
  my $month  = 0;
  my $day    = 0;
  my $hour   = 0;
  my $min    = 0;
  my $sec    = 0;

  if ($date =~ /(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
    $year   = $1;
    $month  = $2;
    $day    = $3;
    $hour   = $4;
    $min    = $5;
    $sec    = $6;
  }

  $date = POSIX::strftime( $format,
                  localtime(POSIX::mktime($sec, $min, $hour, $day, ($month - 1), ($year - 1900)) ) );

  return $date;
}

#**********************************************************
# breake point
#  Args 
#   HEADER    - show header html
#   SHOW      - show input
#   SKIP_EXIT - skip exit on point
#
#**********************************************************
sub _bp {
  my ($attr) = @_;

  if (! $ENV{DEBUG}) {
    #return 1; 
  }

  if ($attr->{HEADER}) {
    print "Content-Type: text/html\n\n";
  }
  
  my $break_line = " <br>\n";

  if ($attr->{SHOW}) {
    print $break_line . "SHOW: ";
    if (ref $attr->{SHOW} eq 'ARRAY') {
      print "(Array_ref)";
      foreach my $key (sort @{ $attr->{SHOW} }) {
        print "$key ".$break_line;
      }
    }
    if (ref $attr->{SHOW} eq 'HASH') {
      print "(Hash_ref)";
      foreach my $key (sort keys %{ $attr->{SHOW} }) {
        print "$key -> $attr->{SHOW}->{$key}". $break_line;
      }
    }
    else {
      print '('. (ref $attr->{SHOW}) .') '. "'$attr->{SHOW}'".$break_line;
    }
    print "<br>\n";
  }

  my ($package, $filename, $line) = caller;
  print "_BP File: $filename Line: $line ($package)\n";
  # warn("foo");


  if ($attr->{EXIT}) {
    exit;
  }

  return 1;
}

#**********************************************************
#
#**********************************************************
sub urlencode {
  my ($s) = @_;

  #$s =~ s/ /+/g;
  #$s =~ s/([^A-Za-z0-9\+-])/sprintf("%%%02X", ord($1))/seg;
  $s =~ s/([^A-Za-z0-9])/sprintf("%%%2.2X", ord($1))/ge;

  return $s;
}

#**********************************************************
#
#**********************************************************
sub urldecode {
  my ($s) = @_;

  $s =~ s/\+/ /g;
  $s =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;

  return $s;
}

#**********************************************************
# Get Argument params or Environment parameters
#
# FreeRadius enviropment parameters
#  CLIENT_IP_ADDRESS - 127.0.0.1
#  NAS_IP_ADDRESS - 127.0.0.1
#  USER_PASSWORD - xxxxxxxxx
#  SERVICE_TYPE - VPN
#  NAS_PORT_TYPE - Virtual
#  FRAMED_PROTOCOL - PPP
#  USER_NAME - andy
#  NAS_IDENTIFIER - media.intranet
#**********************************************************
sub get_radius_params {
  my %RAD = ();

  if ($#ARGV > 1) {
    foreach my $pair (@ARGV) {
      my ($side, $value) = split(/=/, $pair, 2);
      if (defined($value)) {
        $value = clearquotes("$value");
        $RAD{"$side"} = "$value";
      }
      else {
        $RAD{"$side"} = "";
      }
    }
  }
  else {
    while (my ($k, $v) = each(%ENV)) {
      if (defined($v) && defined($k)) {
        if ($RAD{$k}) {
          $RAD{$k} .= ";" . clearquotes("$v");
        }
        else {
          $RAD{$k} = clearquotes("$v");
        }
      }
    }
  }

  return \%RAD;
}


#**********************************************************
=head2 startup_files($attr) - Get deamon startup information and other params of system

Analise file /usr/abills/Abills/programs and return hash_ref of params
  
  Atributes:
    $attr

  Returns:
    hash_ref

=cut
#**********************************************************
sub startup_files {
	my ($attr) = @_;

  my %startup_files = ();

	my $startup_conf = '/usr/abills/Abills/programs';
  my $content = '';
  if(lc($^O) eq 'freebsd') {
    %startup_files = (
      WEB_SERVER_USER    => "www",
      RADIUS_SERVER_USER => "freeradius",
      APACHE_CONF_DIR    => '/usr/local/apache22/Include/',
      RESTART_MYSQL      => '/usr/local/etc/rc.d/mysql-server',
      RESTART_RADIUS     => '/usr/local/etc/rc.d/freeradius',
      RESTART_APACHE     => '/usr/local/etc/rc.d/apache22',
      RESTART_DHCP       => '/usr/local/etc/rc.d/isc-dhcp-server',
    );
  }
  else {
    %startup_files = (
      WEB_SERVER_USER    => "www-data",
      APACHE_CONF_DIR    => '/etc/apache2/sites-enabled/',
      RADIUS_SERVER_USER => "freerad",
      RESTART_MYSQL      => '/etc/init.d/mysqld',
      RESTART_RADIUS     => '/etc/init.d/freeradius',
      RESTART_APACHE     => '/etc/init.d/apache2',
      RESTART_DHCP       => '/etc/init.d/isc-dhcp-server'
    );
  }

  if ( -f $startup_conf ) {
	  if (open(my $fh, "$startup_conf") ) {
		  while( <$fh> ) {
			  $content .= $_;
		  }
	    close($fh);
	  }
	
  	my @rows = split(/[\r\n]+/, $content);
	  foreach my $line (@rows) {
	    my ($key, $val) = split(/=/, $line, 2);
  	  next if (!$key);
	    next if (!$val);
	    $startup_files{$key}=$val;
	  }
  }

  return \%startup_files;
}

=head1 AUTHOR

~AsmodeuS~ (http://abills.net.ua/)

=cut



1;
