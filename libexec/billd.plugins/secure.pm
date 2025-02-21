=head1 NAME


=help

  SHOW_HOSTNAME=1
  ACCESS_LIST=1

=VERSION
  Secure

  VERSION: 2
  DATETIME: 20230208

=cut

use strict;
use warnings FATAL => 'all';
use Socket qw(inet_pton inet_aton AF_INET6 AF_INET);

our (
  %conf,
  $base_dir,
  $lib_path,
  $DATE,
  $argv
);


if ($argv->{ACCESS_LIST}) {
  access_list($argv);
}
else {
  secure_log($argv);
}

#**********************************************************
=head2 secure_log($attr)

=cut
#**********************************************************
sub secure_log {

  my $apache_log = $argv->{APACHE_LOGS} || $conf{APACHE_LOGS} || '/var/log/httpd/abills-access_log';

  if (!$conf{APACHE_LOGS}) {
    print "Error. Please add logs paths with ';' to \$conf{APACHE_LOGS} in config.pl \n";
    return 0;
  }

  my $search_parameters = '';
  if (open(my $params, '<', $lib_path.'secure.txt')) {
    while (my $line = <$params>) {
      $search_parameters .= $line;
    };
    close($params);
  }
  my @search_parameters = split(/\n/, $search_parameters);

  if (!@search_parameters) {
    print "Error. Please add search parameters to libexec/secure.txt \n";
    return 0;
  }

  $apache_log =~ s/ //g;
  my @logfiles = split(/;\s?/, $apache_log);

  my $content = '';

  foreach my $logfile (@logfiles) {
    foreach my $parameter (@search_parameters) {
      if (open(my $fh, '-|', "grep -i $parameter $logfile")) {
        while (my $line = <$fh>) {
          my $change = "\033[1m$parameter\033[0m";
          $line =~ s/$parameter/$change/g;
          $content .= $line;
        };
        close($fh);
      }
    }
  }

  print $content;

  if ($content){
    open(my $fh_close, '>>', '/var/log/apache2/secure.log') or die $!;
    print $fh_close $content . "\n";
    close($fh_close);
  }

  return 1;
}

#**********************************************************
=head access_list()

  Arguments:
    $attr

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub access_list {
  my ($attr)=@_;

  my $apache_log = $argv->{APACHE_LOGS} || $conf{APACHE_LOGS} || '/var/log/httpd/abills-access_log';
  my %ip_list = ();
  my %ip_aids_list = ();

  open( my $fh, '<', $apache_log) || die "Can't open '$apache_log' $!\n";
    while(<$fh>) {
      if (/\s+\/admin/) {
        my ($ip, undef, undef, $date, $gmt, $request,
          $url, $proto, $respos_code) = split(/ /, $_);
        $ip_list{$ip}++;

        if (/AID=(\d+)/) {
          my $aid = $1;
          if (! in_array($aid, $ip_aids_list{$ip})) {
            push @{$ip_aids_list{$ip}}, $aid;
          }
        }
      }
    }
  close($fh);

  foreach my $ip (sort { $ip_list{$b} <=> $ip_list{$a} } keys %ip_list) {
    my $hostname = q{};
    if ($attr->{SHOW_HOSTNAME} && $ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
      $hostname = gethostbyaddr(inet_aton($ip), AF_INET) || q{};
      if ($hostname) {
        $hostname = ' (' . ( $hostname || q{} ) . ')';
      }
      else {
        $hostname = `whois $ip | grep -i netname`;
        if ($hostname) {
          $hostname =~ s/\n//g;
          $hostname = ' (' . ( $hostname || q{} ) . ')';
        }
      }
    }

    print "$ip$hostname: $ip_list{$ip}\n";
    if ($ip_aids_list{$ip}) {
      print '  '. join(",", sort @{ $ip_aids_list{$ip} }) ."\n";
    }
  }

  return 1;
}

1
