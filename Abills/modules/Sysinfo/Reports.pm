#package Sysinfo::Reports;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Sysinfo::Reports -

=cut

use Abills::Base qw(int2byte indexof);

my %sysinfo_hash = ();
my $os           = sysinfo_get_os();

our ($admin, $db, %lang, %conf, $SORT, %permissions);
our Abills::HTML $html;

$conf{SYSINFO_SUDOERS_D} ||= '';

require Sysinfo::Services;

#*******************************************************************
=head2 sysinfo_perl() - Show system perl info

=cut
#*******************************************************************
sub sysinfo_perl {
  #my ($attr) = @_;

  my $perl_version = $^V;
  $perl_version=~s/v//xg;
  $html->message('info', '', "$lang{VERSION} Perl : $perl_version");

  my @require_modules = (
    'DBI',
    'DBD::mysql',
    'Digest::MD5',
    'Digest::MD4',
    'Crypt::DES',
    'Digest::SHA',
    'Time::HiRes',
    'XML::Simple',
    'PDF::API2',
    'RRDTool::OO',
    'JSON',
    'Authen::Captcha',
    'Spreadsheet::WriteExcel',
    'Asterisk::AGI',
    'Perl::GD',
    'Devel::NYTProf',
    'Crypt::OpenSSL::X509',
    'Imager::QRCode',
    'LWP::UserAgent'
  );

  #use ExtUtils::Installed;
  #my ($inst) = ExtUtils::Installed->new();
  my (@modules) = &list_perl_modules();    # $inst->modules();

  if ($FORM{MODULE}) {
    my @mods = ();
    my $mod;

    if ($FORM{'idx'}) {
      @mods = &list_perl_modules();
      $mod  = $mods[ $FORM{'idx'} ];
    }
    else {
      print "---------------- $FORM{MODULE} ------------------";
      @mods = &list_perl_modules($FORM{MODULE});
      $mod  = $mods[0];
    }

    my %INFO = ();
    my $midx = ($FORM{'midx'}) ? $FORM{'midx'} : 0;

    my @m = ();
    if ($mod->{'mods'}){
      @m = @{ $mod->{'mods'} };
    }

    ($INFO{DESCRIBE}, $INFO{VERSION}) = &module_desc($mod, $midx);

    $INFO{NAME}    = $FORM{MODULE};
    $INFO{DATE}    = $mod->{'date'};
    $INFO{FILES}   = $mod->{'files'}->[$midx];
    $INFO{INSTALL} = $mod->{'pkg'} ? $mod->{'pkgtype'} : 'Manual Perl module install';

    if ($mod->{'master'} && $midx == $mod->{'master'} && @m > 1) {
      for (my $i = 0 ; $i < @m ; $i++) {
        if ($i != $mod->{'master'}) {
          $INFO{SUBMODULES} .= $html->button($m[$i], "index=$index&MODULE=$m[$i]&midx=$i&idx=$FORM{'idx'}") . "  ";
        }
      }
    }

    my $perl_doc = _cmd('which perldoc');
    if(! $perl_doc) {
      $perl_doc = '/usr/local/bin/perldoc';
    }

    if ($m[$midx]) {
      if (open(my $DOC, '-|', "$perl_doc -t '$m[$midx]' 2>/dev/null")) {
        while (<$DOC>) {$INFO{DOC} .= $_;}
        close($DOC);
      }
    }

    $INFO{DOC} = $html->link_former($INFO{DOC}, { SKIP_SPACE => 1 });
    $html->tpl_show(_include('sysinfo_pmodule_info', 'Sysinfo'), \%INFO);
    return 1;
  }

  my $table = $html->table({
    width       => '100%',
    title_plain => [ $lang{NAME}, $lang{DESCRIBE}, $lang{VERSION}, $lang{DATE} ],
    caption     => $lang{RECOMMENDED_MODULES},
    ID          => 'RECOMMENDED_MODULES',
  });

  foreach my $name (sort @require_modules ) {
    my @mods = &list_perl_modules($name);
    my $mod  = $mods[0];

    my ($desc, $ver) = &module_desc($mod);
    my $date = ($mod->{'time'}) ? POSIX::strftime('%Y-%m-%d %H-%M-%S', localtime($mod->{'time'})) : '';

    ::load_module($name, { LOAD_PACKAGE => 1 });

    $ver  = 0;
    $ver = $name->VERSION unless ( $@ );

    $table->addrow(
      $html->button($name, "index=$index&MODULE=$name&idx=". ($mod->{'index'} || '')),
      $desc,
      $ver || '-',
      $date,
      $html->button($lang{INFO}, "", { GLOBAL_URL => "http://abills.net.ua/wiki/display/AB/Perl+$name", ex_params => "TARGET=_new", class => 'info' }),
    );
  }

  print $table->show();

  $table = $html->table({
    caption     => $lang{MODULES},
    width       => '100%',
    title_plain => [ $lang{NAME}, "SUBMODULES", $lang{DESCRIBE}, $lang{VERSION}, $lang{DATE} ],
    ID          => 'PERL_MODULES'
  });

  foreach my $module (sort { lc($a->{'mods'}->[ $a->{'master'} ]) cmp lc($b->{'mods'}->[ $b->{'master'} ]) } @modules) {
    my $mi = $module->{'master'} || 0;
    my $name = $module->{'mods'}->[$mi];
    my ($desc, $ver) = &module_desc($module, $mi);
    my $date = POSIX::strftime('%Y-%m-%d %H-%M-%S', localtime($module->{'time'}));

    $table->addrow(
      $html->button($name, "index=$index&MODULE=$name&idx=$module->{'index'}"),
      $#{ $module->{'mods'} },
      $html->link_former($desc, { SKIP_SPACE => 1 }),
      $ver || 0,
      $date
    );
  }

  print $table->show();

  return 1;
}

#*******************************************************************
=head2 sysinfo_os() OS info

