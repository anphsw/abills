=head1
  Name: equipment ping

=cut

use Abills::Filters;
#do 'Abills/Misc.pm';
use Equipment;
use Abills::HTML;
use Net::Ping;
our $Admin;
our $db;
our %conf;

$html = Abills::HTML->new(
       {
         CONF     => \%conf,
         NO_PRINT => 0,
         PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
         CHARSET  => $conf{default_charset},
         csv      => 1
       }
    );
my $Equipment = Equipment->new($db, $Admin, \%conf);

equipment_ping();

#**********************************************************
=head2 equipment_ping($attr)

  Arguments:
    
    
  Returns:
  
=cut
#**********************************************************
sub equipment_ping {
  my ($attr) = @_;
  my $timeout = $attr->{TOUT} || '2';
  $p = Net::Ping->new()  or die "Can't create new ping object: $!\n";

  my $equipment_list = $Equipment->_list({COLS_NAME => 1,
                                          PAGE_ROWS => 100000,
                                          NAS_IP    => '_SHOW',
                                          STATUS    => '0;1',
                                          NAS_NAME  => '_SHOW'
                                          });
  
  foreach my $equip (@$equipment_list){
    next if(! $equip->{nas_ip});
    my $ping_result = '0';
    $ping_result = '1' if $p->ping($equip->{nas_ip}, $timeout);

    if($debug> 2) {
      print "$equip->{nas_ip}: $ping_result\n";
    }

    if($ping_result == 1){
      if($equip->{status} != 0){
        $Equipment->_change({NAS_ID => $equip->{nas_id}, STATUS => 0});
      }
    }
    else {
      if($equip->{status} == 0){
        $Equipment->_change({NAS_ID => $equip->{nas_id}, STATUS => 1});
      }
    }

    if($conf{EQUIPMENT_PING_DEBUG}){
      open(my $file, '>>', '/tmp/buffer');
      $ping_result == 1
      ? print $file "+Destination Host Reachable:\nDate\t\t- $DATE $TIME\nNAS name\t- $equip->{nas_name}\nNAS IP\t\t- $equip->{nas_ip}\n\n\n" 
      : print $file "-Destination Host Unreachable:\nDate\t\t- $DATE $TIME\nNAS name\t- $equip->{nas_name}\nNAS IP\t\t- $equip->{nas_ip}\n\n\n";
      close $file;
    }
  }
  $p->close;

  return 1;
}