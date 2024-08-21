=head1 NAME

 billd plugin

 DESCRIBE: Equipment config grabber via "expect"

 EXECUTE: /usr/abills/libexec/billd equipment_conf_expect

=cut

use strict;
use warnings;
use Equipment;
use File::Copy qw/copy/;

our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db,
  $base_dir
);

my $Equipment = Equipment->new($db, $Admin, \%conf);

equipment_conf_expect();

#**********************************************************
=head2 equipment_check($attr)

  Arguments:

=cut
#**********************************************************
sub equipment_conf_expect {

  if(!$conf{EQUIPMENT_CONF_BACKUP}){
    print "Error. It is not specified \$conf{EQUIPMENT_CONF_BACKUP} \n";
    return 1;
  }

  system("chmod +x $conf{EQUIPMENT_CONF_BACKUP}");
  
  my $expect_dir = $base_dir.'Abills/modules/Equipment/expect';
  opendir(my $dir, $expect_dir);
  my @expect_files = grep(/\.backup$/, readdir($dir));
  closedir $dir;

  my $equipment_list = $Equipment->_list({
    NAS_IP           => '_SHOW',
    NAS_NAME         => '_SHOW',
    NAS_MNG_USER     => '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    NAS_MNG_HOST_PORT=> '_SHOW',
    MODEL_NAME       => '_SHOW',
    COLS_NAME        => 1,
    PAGE_ROWS        => 10000,
  });

  foreach my $nas (@$equipment_list) {
    next if (!$nas->{model_name});
    $nas->{model_name} = lc($nas->{model_name});
    $nas->{model_name} =~ s/ //g;
    $nas->{model_name} =~ s/olt//g;
    

    my $nas_mng_ip = $nas->{nas_ip} || '';
    my $nas_mng_login = $nas->{nas_mng_user} || 'admin';
    my $nas_mng_password = $nas->{nas_mng_password} || 'public';
    my $nas_mng_ip_port = '';
    my $cmd = '';
    my $file_backup = '';

    if ($nas->{nas_mng_ip_port} && $nas->{nas_mng_ip_port} =~ /:(\d+):/) {
      $nas_mng_ip_port = $1;
    }

    if ( in_array( "$nas->{model_name}.backup", \@expect_files ) ){
      $file_backup = "$nas->{model_name}.backup";
    }

    if ($file_backup ){
      my $filepath_expect = $base_dir."Abills/modules/Equipment/expect/$file_backup";
      system("chmod +x $filepath_expect");

      $cmd = "perl $filepath_expect $nas_mng_ip $nas_mng_login $nas_mng_password $nas_mng_ip_port";

      my $conf;
      open(my $fh, '-|', $cmd) || die "Can't open file $cmd $!\n";
      while(<$fh>) {
        $conf .= $_;
      }
      close($fh);

      my $filepath_save = $conf{EQUIPMENT_CONF_BACKUP}.$nas->{nas_id}.'.conf';

      if (-e $filepath_save.'.0') {
        copy($filepath_save.'.0', $filepath_save.'.1');
      }
      if (-e $filepath_save) {
        copy($filepath_save, $filepath_save.'.0');
      }

      open(my $fh_, '>', $filepath_save) or die "Can't open file $filepath_save: $!";
      print $fh_ $conf;
      close($fh_);
    }
  }

  return;
}
    
1;