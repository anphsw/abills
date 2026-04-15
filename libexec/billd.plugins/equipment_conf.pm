=head1 NAME

 billd plugin

 DESCRIBE: Equipment config grabber via "expect"

 EXECUTE: /usr/abills/libexec/billd equipment_conf

=cut

use strict;
use warnings;
use Equipment;
use File::Copy qw/copy/;
use Abills::Base qw(int2byte);

our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db,
  $base_dir
);

equipment_conf_expect($argv);

#**********************************************************
=head2 equipment_check($attr)

  Arguments:

  Results:
    TRUE or FALSE


=cut
#**********************************************************
sub equipment_conf_expect {
  my($attr)=@_;

  my $Equipment = Equipment->new($db, $Admin, \%conf);

  if (!$conf{EQUIPMENT_CONF_BACKUP}) {
    print "Error. It is not specified \$conf{EQUIPMENT_CONF_BACKUP} \n";
    return 0;
  }

  my $expect = ($attr->{EXPECT}) ? $attr->{EXPECT} : cmd('which expect');
  chop($expect);
  if (! -x $expect) {
    print "expect not found\n";
    return 0;
  }

  system("chmod +x $conf{EQUIPMENT_CONF_BACKUP}");

  my $expect_dir = $base_dir . 'Abills/modules/Equipment/expect';
  opendir(my $dir, $expect_dir);
    my @expect_files = grep {/\.backup$/x} readdir($dir);
  closedir $dir;

  my $equipment_list = $Equipment->list({
    NAS_IP            => '_SHOW',
    NAS_NAME          => '_SHOW',
    NAS_MNG_USER      => '_SHOW',
    NAS_MNG_PASSWORD  => '_SHOW',
    NAS_MNG_HOST_PORT => '_SHOW',
    MODEL_NAME        => '_SHOW',
    VENDOR_NAME       => '_SHOW',
    PAGE_ROWS         => 10000,
    NAS_ID            => $attr->{NAS_ID}
  });

  foreach my $nas (@$equipment_list) {
    next if (!$nas->{model_name});
    $nas->{model_name} = lc($nas->{model_name});
    $nas->{model_name} =~ s/\s+//xg;
    $nas->{model_name} =~ s/olt//xg;
    $nas->{vendor_name} = lc($nas->{vendor_name});

    my $nas_mng_ip = $nas->{nas_ip} || '';
    my $nas_mng_login = $nas->{nas_mng_user} || 'admin';
    my $nas_mng_password = $nas->{nas_mng_password} || 'public';
    my $nas_mng_ip_port = '';
    my $cmd = '';
    my $file_backup = '';

    if ($nas->{nas_mng_ip_port} && $nas->{nas_mng_ip_port} =~ /:(\d+):/xm) {
      $nas_mng_ip_port = $1;
    }

    foreach my $backup_script (@expect_files) {
      # if($debug > 2 ) {
      #   print "  $backup_script\n";
      # }

      if("$nas->{model_name}.backup" eq $backup_script) {
        $file_backup = "$nas->{model_name}.backup";
        last;
      }
      elsif("$nas->{vendor_name}.backup" eq $backup_script) {
        $file_backup = "$nas->{vendor_name}.backup";
        last;
      }
    }

    if ($file_backup) {
      my $filepath_expect = $base_dir . "Abills/modules/Equipment/expect/$file_backup";
      system("chmod +x $filepath_expect");

      $cmd = "$expect $filepath_expect $nas_mng_ip $nas_mng_login $nas_mng_password $nas_mng_ip_port";

      if($debug > 3) {
        print $cmd."\n";
      }

      my $conf;
      open(my $fh, '-|', $cmd) || die "Can't open file $cmd $!\n";
      while (<$fh>) {
        $conf .= $_;
      }
      close($fh);

      if($debug > 5) {
        print $conf;
      }

      my $filepath_save = $conf{EQUIPMENT_CONF_BACKUP} . $nas->{nas_id} . '.conf';
      my $filepath_save_0 = $filepath_save . '.0';

      if (-e $filepath_save_0) {
        copy($filepath_save_0, $filepath_save . '.1');
      }
      if (-e $filepath_save) {
        copy($filepath_save, $filepath_save . '.0');
      }

      open(my $fh_, '>', $filepath_save) or die "Can't open file $filepath_save: $!";
        print $fh_ $conf;
      close($fh_);

      if($debug > 0) {
        my $size = (stat($filepath_save))[7];
        $size = int2byte($size);
        _log('LOG_NOTICE', "NAS_ID: $nas->{nas_id} BACKUP: $filepath_save $size");
      }
    }
  }

  return 1;
}

1;