=cut
#*******************************************************************
sub sysinfo_os {

  my %INFO_HASH = ();

  my $full_info = sysinfo_get_os({ FULL_INFO => 1 });
  $full_info //= q{};
  #FreeBSD
  if ($full_info =~ m/(\S+)\s+(\S+)\s+(\S+).+\#\d:(.+)\s+(\S+\@\S+)\s+(\S+)/x) {
    $INFO_HASH{OS}       = $1;
    $INFO_HASH{HOST}     = $2;
    $INFO_HASH{VERSION}  = $3;
    $INFO_HASH{DATE}     = $4;
    $INFO_HASH{KERNEL}   = $5;
    $INFO_HASH{PLATFORM} = $6;
  }
  #Linux
  elsif ($full_info =~ m/(\S+)\s+(\S+)\s+(\S+)\s+([0-9a-z#]+)\s(\S+)\s(\S+\s+\S+\s+\d+\s+\d{2}:\d{2}:\d{2}\s+\S+\s+\d{4})\s+(\S+)/ix) {
    $INFO_HASH{OS}       = $1;
    $INFO_HASH{HOST}     = $2;
    $INFO_HASH{KERNEL}   = $3;
    $INFO_HASH{VERSION}  = $4;
    $INFO_HASH{CPU}      = $5;
    $INFO_HASH{DATE}     = $6;
    $INFO_HASH{PLATFORM} = $7;
    $INFO_HASH{SUM_PLATFORM} = $8;
  }
  #Linux Debian
  elsif ($full_info =~ m/(\S+)\s+([a-z\-0-9]+)\s+(\S+)\s+([0-9a-z#]+)\s+(\S+)\s(\S+\s+\S+\s+[0-9\.\-]+)\s+([\(\)0-9\-]+)\s+(\S+)/ix) {
    $INFO_HASH{OS}       = $1;
    $INFO_HASH{HOST}     = $2;
    $INFO_HASH{KERNEL}   = $3;
    $INFO_HASH{VERSION}  = $6;
    $INFO_HASH{CPU}      = $5;
    $INFO_HASH{DATE}     = $7;
    $INFO_HASH{PLATFORM} = $8;
    $INFO_HASH{SUM_PLATFORM} = $8;
  }

  if ($os eq 'FreeBSD') {
    if ($INFO_HASH{KERNEL} && $INFO_HASH{KERNEL} =~ m/\/(\w+)$/x) {
      my $file = $1 || q{};
      $INFO_HASH{KERNEL_FILE} = "/usr/src/sys/i386/conf/" . $file if (-f "/usr/src/sys/i386/conf/" . $file);
    }
  }

  if ($FORM{KERNEL}) {
    my $kern_file = '';
    open(my $fh, '>', "$INFO_HASH{KERNEL_FILE}") || print $html->message('err', $lang{ERROR}, "Can't open '$INFO_HASH{KERNEL_FILE}' $!");
    while (<$fh>) {
      $kern_file .= $_;
    }
    close($fh);

    $kern_file =~ s/\n/<br>\n/xg;

    my $table = $html->table({
        caption => "$INFO_HASH{KERNEL_FILE}",
        width   => '100%'
    });

    my @division = ('device', 'options', 'machine', 'cpu', 'ident');
    foreach my $s (@division) {
      $kern_file =~ s/$s |$s\t/<b>$s<\/b> /xig;
    }
    $kern_file =~ s/ /&nbsp;/xg;
    $kern_file =~ s/#(.+)\n/<font color=#0000FF># $1<\/font>/xg;

    $table->addtd($table->td($kern_file));

    print $table->show();
  }

  my $table = $html->table({
    caption     => "Operation System: $full_info;",
    title_plain => [ $lang{PARAMS}, $lang{VALUE} ],
  });

  $table->addrow('OS',      $INFO_HASH{OS});
  $table->addrow('HOST',    $INFO_HASH{HOST});
  $table->addrow('VERSION', $INFO_HASH{VERSION});
  $table->addrow($lang{DATE},  $INFO_HASH{DATE});
  $table->addrow('KERNEL', ($INFO_HASH{KERNEL_FILE}) ? $html->button($INFO_HASH{KERNEL}, "index=$index&KERNEL=1") : $INFO_HASH{KERNEL});
  $table->addrow('PLATFORM', $INFO_HASH{PLATFORM});
  $table->addrow('CPU',    $INFO_HASH{CPU});

  print $table->show();

  return 1;
}

#*******************************************************************
=head2 sysinfo_get_os($attr) - Show system info

  Arguments:
    $attr
      FULL_INFO

  Results:
    $os_info

=cut
#*******************************************************************
sub sysinfo_get_os {
  my ($attr) = @_;

  my $os_full = '';
  my $os_name = 'UNKNOWN';
  if (-x '/usr/bin/uname') {
    $os_full = _cmd('/usr/bin/uname -a');
  }
  elsif (-x '/bin/uname') {
    $os_full = _cmd('/bin/uname -a');
  }

  if ($attr->{FULL_INFO}) {
    $os_name = $os_full;
  }
  elsif ($os_full =~ m/(\S+)/x) {
    $os_name = $1;
  }

  return $os_name;
}

#*******************************************************************
# Show system info
#*******************************************************************
sub sysinfo_globals {

  #Canonical Hostname localhost
  #Listening IP 217.73.128.3
  #Kernel Version 2.6.20.7
  #Distro Name  CentOS release 4.4 (Final)
  #Uptime 2 days 44 minutes
  #Current Users 0
  #Load Averages
}

#*******************************************************************
# Show system info
#*******************************************************************
sub sysinfo_main {

  #OS version
  sysinfo_os();

  # Memory Usage
  sysinfo_memory();

  # Mounted Filesystems
  sysinfo_disk();

  # Network Usage
  sysinfo_network();

  # Check Running proccess

  # System Vital

  # Hardware Information

}

#**********************************************************
=head2 sysinfo_memory()

=cut
#**********************************************************
sub sysinfo_memory {
  $sysinfo_hash{$os}{'memory'}->();
}

#**********************************************************
=head2 sysinfo_cpu()

=cut
#**********************************************************
sub sysinfo_cpu {
  return $sysinfo_hash{$os}{'cpu'}->();
}

#**********************************************************
=head2 sysinfo_disk()

=cut
#**********************************************************
sub sysinfo_disk {

  my $table = $html->table(
    {
      caption     => "Disk usage",
      width       => '100%',
      title_plain => [ 'Filesystem', 'Size', 'Used', 'Avail', 'Capacity', 'Mounted' ],
    }
  );

  my $info       = $sysinfo_hash{$os}{'disk'}->();
  my $i          = 0;
  my $total_size = 0;
  my $total_used = 0;
  foreach my $line (@{ $info->{Filesystem} }) {
    if ($line =~ m/^\/|total/x) {
      $total_size += $info->{Size}->[$i] || 0;
      $total_used += $info->{Used}->[$i] || 0;

      my $progress = $html->progress_bar({
        TEXT     => $info->{Capacity}->[$i],
        TOTAL    => $total_size,
        COMPLETE => $total_used
      });
      $line = $lang{TOTAL} if($line eq 'total');
      $table->addrow($line,
        int2byte($info->{Size}->[$i]*1024),
        int2byte($info->{Used}->[$i]*1024),
        int2byte($info->{Avail}->[$i]*1024),
        $progress,
        $info->{Mounted}->[$i]
      );
    }
    $i++;
  }
  if($os eq 'FreeBSD') {
    $table->{rowcolor} = 'bg-info';
    my $progress = $html->progress_bar({
      TEXT     => ($total_used / ($total_size || 1)) * 100,
      TOTAL    => $total_size,
      COMPLETE => $total_used
    });

    $table->addrow("$lang{TOTAL}:", int2byte($total_size*1024),
      int2byte($total_used*1024),
      int2byte(($total_size - $total_used)*1024),
      $progress,
      '');
  }

  print $table->show();

  return 1;
}

#*******************************************************************
=head2 sysinfo_network()

=cut
#*******************************************************************
sub sysinfo_network {

  my $table = $html->table({
    caption => $lang{NETWORK},
    width   => '100%',
    title   => [ 'INTERFACE', $lang{STATE}, $lang{ADDRESS}, $lang{RECV}, $lang{SENT}, $lang{ERROR} ],
    ID      => 'NETWORK'
  });

  my $info = $sysinfo_hash{$os}{'network'}->();
  my @states = ('Up', 'Down');

  my $sorted_iface = multi_hash_sort($info, ($SORT || 0) - 1, {
      ACTIVE_FIELDS => [ 'IF_NAME', 'STATE', 'NETWORK', 'IN', 'OUT', 'IN_ERROR', 'OUT_ERROR', 'COLL' ] });

  foreach my $iface (@$sorted_iface) {
    my $v = $info->{$iface};
    $table->addrow($iface,
      $states[ $v->{STATE} ],
      $v->{ADDRESS} . '/' . ($v->{IP} || ''),
      int2byte($v->{IN} || 0),
      int2byte($v->{OUT} || 0),
      ($v->{IN_ERROR} || 0) . '/'. ($v->{OUT_ERROR} || 0)
    );
  }

  print $table->show();

  return 1;
}

#*******************************************************************
=head2 sysinfo_processes()

=cut
#*******************************************************************
sub sysinfo_processes {

  #watch section
  my %watch_proccess = ('httpd'        => '#E8E800:',
    'apache'       => '#E8E800:',
    'mysqld'       => '#B0A36A:',
    'radiusd'      => '#8888FF:',
    'mpd'          => '#FF9866:',
    'flow-capture' => '#CFCFCF:',
    'named'        => '#CFCFCF:',
    'ipcad'        => '#CFCFCF:',
    'accel-ppp'    => '#000080:',
  );

  foreach my $ps_name ( split(/,\s?/x, $conf{SYSINFO_WATCH} || q{}) ) {
    $watch_proccess{$ps_name} = '-';
  }

  my $restart_defined_processes = sysinfo_get_process_pathes();

  #all
  my $table = $html->table({
      caption    => "$lang{PROCESSES}",
      width      => '100%',
      title      => [ 'USER', 'PID', '%CPU', '%MEM', 'VSZ', 'RSS', 'TT', 'STAT', 'STARTED', 'TIME', 'COMMAND', '-' ],
      ID         => 'SYSINFO_PROCESSES'
  });

  my $info = $sysinfo_hash{$os}{'processes'}->();

  my @active_fields = ('USER', 'PID', 'CPU', 'MEM', 'VSZ', 'RSS', 'TT', 'STAT', 'STARTED', 'TIME', 'COMMAND');

  my $sorted = arr_hash_sort($info, ($SORT || 0) - 1, { ACTIVE_FIELDS => \@active_fields });

  foreach my $line (@$sorted) {
    #reset %watch_proccess;
    my $restart_button = '';

    foreach my $proc_name (sort keys %watch_proccess ) {
      if ($line->{COMMAND} =~ m/$proc_name/x) {
        my ($color, undef)=split(':', $watch_proccess{$proc_name});
        $table->{rowcolor}=$color || $_COLORS[0];
        if ($restart_defined_processes->{$proc_name} && ($permissions{4} && $permissions{4}->{8}) && -f $restart_defined_processes->{$proc_name}){
          my $disabled = ($proc_name eq 'apache' && !$conf{SYSINFO_ALLOW_APACHE_RESTART}) ? 'disabled' : '';

          my $restart_index = get_function_index('sysinfo_services');
          $restart_button = $html->button( 'R', "index=$restart_index&SERVICE=$proc_name&RESTART=1&action=1",
            {
              title   => 'restart',
              class   => "btn btn-sm btn-danger $disabled",
              CONFIRM => "$lang{RESTART} $proc_name?"
            }
          );
        }
        #$line->{COMMAND};
        last;
      }
    }

    $table->addrow($line->{USER},
      $line->{PID},
      $line->{CPU},
      $line->{MEM},
      $line->{VSZ},
      $line->{RSS},
      $line->{TT},
      $line->{STAT},
      $line->{STARTED},
      $line->{TIME},
      $line->{COMMAND},
      $restart_button
    );
    delete $table->{rowcolor};
  }
  print $table->show();

  return 1;
}


#**********************************************************
# show proccess
#**********************************************************
$sysinfo_hash{'FreeBSD'}{'processes'} = sub {

  #USER       PID %CPU %MEM   VSZ   RSS  TT  STAT STARTED      TIME COMMAND
  my $total_info = _cmd('env COLUMNS=1000 /bin/ps aux');

  my @arr = split(/\n/x, $total_info);
  my @result_array = ();

  foreach my $line (@arr) {
    $line =~ s/,/\./xg;
    if ($line =~ m/(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)/x) {
      my %info = ();

      # print "$1, $2, $3, $4, $5 <br>";
      $info{USER}    = $1;
      $info{PID}     = $2;

      $info{CPU}     = $3;
      $info{MEM}     = $4;
      $info{VSZ}     = $5;
      $info{RSS}     = $6;

      $info{TT}      = $7;
      $info{STAT}    = $8;
      $info{STARTED} = $9;
      $info{TIME}    = $10;
      $info{COMMAND} = $11;

      push @result_array, \%info;
    }
  }

  return \@result_array;
};

$sysinfo_hash{'FreeBSD'}{'network'} = sub {
  my $total_info = _cmd('/usr/bin/netstat -in');

  my @arr = split(/\n/x, $total_info);
  my %info = ();

  foreach my $line (@arr) {
    if ($line =~ m/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/x) {
      my $iface                = $1;
      $info{$iface}{MTU}       = $2;
      $info{$iface}{NETWORK}   = $3;
      $info{$iface}{ADDRESS}   = $4;
      $info{$iface}{IN}        = $5;
      $info{$iface}{IN_ERROR}  = $6;
      $info{$iface}{OUT}       = $7;
      $info{$iface}{OUT_ERROR} = $8;
      $info{$iface}{COLL}      = $9;
      $info{$iface}{IF_NAME}   = $iface;
      $info{$iface}{STATE}     = ($iface =~ m/\*$/x) ? 1 : 0;
    }
    elsif ($line =~ m/^(\S+)\s+(\S+)\s+(\S+)\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+(\d+)/x) {
      my $iface               = $1;
      $info{$iface}{IP}       = $4;
    }
    elsif ($line =~ m/(tun\d+[*]{0,1})\s+(\d+)\s+<Link#\d+>\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/x) {
      my $iface                 = $1;
      $info{$iface}{MTU}        = $2;
      $info{$iface}{IN}        += $3;
      $info{$iface}{IN_ERROR}  += $4;
      $info{$iface}{OUT}       += $5;
      $info{$iface}{OUT_ERROR} += $6;
      $info{$iface}{COLL}      += $7;
      $info{$iface}{IF_NAME}    = $iface;
      $info{$iface}{STATE}      = ($iface =~ m/\*$/x) ? 1 : 0;
    }
    elsif ($line =~ m/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+-\s+(\d+)\s+-\s+-/x) {
      my $iface             = $1;
      $info{$iface}{MTU}    = $2;
      $info{$iface}{MASK}   = $3;
      $info{$iface}{IP}     = $4;
      $info{$iface}{IP_IN}  = $5;
      $info{$iface}{IP_OUT} = $6;
      $info{$iface}{IF_NAME}= $iface;
      $info{$iface}{STATE}  = ($iface =~ m/\*$/x) ? 1 : 0;
    }
  }

  return \%info;
};

$sysinfo_hash{'FreeBSD'}{'disk'} = sub {
  my $total_info = _cmd('/bin/df ');

  my @arr   = split(/\n/x, $total_info);
  my %info  = ();
  my $block = 1024;

  if ($total_info =~ m/(\d+)-blocks/x) {
    $block = $1;
  }

  foreach my $line (@arr) {
    if ($line =~ m/(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\S+)/x) {
      push @{ $info{Filesystem} }, $1;
      push @{ $info{Size} },       $2 * $block;
      push @{ $info{Used} },       $3 * $block;
      push @{ $info{Avail} },      $4 * $block;
      push @{ $info{Capacity} },   $5;
      push @{ $info{Mounted} },    $6;
    }
  }
  return \%info;
};

#*******************************************************************
=head2 freeebsd_memory

=cut
#*******************************************************************
$sysinfo_hash{'FreeBSD'}{'memory'} = sub {
  my ($attr) = @_;

  my $sysctl        = {};
  my $sysctl_output = _cmd('/sbin/sysctl -a');
  foreach my $line (split(/\n/x, $sysctl_output)) {
    if ($line =~ m/^([^:]+):\s+(.+)\s*$/xs) {
      $sysctl->{$1} = $2;
    }
  }

  #   determine the individual known information
  #   NOTICE: forget hw.usermem, it is just (hw.physmem - vm.stats.vm.v_wire_count).
  #   NOTICE: forget vm.stats.misc.zero_page_count, it is just the subset of
  #           vm.stats.vm.v_free_count which is already pre-zeroed.
  my $mem_hw       = &mem_rounded_freebsd($sysctl->{"hw.physmem"});
  my $mem_phys     = $sysctl->{"hw.physmem"};
  my $mem_all      = $sysctl->{"vm.stats.vm.v_page_count"} * $sysctl->{"hw.pagesize"};
  my $mem_wire     = $sysctl->{"vm.stats.vm.v_wire_count"} * $sysctl->{"hw.pagesize"};
  my $mem_active   = $sysctl->{"vm.stats.vm.v_active_count"} * $sysctl->{"hw.pagesize"};
  my $mem_inactive = $sysctl->{"vm.stats.vm.v_inactive_count"} * $sysctl->{"hw.pagesize"};
  my $mem_cache    = $sysctl->{"vm.stats.vm.v_cache_count"} * $sysctl->{"hw.pagesize"};
  my $mem_free     = $sysctl->{"vm.stats.vm.v_free_count"} * $sysctl->{"hw.pagesize"};

  #   determine the individual unknown information
  my $mem_gap_vm  = $mem_all - ($mem_wire + $mem_active + $mem_inactive + $mem_cache + $mem_free);
  my $mem_gap_sys = $mem_phys - $mem_all;
  my $mem_gap_hw  = $mem_hw - $mem_phys;

  #   determine logical summary information
  my $mem_total = $mem_hw;
  my $mem_avail = $mem_inactive + $mem_cache + $mem_free;
  my $mem_used  = $mem_total - $mem_avail;

  #   information annotations
  my $info = {
    "mem_wire"     => 'Wired: disabled for paging out',
    "mem_active"   => 'Active: recently referenced',
    "mem_inactive" => 'Inactive: recently not referenced',
    "mem_cache"    => 'Cached: almost avail. for allocation',
    "mem_free"     => 'Free: fully available for allocation',
    "mem_gap_vm"   => 'Memory gap: UNKNOWN',
    "mem_all"      => 'Total real memory managed',
    "mem_gap_sys"  => 'Memory gap: Kernel?!',
    "mem_phys"     => 'Total real memory available',
    "mem_gap_hw"   => 'Memory gap: Segment Mappings?!',
    "mem_hw"       => 'Total real memory installed',
    "mem_used"     => 'Logically used memory',
    "mem_avail"    => 'Logically available memory',
    "mem_total"    => 'Logically total memory',
  };

  my $table = $html->table(  {
    caption => "SYSTEM MEMORY INFORMATION",
    width   => '100%',
  });

  if (!$attr->{SHORT}) {
    $table->{rowcolor} = 'bg-info';
    $table->{extra}    = "colspan='5' class='small'";
    $table->addrow("&nbsp;");
    delete $table->{rowcolor};
    delete $table->{extra};

    $table->addrow("mem_wire:",     $mem_wire,     int2byte($mem_wire),     sprintf("%3d%%", ($mem_wire / $mem_all) * 100),     $info->{"mem_wire"});
    $table->addrow("mem_active:",   $mem_active,   int2byte($mem_active),   sprintf("%3d%%", ($mem_active / $mem_all) * 100),   $info->{"mem_active"});
    $table->addrow("mem_inactive:", $mem_inactive, int2byte($mem_inactive), sprintf("%3d%%", ($mem_inactive / $mem_all) * 100), $info->{"mem_inactive"});
    $table->addrow("mem_cache: ",   $mem_cache,    int2byte($mem_cache),    sprintf("%3d%%", ($mem_cache / $mem_all) * 100),    $info->{"mem_cache"});
    $table->addrow("mem_free:  ",   $mem_free,     int2byte($mem_free),     sprintf("%3d%%", ($mem_free / $mem_all) * 100),     $info->{"mem_free"});
    $table->addrow("mem_gap_vm:",   $mem_gap_vm,   int2byte($mem_gap_vm),   sprintf("%3d%%", ($mem_gap_vm / $mem_all) * 100),   $info->{"mem_gap_vm"});

    $table->{rowcolor} = 'bg-info';
    $table->{extra}    = "colspan='5' class='small'";
    $table->addrow("&nbsp;");
    delete $table->{rowcolor};
    delete $table->{extra};
    $table->addrow("mem_all:",     $mem_all,     int2byte($mem_all),     '100%', $info->{"mem_all"});
    $table->addrow("mem_gap_sys:", $mem_gap_sys, int2byte($mem_gap_sys), '',     $info->{"mem_gap_sys"});

    $table->{rowcolor} = 'bg-info';
    $table->{extra}    = "colspan='5' class='small'";
    $table->addrow("&nbsp;");
    delete $table->{rowcolor};
    delete $table->{extra};

    $table->addrow("mem_phys:",   $mem_phys,   int2byte($mem_phys),   '', $info->{"mem_phys"});
    $table->addrow("mem_gap_hw:", $mem_gap_hw, int2byte($mem_gap_hw), '', $info->{"mem_gap_hw"});

    $table->{rowcolor} = 'bg-info';
    $table->{extra}    = "colspan='5' class='small'";
    $table->addrow("&nbsp;");
    delete $table->{rowcolor};
    delete $table->{extra};
    $table->addrow("mem_hw:", $mem_hw, int2byte($mem_hw), '', $info->{"mem_hw"});
  }

  $table->{rowcolor} = 'bg-info';
  $table->{extra}    = "colspan='5' class='small'";
  $table->addrow("SYSTEM MEMORY SUMMARY:");
  delete $table->{rowcolor};
  delete $table->{extra};
  $table->addrow("mem_used:",  $mem_used,  int2byte($mem_used),  sprintf("<img src='../img/gorred.gif' height=10 width=%3d> %3d%%",   ($mem_used / $mem_total) * 100,  ($mem_used / $mem_total) * 100),  $info->{"mem_used"});
  $table->addrow("mem_avail:", $mem_avail, int2byte($mem_avail), sprintf("<img src='../img/gorgreen.gif' height=10 width=%3d> %3d%%", ($mem_avail / $mem_total) * 100, ($mem_avail / $mem_total) * 100), $info->{"mem_avail"});

  $table->{rowcolor} = 'bg-info';
  $table->{extra}    = "colspan='5' class='small'";
  $table->addrow("&nbsp;");
  delete $table->{rowcolor};
  delete $table->{extra};
  $table->addrow("mem_total:", $mem_total, int2byte($mem_total), '100%', $info->{"mem_total"});

  print $table->show();
};

$sysinfo_hash{'FreeBSD'}{'cpu'} = sub {
  my ($attr) = shift;

  my $cpu_output = _cmd('sysctl -a | grep cpu');

  my %cpu = (cpu_count => 0);

  foreach my $line ( split(/\n/x, $cpu_output) ) {
    if ( $line =~ m/^(.+): (.+)\s?$/xs ) {
      my $key = $1;
      my $val = $2;

      $cpu{$key} = $val;

      if ($key =~ m/dev\.cpu\.(\d+)\./x){
        my $core_num = $1 || 0;
        if ($core_num >= $cpu{cpu_count}){
          $cpu{cpu_count} = $core_num;
        }
      }

    }
  }

  $cpu{cpu_count}++;

  if ($attr->{SHORT}) {
    return \%cpu;
  }

  sysinfo_show({
    DATA        => \%cpu,
    TABLE_TITLE => "SYSTEM CPU INFORMATION"
  });
};

#*******************************************************************
# Show system info swap
#*******************************************************************
$sysinfo_hash{'FreeBSD'}{'swap'} = sub {

  my $memmory_output = _cmd(q@ /usr/sbin/swapinfo -k | tail -1 | awk '{ print $2*1024" "$3*1024 } @);

  my %memmory = ();
  ($memmory{swap_total}, $memmory{swap_used}) = split(/\s+/x, $memmory_output);

  return \%memmory;
};

#**********************************************************
=head2 Linux disc usage

=cut
#**********************************************************
$sysinfo_hash{'Linux'}{'disk'} = sub {
  my $total_info = _cmd('/bin/df --total');
  my @arr   = split(/\n/x, $total_info);
  my %info  = ();

  if(! $total_info) {
    return \%info;
  }

  my $block = 1024;
  my %division = (
    'K' => 1024,
    'M' => (1024*1024),
    'G' => (1024*1024*1024),
  );
  if ($total_info =~ m/(\d+)-blocks/x) {
    $block = $1;
  }

  foreach my $line (@arr) {
    if ( $line =~ m/(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\S+)/x && $line !~ m/Available/x ){
      my $file_system_point = $1 || q{};
      my $size  = $2 || 0;
      my $used  = $3 || 0;
      my $avail = $4 || 0;
      my $capacity = $5 || 0;
      my $mount_point = $6 || '';

      if( $size !~ m/\d/x) {
        next;
      }
      if ($size =~ m/(\d+)([A-Z])$/x) {
        $size = $1 * $division{$2};
      }
      if ($used =~ m/(\d+)([A-Z])$/x) {
        $used = $1 * $division{$2};
      }
      if ($avail =~ m/(\d+)([A-Z])$/x) {
        $avail = $1 * $division{$2};
      }

      push @{ $info{Filesystem} }, $file_system_point;
      push @{ $info{Size} },       $size;
      push @{ $info{Used} },       $used;
      push @{ $info{Avail} },      $avail;

      push @{ $info{Capacity} },   $capacity;
      push @{ $info{Mounted} },    $mount_point;
    }
  }

  return \%info;
};

#*******************************************************************
# Show system info swap
#*******************************************************************
$sysinfo_hash{'Linux'}{'swap'} = sub {
  my $memmory_output = _cmd(q* /sbin/swapon -s |/usr/bin/tail -1 |awk '{print \$3" " \$4}' *);

  my %memmory = ();
  ($memmory{swap_total}, $memmory{swap_used}) = split(/\s+/x, $memmory_output);

  return \%memmory;
};

#*******************************************************************
# Show system info
#*******************************************************************
$sysinfo_hash{'Linux'}{'memory'} = sub {
  my ($attr) = @_;

  my $memmory_output = _cmd('cat /proc/meminfo');

  my %memmory = ();
  foreach my $line (split(/\n/x, $memmory_output)) {
    if ($line =~ m/^([^:]+):\s+(.+)\s*$/xs) {
      $memmory{$1} = $2;
    }
  }

  if ($attr->{SHORT}) {
    return \%memmory;
  }

  sysinfo_show({
    DATA        => \%memmory,
    TABLE_TITLE => "SYSTEM MEMORY INFORMATION"
  });

  return \%memmory;
};


$sysinfo_hash{'Linux'}{'cpu'} = sub {
  my ($attr) = @_;

  my $cpu_output=_cmd('cat /proc/cpuinfo');

  my %cpu = (cpu_count => 0);

  foreach my $line (split(/\n/x, $cpu_output)) {
    if ($line =~ m/^([^:]+)\s+:\s+(.+)\s*$/xs) {
      my $key = $1;
      my $val = $2;

      $cpu{$key} = $val;
      if ( $key eq 'processor' ) {
        $cpu{cpu_count}++;
      }
    }
  }

  if ($attr->{SHORT}) {
    return \%cpu;
  }

  sysinfo_show({
    DATA        => \%cpu,
    TABLE_TITLE => "SYSTEM CPU INFORMATION"
  });

  return \%cpu;
};

$sysinfo_hash{'Linux'}{'processes'} = sub {

  #USER       PID %CPU %MEM   VSZ   RSS  TT  STAT STARTED      TIME COMMAND
  my $total_info = _cmd('env COLUMNS=1000 /bin/ps aux');

  my @arr = split(/\n/x, $total_info);
  my @result_array = ();

  foreach my $line (@arr) {

    if ($line =~ m/(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)/x) {
      my %info = ();

      # print "$1, $2, $3, $4, $5 <br>";
      $info{USER} = $1;
      $info{PID}  = $2;

      $info{CPU} = $3;
      $info{MEM} = $4;
      $info{VSZ} = $5;
      $info{RSS} = $6;

      $info{TT}      = $7;
      $info{STAT}    = $8;
      $info{STARTED} = $9;
      $info{TIME}    = $10;
      $info{COMMAND} = $11;

      push @result_array, \%info;
    }

  }

  return \@result_array;
};

#**********************************************************
# Linux network
#**********************************************************
$sysinfo_hash{'Linux'}{'network'} = sub {

  my %info = ();
  if (! -x '/bin/netstat') {
    print "Install netstat";
    return \%info;
  }

  my $total_info = _cmd('/bin/netstat -in');
  my @arr = split(/\n/x, $total_info);

  foreach my $line (@arr) {
    if ($line =~ m/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/x) {
      my $iface                = $1;
      $info{$iface}{MTU}       = $2;
      $info{$iface}{NETWORK}   = '-';
      $info{$iface}{ADDRESS}   = '-';
      $info{$iface}{IN}        = $4;
      $info{$iface}{IN_ERROR}  = $5;
      $info{$iface}{OUT}       = $8;
      $info{$iface}{OUT_ERROR} = $9;
      $info{$iface}{COLL}      = '-';
      $info{$iface}{IF_NAME}   = $iface;
      $info{$iface}{STATE}     = ($iface =~ m/\*$/x) ? 1 : 0;
    }
    elsif ($line =~ m/(tun\d+[*]{0,1})\s+(\d+)\s+<Link#\d+>\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/x) {
      my $iface                 = $1;
      $info{$iface}{MTU}        = $2;
      $info{$iface}{IN}       += $3;
      $info{$iface}{IN_ERROR}  += $4;
      $info{$iface}{OUT}       += $5;
      $info{$iface}{OUT_ERROR} += $6;
      $info{$iface}{COLL}      += $7;
      $info{$iface}{IF_NAME}    = $iface;
      $info{$iface}{STATE}      = ($iface =~ m/\*$/x) ? 1 : 0;
    }
    elsif ($line =~ m/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+-\s+(\d+)\s+-\s+-/x) {
      my $iface              = $1;
      $info{$iface}{MTU}     = $2;
      $info{$iface}{MASK}    = $3;
      $info{$iface}{IP}      = $4;
      $info{$iface}{IP_IN}   = $5;
      $info{$iface}{IP_OUT}  = $6;
      $info{$iface}{IF_NAME} = $iface;
      $info{$iface}{STATE}   = ($iface =~ m/\*$/x) ? 1 : 0;
    }
    else {
      #print "not parsed> $line" if ($debug);
    }
  }

  return \%info;
};

#**********************************************************
#   round the physical memory size to the next power of two which is
#   reasonable for memory cards. We do this by first determining the
#   guessed memory card size under the assumption that usual computer
#   hardware has an average of a maximally eight memory cards installed
#   and those are usually of equal size.
#**********************************************************
sub mem_rounded_freebsd {
  my ($mem_size) = @_;
  my $chip_size  = 1;
  my $chip_guess = ($mem_size / 8) - 1;
  while ($chip_guess != 0) {
    $chip_guess >>= 1;
    $chip_size <<= 1;
  }
  my $mem_round = (int($mem_size / $chip_size) + 1) * $chip_size;
  return $mem_round;
}

#**********************************************************
=head2 sysinfo_show()

  show hash in table format

  Arguments:
    DATA
    TABLE_TITLE

=cut
#**********************************************************
sub sysinfo_show {
  my ($attr) = @_;

  my $table = $html->table({
    ID      => $attr->{TABLE_TITLE} || 'TABLE_ID',
    title   => [ 'key', 'name' ],
    caption => $attr->{TABLE_TITLE},
    width   => '100%',
  });

  foreach my $key ( sort keys %{ $attr->{DATA} }  ) {
    $table->addrow($key, $attr->{DATA}->{$key});
  }

  print $table->show();

  return 1;
}

#**********************************************************
#
#**********************************************************
sub multi_hash_sort {
  my ($hash, $sort, $attr) = @_;

  my $ACTIVE_FIELDS = ($attr->{ACTIVE_FIELDS}) ? $attr->{ACTIVE_FIELDS} : [0];

  my %SORT_HASH = ();

  while (my ($k, $v) = each %$hash ) {
    $SORT_HASH{$k} = $v->{ $ACTIVE_FIELDS->[$sort] };
  }

  my @sorted_ids = sort {
    if($FORM{desc}) {
      length($SORT_HASH{$b}) <=> length($SORT_HASH{$a})
        || $SORT_HASH{$b} cmp $SORT_HASH{$a};
    }
    else {
      length($SORT_HASH{$a}) <=> length($SORT_HASH{$b})
        || $SORT_HASH{$a} cmp $SORT_HASH{$b};
    }
  } keys %SORT_HASH;

  return \@sorted_ids;
}

#**********************************************************
#
#**********************************************************
sub arr_hash_sort {
  my ($array, $sort, $attr) = @_;

  my $ACTIVE_FIELDS = ($attr->{ACTIVE_FIELDS}) ? $attr->{ACTIVE_FIELDS} : [0];

  my %SORT_HASH = ();
  my $i         = 0;

  foreach my $line (@{$array}) {
    $SORT_HASH{$i} = $SORT_HASH{$i} = $line->{ $ACTIVE_FIELDS->[$sort] };
    $i++;
  }

  #print $sorted[0]->{$ACTIVE_FIELDS[$FORM{sort}-1]} ;
  my @sorted_ids =
    sort { length($SORT_HASH{$a}) <=> length($SORT_HASH{$b}) || $SORT_HASH{$a} cmp $SORT_HASH{$b} } keys %SORT_HASH;

  my @sorted = ();
  foreach my $line (@sorted_ids) {
    push @sorted, $array->[$line];
  }

  return \@sorted;
}

#Taken from Webmin
#*************************************************************************
# list_perl_modules([master-name])
# Returns a list of all installed perl modules, by reading .packlist files
#*************************************************************************
sub list_perl_modules {
  my ($limit) = @_;
  my (@rv, %done, %donedir, %donemod);

  my $perl_version = $^V;
  my %Config = (
    'sitelib'  => (-d "/usr/local/lib/perl5/site_perl/$perl_version") ? "/usr/local/lib/perl5/site_perl/$perl_version" : "/usr/local/lib/perl5/site_perl/",
    'sitearch' => (-d "/usr/local/lib/perl5/site_perl/$perl_version/mach") ? "/usr/local/lib/perl5/site_perl/$perl_version/mach" : "/usr/local/lib/perl5/site_perl/"
  );

  if (-d "/usr/lib/x86_64-linux-gnu/perl5/") {
    $perl_version =~ m/(\d+).(\d+)/x;
    $Config{sitelib}="/usr/lib/x86_64-linux-gnu/perl5/$1.$2";
  }

  foreach my $d (
    &expand_usr64($Config{'privlib'}),
    &expand_usr64(
      $Config{'sitelib_stem'} ? $Config{'sitelib_stem'} : $Config{'sitelib'}
    ),
    &expand_usr64(
      $Config{'sitearch_stem'} ? $Config{'sitearch_stem'} : $Config{'sitearch'}
    ),
    &expand_usr64(
      $Config{'vendorlib_stem'} ? $Config{'vendorlib_stem'} : $Config{'vendorlib'}
    ),
    &expand_usr64($Config{'installprivlib'})
  ) {
    #print ">> " . ($d || q{--}) .'<br>';
    next if (!$d || ! -d $d);

    next if ($donedir{$d});

    print "find '$d' -name .packlist -print<br>" if ($FORM{DEBUG});
    open(my $FIND, '-|', "find '$d' -name .packlist -print");
    while (my $f = <$FIND>) {
      chop($f);
      my @st = stat($f);
      next if ($done{ $st[0], $st[1] }++);
      @st  = stat($f);

      my $mod = {
        'date'     => scalar(localtime($st[9])),
        'time'     => $st[9],
        'packfile' => $f,
        'index'    => scalar(@rv)
      };

      $f =~ m/\/(([A-Z][^\/]*\/)*[^\/]+)\/.packlist$/x;
      $mod->{'name'} = $1;
      $mod->{'name'} =~ s/\//::/xg;
      next if ($limit && $mod->{'name'} ne $limit);
      next if ($donemod{ $mod->{'name'} }++);

      # Add the files in the .packlist
      my (%donefile, $l);
      open(my $fh, '<', $f);
      while ($l = <$fh>) {
        chop($l);
        $l =~ s/^\/tmp\/[^\/]+//x;
        $l =~ s/^\/var\/tmp\/[^\/]+//x;
        next if ($donefile{$l}++);
        if ($l =~ m/\/((([A-Z][^\/]*\/)([^\/]+\/)?)?[^\/]+)\.pm$/x) {
          my $mn = $1;
          $mn =~ s/\//::/gx;
          push(@{ $mod->{'mods'} },  $mn);
          push(@{ $mod->{'files'} }, $l);
        }
        elsif ($l =~ m/^([^\/]+)\.pm$/x) {
          # Module name only, with no path! Damn redhat..
          my @rpath = ();
          next if (!$d || ! -d $d);
          if (open(my $FIND2, '-|', "find '$d' -name '$l' -print")) {
            while (<$FIND2>) {
              chop;
              push(@rpath, $_);
            }
            close($FIND2);
          }
          @rpath = sort { length($a) cmp length($b) } @rpath;
          if (@rpath) {
            $rpath[0] =~ m/\/(([A-Z][^\/]*\/)*[^\/]+)\.pm$/x;
            my $mn = $1;
            $mn =~ s/\//::/xg;
            push(@{ $mod->{'mods'} },  $mn);
            push(@{ $mod->{'files'} }, $rpath[0]);
            $mod->{'noremove'}  = 1;
            $mod->{'noupgrade'} = 1;
          }
        }
        push(@{ $mod->{'packlist'} }, $l);
      }
      close($fh);
      my $mi = &indexof($mod->{'name'}, @{ $mod->{'mods'} });
      $mod->{'master'} = $mi < 0 ? 0 : $mi;
      push(@rv, $mod) if (@{ $mod->{'mods'} });
    }
    close($FIND);
  }

  ## Look for RPMs or Debs for Perl modules
  #if (&foreign_check("software") && $config{'incpackages'}) {
  #	&foreign_require("software", "software-lib.pl");
  #	if ($software::config{'package_system'} eq "rpm") {
  #		local $n = &software::list_packages();
  #		local $i;
  #		for($i=0; $i<$n; $i++) {
  #			# Create the module object
  #			next if ($software::packages{$i,'name'} !~
  #				 /^perl-([A-Z].*)$/ &&
  #				 $software::packages{$i,'name'} !~
  #				 /^([A-Z].*)-[pP]erl$/i);
  #			local $mod = { 'index' => scalar(@rv),
  #				       'pkg' => $software::packages{$i,'name'},
  #				       'pkgtype' => 'rpm',
  #				       'noupgrade' => 1,
  #				       'version' =>
  #					  $software::packages{$i,'version'} };
  #			$mod->{'name'} = $1;
  #			$mod->{'name'} =~ s/\-/::/g;
  #			next if ($limit && $mod->{'name'} ne $limit);
  #			next if ($donemod{$mod->{'name'}}++);
  #
  #			# Add the files in the RPM
  #			local $fn = &software::check_files(
  #				$software::packages{$i,'name'},
  #				$software::packages{$i,'version'});
  #			local $fi;
  #			for($fi=0; $fi<$fn; $fi++) {
  #				local $l = $software::files{$fi,'path'};
  #				if ($l =~ /\/((([A-Z][^\/]*\/)([^\/]+\/)?)?[^\/]+)\.pm$/) {
  #					local $mn = $1;
  #					$mn =~ s/\//::/g;
  #					push(@{$mod->{'mods'}}, $mn);
  #					push(@{$mod->{'files'}}, $l);
  #					}
  #				push(@{$mod->{'packlist'}}, $l);
  #				if (!$mod->{'date'}) {
  #					local @st = stat($l);
  #					$mod->{'date'} = scalar(localtime($st[9]));
  #					$mod->{'time'} = $st[9];
  #					}
  #				}
  #
  #			local $mi = &indexof($mod->{'name'}, @{$mod->{'mods'}});
  #			$mod->{'master'} = $mi < 0 ? 0 : $mi;
  #			push(@rv, $mod) if (@{$mod->{'mods'}});
  #			}
  #		}
  #	elsif ($software::config{'package_system'} eq "debian") {
  #		# Look for Debian packages of Perl modules
  #		local $n = &software::list_packages();
  #		local $i;
  #		for($i=0; $i<$n; $i++) {
  #			# Create the module object
  #			next if ($software::packages{$i,'name'} !~
  #				 /^lib(\S+)-perl$/);
  #			local $mod = { 'index' => scalar(@rv),
  #				       'pkg' => $software::packages{$i,'name'},
  #				       'pkgtype' => 'debian',
  #				       'noupgrade' => 1,
  #				       'version' =>
  #					  $software::packages{$i,'version'} };
  #
  #			# Add the files in the RPM
  #			local $fn = &software::check_files(
  #				$software::packages{$i,'name'},
  #				$software::packages{$i,'version'});
  #			local $fi;
  #			for($fi=0; $fi<$fn; $fi++) {
  #				local $l = $software::files{$fi,'path'};
  #				if ($l =~ /\/((([A-Z][^\/]*\/)([^\/]+\/)?)?[^\/]+)\.pm$/) {
  #					local $mn = $1;
  #					$mn =~ s/\//::/g;
  #					push(@{$mod->{'mods'}}, $mn);
  #					push(@{$mod->{'files'}}, $l);
  #					}
  #				push(@{$mod->{'packlist'}}, $l);
  #				if (!$mod->{'date'}) {
  #					local @st = stat($l);
  #					$mod->{'date'} = scalar(localtime($st[9]));
  #					$mod->{'time'} = $st[9];
  #					}
  #				}
  #			next if (!@{$mod->{'mods'}});
  #
  #			# Work out the name
  #			foreach my $m (@{$mod->{'mods'}}) {
  #				local $pn = lc($m);
  #				$pn =~ s/::/-/g;
  #				$pn = "lib".$pn."-perl";
  #				if ($pn eq $mod->{'pkg'}) {
  #					$mod->{'name'} = $m;
  #					last;
  #					}
  #				}
  #			$mod->{'name'} ||= $mod->{'mods'}->[0];
  #			next if ($limit && $mod->{'name'} ne $limit);
  #			next if ($donemod{$mod->{'name'}}++);
  #
  #			local $mi = &indexof($mod->{'name'}, @{$mod->{'mods'}});
  #			$mod->{'master'} = $mi < 0 ? 0 : $mi;
  #			push(@rv, $mod) if (@{$mod->{'mods'}});
  #			}
  #
  #		}
  #	}

  return @rv;
}

#***************************************************************
=head2 expand_usr64()

   expand_usr64(dir)
   If a directory is like /usr/lib and /usr/lib64 exists, return them both

=cut
#***************************************************************
sub expand_usr64 {
  my $main_dir = shift;

  if ($main_dir && $main_dir =~ m/^(\/usr\/lib\/|\/usr\/local\/lib\/)(.*)$/x) {
    my ($dir, $dir64, $rest) = ($1, $1, $2);
    $dir64 =~ s/\/lib\//\/lib64\//x;
    return (-d $dir64) ? ($dir . $rest, $dir64 . $rest) : ($dir . $rest);
  }
  else {
    return ($main_dir);
  }
}

#***************************************************************
=head2  module_desc(&mod, index)

  Returns a one-line description for some module, and a version number

=cut
#***************************************************************
sub module_desc {
  my ($in_name, $desc);

  my $f   = (defined($_[1])) ? $_[0]->{'files'}->[ $_[1] ] : '';
  my $pf  = $f;
  my $ver = $_[0]->{'version'};

  $pf =~ s/\.pm$/\.pod/x if ($pf);

  my ($got_version, $got_name);

  my $MOD;
  if ( ($pf && open($MOD, '<', $pf)) || ($f && open($MOD, '<', $f))) {
    while (<$MOD>) {
      if (m/^=head1\s+name/xi && !$got_name) {
        $in_name = 1;
      }
      elsif (m/^=/x && $in_name) {
        $got_name++;
        $in_name = 0;
      }
      elsif ($in_name) {
        $desc .= $_;
      }
      if (m/^\s*(our\s+)?\$VERSION\s*=\s*"([0-9\.]+)"/x
        || m/^\s*(our\s+)?\$VERSION\s*=\s*'([0-9\.]+)'/x
        || m/^\s*(our\s+)?\$VERSION\s*=\s*([0-9\.]+)/x) {
        $ver = $2;
        $got_version++;
      }
      last if ($got_version && $got_name);
    }
    close($MOD);
  }

  my $name;

  if (defined($_[1])) {
    $name = $_[0]->{'mods'}->[ $_[1] ];
  }
  else {
    $name = '';
  }

  if ($desc) {
    $desc =~ s/^\s*$name\s+\-\s+//x
      || $desc =~ s/^\s*\S*<$name>\s+\-\s+//x;
  }

  return wantarray ? ($desc, $ver) : $desc;
}

#***************************************************************
=head2 download_packages_file(&callback)

=cut
#***************************************************************
#sub download_packages_file {
#  $config{'packages'} =~ /^http:\/\/([^\/]+)(\/.*)$/
#  || &error($text{'download_epackages'});
#  local ($host, $page, $port) = ($1, $2, 80);
#  if ($host =~ /^(.*):(\d+)$/) { $host = $1; $port = $2; }
#  #&http_download($host, $port, $page, $packages_file, undef, $_[0]);
#}

#**********************************************************
=head2 sysinfo_sp_info()

=cut
#**********************************************************
sub sysinfo_sp_info {

  my ($cpu, $ram, $hdd, $load, $load_2, $load_3)=(0, 0, '', 0, 0, 0);

  if ($os eq 'FreeBSD') {
    my $sysctl_output = _cmd('/sbin/sysctl -a');

    my %sysctl = ();
    foreach my $line (split(/\n/x, $sysctl_output)) {
      if ($line =~ m/^([^:]+):\s+(.+)\s*$/xs) {
        $sysctl{$1} = $2;
      }
    }

    $cpu = $sysctl{'kern.smp.cpus'} || 0;

    my $mem_phys     = $sysctl{"hw.physmem"};
    my $mem_free     = $sysctl{"vm.stats.vm.v_free_count"} * $sysctl{"hw.pagesize"};

    $ram = $html->progress_bar({
      TOP_TEXT     => int2byte($mem_phys) ." $lang{FREE}: ". int2byte($mem_free),
      TOTAL    => $mem_phys,
      COMPLETE => $mem_phys - $mem_free
    });
  }
  else {
    my $cpu_info = $sysinfo_hash{$os}{'cpu'}->({ SHORT => 1 });
    $cpu = $cpu_info->{cpu_count};

    my $memmory_output = _cmd('cat /proc/meminfo');

    my %memmory = ();
    foreach my $line (split(/\n/x, $memmory_output)) {
      if ($line =~ m/^([^:]+):\s+(.+)\s*$/xs) {
        $memmory{$1} = $2;
      }
    }
    if ($memmory{MemTotal}){
      $memmory{MemTotal} =~ m/(\d+)/x;
      $memmory{MemTotal} = $1 || 0;
    }
    else {
      $memmory{MemTotal} = 0;
    }

    if ($memmory{MemFree}){
      $memmory{MemFree} =~ m/(\d+)/x;
      $memmory{MemFree} = $1 || 0;
    }
    else {
      $memmory{MemFree}=0;
    }

    $ram = $html->progress_bar({
      TOTAL    => $memmory{MemTotal},
      COMPLETE => $memmory{MemTotal} - $memmory{MemFree},
      TOP_TEXT => int2byte(($memmory{MemTotal} || 0) * 1024) ." $lang{FREE}: ". int2byte(($memmory{MemFree} || 0) * 1024)
    });
  }

  my $swap_info = $sysinfo_hash{$os}{'swap'}->({ SHORT => 1 });
  $swap_info->{swap_total} //= 0;
  $swap_info->{swap_used}  //= 0;
  my $swap = $html->progress_bar({
    TOTAL    => $swap_info->{swap_total},
    COMPLETE => $swap_info->{swap_used},
    TOP_TEXT => int2byte($swap_info->{swap_total} * 1024) ." $lang{FREE}: ". int2byte(($swap_info->{swap_total} - $swap_info->{swap_used}) * 1024)
  });

  my $info       = $sysinfo_hash{$os}{'disk'}->({ SHORT => 1 });
  my $i          = 0;

  my @user_defined_mount_points = ();
  if (defined $conf{SYSINFO_MOUNT_POINTS} && $conf{SYSINFO_MOUNT_POINTS} ne ''){
    @user_defined_mount_points = split('/,\s+', $conf{SYSINFO_MOUNT_POINTS});
  }

  foreach my $line (@{ $info->{Filesystem} }) {
    if ($line =~ m/^\//x) {
      if (in_array($info->{Mounted}->[$i], ['/', '/var', '/usr', @user_defined_mount_points ] )) {
        $hdd .= $html->progress_bar({
          TOTAL    => $info->{Size}->[$i],
          COMPLETE => $info->{Used}->[$i],
          TOP_TEXT => "$info->{Mounted}->[$i]:  " . int2byte(($info->{Size}->[$i] || 0) * 1024) . " $lang{USED}: " . int2byte(($info->{Used}->[$i] || 0) * 1024),
        });
      }
    }
    $i++;
  }

  my $uptime_out = _cmd('uptime');

  my $rex = qr{load \s+ averages? :
    \s+
    (\d{1,3} [\.,]? \d{2})
    , \s+
    (\d{1,3} [\.,]? \d{2})
    , \s+
    (\d{1,3} [\.,]? \d{2})
  }x;

  if ($uptime_out =~ m/$rex/x) {
    $load   = $1;
    $load_2 = $2;
    $load_2 = ($load_2 * 100) . ' %';
    $load_3 = $3;
    $load_3 = ($load_3 * 100) . ' %';
    $load   =~ s/\,/\./xg;
    $load   = ($load / $cpu * 100) . ' %';
  }

  my $uptime = '';
  if ($uptime_out =~ m/up\s+(.+),\s+\d+\s+u/x) {
    $uptime = $1;
    $uptime =~ s/days/$lang{DAYS}/xg;
  }

  ($load) = $load =~ m/([\d]+\.?[\d]?)/x;

  $load = $html->progress_bar({
    TOP_TEXT => sprintf('%.2f%%', $load), #/$load_2/$load_3",
    TOTAL    => 100,
    COMPLETE => $load
  });

  my $table = $html->table({
    width      => '100%',
    caption    => $html->button($lang{SYSTEM_INFO}, "index=".get_function_index('sysinfo_main')),
    ID         => 'SYSTEM_INFO',
    rows       => [
      [ $lang{CPU},    $cpu    ],
      [ $lang{MEMORY}, $ram    ],
      [ 'SWAP',        $swap   ],
      [ $lang{DISC},   $hdd    ],
      [ $lang{LOAD},   $load   ],
      [ $lang{UPTIME}, $uptime ],
    ]
  });

  my $reports = $table->show();

  return $reports;
}

#**********************************************************
=head2 sysinfo_get_process_pathes()

=cut
#**********************************************************
sub sysinfo_get_process_pathes {

  my %services_init_scripts = ();

  my $services_cmd = sysinfo_get_defined_restart_programs({SERVICE_NAME_CMD_HASH => 1});

  $services_init_scripts{apache} = $conf{SYSINFO_APACHE_NAME} || $services_cmd->{apache2} || $services_cmd->{apache} || $services_cmd->{apache24} || $services_cmd->{httpd} || '';
  $services_init_scripts{radiusd} = $conf{SYSINFO_FREERADIUS_NAME} || $services_cmd->{radiusd} || $services_cmd->{freeradius} || '';
  $services_init_scripts{mysqld} = $conf{SYSINFO_MYSQL_NAME} || $services_cmd->{mysql} || $services_cmd->{'mysql-server'} || $services_cmd->{mysqd} || '';
  $services_init_scripts{'flow-capture'} = $conf{SYSINFO_FLOW_CAPTURE_NAME} || '';
  $services_init_scripts{named} = $conf{SYSINFO_NAMED_NAME} || '';
  $services_init_scripts{ipcad} = $conf{SYSINFO_IPCAD_NAME} || '';
  $services_init_scripts{'accel-ppp'} = $conf{SYSINFO_ACCEL_PPP_NAME} || '';
  $services_init_scripts{mpd} = $conf{SYSINFO_MPD_NAME} || '';

  foreach my $service_defined (keys %$services_cmd, split(/,\s?/x, $conf{SYSINFO_WATCH} || '')){
    $services_init_scripts{$service_defined} = $services_cmd->{$service_defined} if $services_cmd->{$service_defined};
  }

  return \%services_init_scripts;
}

#**********************************************************
=head2 sysinfo_sp_ps()

=cut
#**********************************************************
sub sysinfo_sp_ps {
  my %watch_proccess = (
    'mysqld'       => '-',
    'radiusd'      => '-',
    'flow-capture' => '-',
    'named'        => '-',
    'ipcad'        => '-',
  );

  if ( $os eq 'Linux' ) {
    $watch_proccess{'apache'} = '-';
    $watch_proccess{'accel-ppp'} = '-';
  }
  else {
    $watch_proccess{'httpd'} = '-';
    if ( -f '/usr/local/etc/rc.d/mpd5' ) {
      $watch_proccess{mpd} = '';
    }
  }

  if ( $conf{SYSINFO_WATCH} ) {
    %watch_proccess = ();
    foreach my $ps_name ( split(/,\s?/x, $conf{SYSINFO_WATCH}) ) {
      $watch_proccess{$ps_name} = '-';
    }
  }

  my $info = $sysinfo_hash{$os}->{'processes'}->( { SHORT => 1 } );

  foreach my $line ( @{$info} ) {
    foreach my $proc_name ( keys %watch_proccess ) {
      if ( $line->{COMMAND} =~ m/$proc_name/x ) {
        my $ps_count = 1;
        if ( $watch_proccess{$proc_name} ) {
          $watch_proccess{$proc_name} =~ s/,/\./xg;
          my (undef, $cpu, $mem, $vsz, $count) = split(/:/x, $watch_proccess{$proc_name});
          $line->{CPU} += $cpu if ($cpu);
          $line->{MEM} += $mem if ($mem);
          $line->{VSZ} += $vsz if ($vsz);
          $ps_count = ($count || 0) + 1;
        }

        $watch_proccess{$proc_name} = "+:$line->{CPU}:$line->{MEM}:$line->{VSZ}:$ps_count";
        last;
      }
    }
  }

  my %services_init_scripts = ();

  my $admin_has_restart_permission = $permissions{4} && $permissions{4}->{8};
  if ( $admin_has_restart_permission ) {
    %services_init_scripts = %{ sysinfo_get_process_pathes() };
  }

  my $table = $html->table({
    width       => '100%',
    title_plain => [ $lang{COMMAND}, '', 'CPU %', 'MEM %', 'MEM Mb', '-' ],
    caption     => $html->button( "$lang{PROCCESS_LIST}", 'index=' . get_function_index('sysinfo_processes') ),
    ID          => 'PROCCESS_LIST',
    EXTRA_BTN   =>  $html->button('', 'index=' . get_function_index('sysinfo_processes'),
      {
        ADD_ICON => 'fa fa-fw fa-info',
        class    => 'btn btn-tool ',
        TITLE    => $lang{INFO}
      }
    ),
  });

  my $restart_index = get_function_index('sysinfo_services');
  foreach my $ps_name ( keys %watch_proccess ) {
    $watch_proccess{$ps_name} =~ s/,/\./xg;
    my ($status, $cpu, $mem, $vsz, $count) = split(/:/x, $watch_proccess{$ps_name});
    if ( ($cpu && $cpu > 40) || ($mem && $mem > 40) ) {
      $table->{rowcolor} = 'danger';
    }
    elsif ( ( $cpu && $cpu > 20) || ($mem && $mem > 20) ) {
      $table->{rowcolor} = 'warning';
    }
    else {
      $table->{rowcolor} = undef;
    }

    my @extra_btns = ();
    if ( $admin_has_restart_permission && $services_init_scripts{$ps_name} && -f $services_init_scripts{$ps_name} ) {

      my $disabled = ($ps_name =~ m/apache|httpd/x && !$conf{SYSINFO_ALLOW_APACHE_RESTART}) ? 'disabled' : '';
      my $restart_btn = $html->button( 'R', "index=$restart_index&SERVICE=$ps_name&RESTART=1&action=1",
        {
          title   => 'restart',
          class   => "btn btn-xs btn-danger $disabled",
          CONFIRM => "$lang{RESTART} $ps_name?"
        }
      );

      push @extra_btns, $restart_btn;

    }
    else {
      push @extra_btns, '';
    }

    $ps_name = ($ps_name =~ m/mysql/x)
      ? $html->button( $ps_name,"index=" . get_function_index('sqlcmd_procs') )
      : $ps_name;

    if ( $count && $count > 1 ) {
      $ps_name .= "($count)";
    }

    $table->addrow( $ps_name,
      $status,
      sprintf("%.2f", $cpu || 0),
      sprintf("%.2f", $mem || 0),
      sprintf("%.2f", ($vsz) ? $vsz / 1024 : 0),
      @extra_btns
    );
  }

  my $reports = $table->show();

  return $reports;
}

#***************************************************************
=head2 sysinfo_start_page($attr)

=cut
#***************************************************************
sub sysinfo_start_page {

  my %START_PAGE_F = (
    'sysinfo_sp_info' => "$lang{SYSTEM_INFO}",
    'sysinfo_sp_ps' => "$lang{PROCCESS_LIST}",
  );

  return \%START_PAGE_F;
}

#**********************************************************
=head2 sysinfo_services()

=cut
#**********************************************************
sub sysinfo_services {

  # Get list of services
  my $service_pathes = sysinfo_get_process_pathes();

  if ( $FORM{action} ) {
    my $service_name = $FORM{SERVICE};
    return 0 unless ($service_name);

    my $service_path = $service_pathes->{$service_name};

    if (!$service_path){
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} : $FORM{SERVICE}");
      return 0;
    }
    elsif ( !($permissions{4} && $permissions{4}->{8}) ) {
      $html->message( 'err', $lang{ERROR}, $lang{ERR_ACCESS_DENY} );
      return 0;
    }

    if ( $FORM{RESTART} ) {
      # Do restart
      my $restart_was_successful = _sysinfo_restart_service($service_path);
      if ( $restart_was_successful eq '1' ) {
        $html->message( 'info', $lang{SUCCESS}, "$lang{RESTART} $service_name" );
      }
      else {
        if ($restart_was_successful eq '0'){
          sysinfo_show_permissions_grant_tip($service_path);
        }
      }

    }
    elsif ( $FORM{STOP} ) {
      $html->message( 'err', $lang{ERROR}, 'Not implemented' );
    }
    elsif ( $FORM{START} ) {
      $html->message( 'err', $lang{ERROR}, 'Not implemented' );
    }
    else {
      $html->message( 'err', $lang{ERROR}, 'Unknown service' );
    }

  }

  my @services = sort keys %{ $service_pathes };

  my $table = $html->table( {
    width      => '100%',
    caption    => $lang{PROCESSES},
    title      => [ '#', $lang{NAME}, $lang{PATH}, $lang{RESTART} ],
    ID         => 'PROCESSES',
    pages      => scalar @services,
      qs         => $pages_qs,
      ID         => 'SYSINFO_ID',
      MENU       => "$lang{ADD}:index=" . get_function_index('form_prog_pathes') . ':add',
  } );

  my $i = 1;
  foreach my $service ( @services ) {
    next unless $service;

    next unless (-f $service_pathes->{$service});

    my $disabled = ($service =~ m/apache/x && !$conf{SYSINFO_ALLOW_APACHE_RESTART}) ? 'disabled' : '';
    my $restart_btn = $html->button( 'R', "index=$index&SERVICE=$service&RESTART=1&action=1",
      {
        title   => 'restart',
        class   => "btn btn-sm btn-danger $disabled",
        CONFIRM => "$lang{RESTART} $service?"
      }
    );

    $table->addrow( $i++, $service, $service_pathes->{$service}, $restart_btn );
  }
  print $table->show();

  return 1;
}


#**********************************************************
=head2 cmd($cmd)

  Arguments:
    $cmd

  Results:
    $result;

=cut
#**********************************************************
sub _cmd {
  my $cmd = shift;

  my $result = `$cmd`;

  return $result;
}

1;
