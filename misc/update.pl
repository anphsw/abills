#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use v5.16;

use Getopt::Long qw/:config auto_version auto_help/;
use Pod::Usage qw(pod2usage);

use Term::Complete qw/Complete/;
use POSIX qw/strftime/;

=head1 NAME

  ABillS Update script

=head1 SYNOPSIS

  update.pl - script for updating ABillS
  
  Arguments:
     -D, --debug - numeric(1..7), level of verbosity
     --branch    - string, git branch to use for update
     --clean     - reload full git repository
     --prefix    - ($base_dir),  where your ABillS directory lives
     --tempdir   - place where script store temprorary sources
     --source    - which system to use while update cvs(untested) or git(default)
     --git-repo  - username@host, where abills.git repository is located

=head1 PURPOSES

  + Check perl version
  + Check perl modules
  + Update sources for current installation (git)
    + backup current sources
    + check free space
    + TODO: update commercial modules
  
  - Update DB scheme prior to current version
  - Update license for commercial users

=cut

our $VERSION = 0.03;

my $PREFIX = '/usr/abills';
my $TEMP_DIR = '/tmp';
my $GIT_BRANCH = 'master';
my $SOURCE = 'git';
my $DEBUG = 0;
my $GIT_REPO_HOST = 'git@abills.net.ua';

my %OPTIONS = (
  sql_check_skip => '',
  clean          => '',
);

GetOptions(
  'debug|D=i'                     => \$DEBUG,
  'branch=s'                      => \$GIT_BRANCH,
  'clean'                         => \$OPTIONS{clean},
  'prefix=s'                      => \$PREFIX,
  'tempdir=s'                     => \$TEMP_DIR,
  'source=s'                      => \$SOURCE,
  'git-repo=s'                    => \$GIT_REPO_HOST,
  
  'skip_check_sql|skip-check-sql' => $OPTIONS{sql_check_skip}
);

if ( !-d $PREFIX && !-d "$PREFIX/lib" ) {
  die " --prefix should point to abills sources dir\n";
}

# Load ABillS Libraries
unshift (@INC, $PREFIX . '/lib');
unshift (@INC, $PREFIX . '/Abills/mysql');
unshift (@INC, $PREFIX . '/');

our (%conf, @MODULES, $base_dir);
require "libexec/config.pl";

require Abills::Base;
Abills::Base->import(qw/_bp/);
_bp('', '', { SET_ARGS => { TO_CONSOLE => 1 } });

require Admins;
require Abills::SQL;
# Connect to DB
my $db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'},
  { CHARSET => $conf{dbcharset} }
);
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID} || 2, { IP => '127.0.0.1' });

my %ENABLED_MODULES = map {$_ => 1} @MODULES;

my $date = strftime("%Y%m%d", localtime());
my $backup_dir = $PREFIX . "_$date";

my $recommended_perl_version = '5.018000';
my $minimal_perl_version = '5.018000';
my $recommended_sql_version = '5.7.6';

my @abills_var_directories = (
  '/var',
  '/var/log',
  '/var/q',
  '/var/log/ipn',
);

my $ABILLS_VERSION = get_abills_version();

check_perl_version($recommended_perl_version);
check_used_perl_modules();

my $SYS_ID = get_sys_id();

if ( $OPTIONS{sql_check_skip} || !check_sql_version() ) {
  print "  If you want to skip MySQL version check, use --skip-check-sql \n";
  exit 1;
};

if ( sources_backup() && sources_update($SOURCE) ) {
  
  sql_update();
  
  update_modules();
  
  print "Success \n";
};

exit 0;

#**********************************************************
=head2 registration()

=cut
#**********************************************************
sub registration {
  
  #  my @identities = ();
  #
  #  # Check for SSH key present
  #  my $system_wide_identity_file_str =
  #    `cat '/etc/ssh/ssh_config' | grep -E '^\ +IdentityFile' | awk -F' ' '{ print \$2 }'`;
  #
  #  my $user_idenity_file_str = '';
  #  if ( -f '/root/.ssh/config' ){
  #    $user_idenity_file_str =
  #      `cat '/root/.ssh/config' | grep -E '^\ +IdentityFile' | awk -F' ' '{ print \$2 }'`;
  #    print "User identities : \n" . $user_idenity_file_str if ($DEBUG);
  #  }
  #
  ##  push(@identities, split('\n', $system_wide_identity_file_str)) if $system_wide_identity_file_str;
  #  push(@identities, split('\n', $user_idenity_file_str)) if $user_idenity_file_str;
  #
  #
  
  # Check each identity for connection to git@abills.net.ua
  my $ssh = `which ssh`;
  chomp($ssh);
  my $has_access_with_identity = sub {
    my $key = shift;
    my $args = join(' ', $ssh, ($key ? "-i $key" : ""), '-o BatchMode=yes', '-q', $GIT_REPO_HOST, '> /dev/null 2>&1');
    print "Checking SSH access with : $args \n" if ( $DEBUG );
    system($args) == 0;
  };
  
  # Prepare signature for downloading
  my $sys_id = get_sys_id();
  
  
  if ( !$has_access_with_identity->() ) {
    print "Don't have access to repo \n";
    return 0;
    
    # TODO: Look for key and save it to /root/.ssh/config
    # TODO: Ask for credentials and save it to $PREFIX/.credentials
    
    #    Host abills.net.ua
    #      User git
    #      Hostname abills.net.ua
    #      IdentityFile ~/.ssh/id_dsa.anton
    
  }
  
  return 1;
  
}

#**********************************************************
=head2 sources_update()

  Arguments :
    $type - 'git', 'free', 'snapshot'

=cut
#**********************************************************
sub sources_update {
  my ($type) = @_;
  
  if ( $type eq 'git' && registration() ) {
    
    # Check git is present
    my $git = `which git`;
    chomp($git);
    if ( !$git ) {
      print "Git is not installed. Please install git \n";
      exit 1;
    }
    
    my $git_cmd = '';
    my @git_options = ();
    my @command_options = ();
    
    my $temprorary_abills_git_sources_dir = "$TEMP_DIR/abills";
    if ( -d  $temprorary_abills_git_sources_dir ) {
      $git_cmd .= 'pull';
      push (@git_options, "-C $temprorary_abills_git_sources_dir");
      if ( $GIT_BRANCH ) {
        push (@command_options, "origin $GIT_BRANCH");
      }
    }
    else {
      $git_cmd .= "clone";
      push (@git_options, "-C $TEMP_DIR");
      if ( $GIT_BRANCH ) {
        push (@command_options, "-b $GIT_BRANCH --single-branch");
        push (@command_options, 'git@abills.net.ua:abills.git');
      }
    }

    my $cmd = "$git " . join(' ', @git_options, $git_cmd, @command_options);
    
    print "Git update: $cmd \n" if ( $DEBUG );
    
    my $update_error = system($cmd);
    if ( $update_error ) {
      print "
      #################################################################
      #                    Git update error                           #
      #################################################################
      
        Check git errors below.\n";
      
      return 0;
    }
    
  }
  
  # Copy new sources to $PREFIX
  my $work_copy = $TEMP_DIR . '/abills_rel';
  
  if ( -e $work_copy && $OPTIONS{clean} ) {
    unlink $work_copy;
  }
  if ( !-e $work_copy ) {
    mkdir $work_copy;
  }
  
  print "Copying working directory to $work_copy \n";
  my $copy_and_prepare_success = system("cp -Rf $TEMP_DIR/abills/* ${work_copy}/") == 0;
  $copy_and_prepare_success ||= system("find ${work_copy} | grep CVS | xargs rm -Rf") == 0;
  $copy_and_prepare_success ||= system("find ${work_copy} | grep .git | xargs rm -Rf") == 0;
  
  if ( !$copy_and_prepare_success ) {
    print "  Error while copying work directory \n";
    return 0;
  }
  
  for my $dir ( @abills_var_directories ) {
    mkdir "$work_copy$dir" if ( !-d "$work_copy$dir" );
    system("chown -R nobody $work_copy$dir");
  }
  
  return 1;
}

#**********************************************************
=head2 sources_backup()

=cut
#**********************************************************
sub sources_backup {
  
  if ( -e $backup_dir && -d $backup_dir ) {
    print "Skipping sources backup. Already have today backup \n";
    return 1;
  }
  
  my $sources_size_kb = get_directory_size($base_dir);
  
  # -P (POSIX) -l (local filesystems) -B k (size in Kilobytes)
  my $df_reply_kb = `df -P -l -B k $base_dir | tail -1 | awk -F' ' '{ print \$4 }'`;
  chomp $df_reply_kb;
  
  if ( !($sources_size_kb && $df_reply_kb) || ($sources_size_kb !~ /^\d+$/ && $df_reply_kb !~ /^\d+$/) ) {
    if ( Term::Complete::Complete->("Can't check free space. Continue anyway? [y/N]") !~ /y/i ) {
      exit 0;
    }
  }
  
  if ( $df_reply_kb && $df_reply_kb =~ /^(\d+)/ ) {
    $df_reply_kb = $1 || 0;
  };
  
  my $free_space_kb = $df_reply_kb - $sources_size_kb;
  
  my $free_space_mb_formatted = sprintf("%.2f", $free_space_kb / 1024);
  my $abills_size_mb_formatted = sprintf("%.2f", $sources_size_kb / 1024);
  print "Free space available : $free_space_mb_formatted Mb ( $abills_size_mb_formatted Mb needed ) \n";
  
  if ( $free_space_kb - ($sources_size_kb * 2) < 0 ) {
    print "Not enough free space to make copy of current abills sources directory.\n";
    # TODO: ask delete old backups
    exit 1;
  }
  
  print "Copying $PREFIX sources to $backup_dir.\n";
  print "Size: ($abills_size_mb_formatted Mb). This can take a while. \n\n";
  
#  return 1;
    return system("cp -Rfp $PREFIX $backup_dir") == 0;
}

#**********************************************************
=head2 get_directory_size() returns size in Kb

=cut
#**********************************************************
sub get_directory_size {
  my ($dir) = @_;
  
  my $size = `du -s -BK $dir | awk -F' ' '{print \$1}'`;
  chomp $size;
  
  if ( $size && $size =~ /^(\d+)/ ) {
    $size = $1;
  }
  else {
    return 0;
  }
  
  return $size ? int($size) : 0;
}

#**********************************************************
=head2 sql_update()

=cut
#**********************************************************
sub sql_update {
  print " sql_update not implemented \n";
}

#**********************************************************
=head2 restart_servers()

=cut
#**********************************************************
sub restart_servers {
  
}

#**********************************************************
=head2 get_license()

=cut
#**********************************************************
sub get_license {
  print " get_license implemented \n";
}

#**********************************************************
=head2 calculate_sys_id()

=cut
#**********************************************************
sub calculate_sys_id {
  print " calculate_sys_id() not implemented \n";
  exit 1;
}

#**********************************************************
=head2 get_sys_id()

=cut
#**********************************************************
sub get_sys_id {
  if (!$SYS_ID){
    $admin->query2("SELECT value FROM config WHERE param='SYS_ID';", undef, { COLS_NAME => 1 });
    if ($admin->{errno}){
      print "Fatal rror while getting SYS_ID. " . ($admin->{errstr} || '');
    }
    my $list = $admin->{list};
    if ($list && ref $list eq 'ARRAY'){
      if (scalar(@$list)) {
        $SYS_ID = $list->[0]->{value};
      }
      else {
        $SYS_ID = calculate_sys_id();
        $admin->query2(q{INSERT INTO config(`param`, `value`) VALUES ('SYS_ID', ?)}, undef, { Bind => [ $SYS_ID ] });
      }
    };
  }
  
  return $SYS_ID;
}

#**********************************************************
=head2 update_modules()

=cut
#**********************************************************
sub update_modules {
  my @modules_to_check = qw(Paysys Ashield Turbo Maps Storage Ureports Cablecat);
  
  my $find_version_in = sub {
    my ($file_name) = shift;
    
  };
  
  for my $module ( @modules_to_check ) {
    next if ( !exists $ENABLED_MODULES{$module} );
    
    my $file_inside_abills_path = '/Abills/mysql/' . ucfirst($module) . '.pm';
    # Get version from current file
    my $current_version = $find_version_in->($PREFIX . $file_inside_abills_path);
    
    # Get version from new version
    my $old_version = $find_version_in->($backup_dir . $file_inside_abills_path);
    
    # Next if the same
    next if (!$current_version || $current_version eq $old_version);
    
    # Make backup of old copy
    `cp $PREFIX$file_inside_abills_path $PREFIX$file_inside_abills_path\_$current_version`;
    
    # Download
    my $downloaded_module = download_module($module);
    
    # Check
    
  };
  
  return 1;
}

#**********************************************************
=head2 download_module() - using Sharing

=cut
#**********************************************************
sub download_module {

}

#**********************************************************
=head2 get_abills_version()

=cut
#**********************************************************
sub get_abills_version {
  # Read from VERSION
  
  if ( -f "$PREFIX/VERSION" ) {
    $ABILLS_VERSION = `cat $PREFIX/VERSION | awk -F' ' '{ print \$1 }'`;
    chomp $ABILLS_VERSION;
  }
  
  if ( $DEBUG ) {
    print "Current version : $ABILLS_VERSION \n";
  }
  
  return $ABILLS_VERSION;
}

#**********************************************************
=head2 read_input($name, $prompt, $default_value, $attr) - read input from user

  $name           - name for variable (unique through program)
  $prompt         - string to show user before he writes value
  $default_value  - default value (will be shown to user), pass undef to prevent empty value
  $attr           - hash_ref
    CHECK         - coderef to check value. if returns false, will ask again
    COMPLETE_LIST - list for autocomplete

=cut
#**********************************************************
sub read_input {
  my ($name, $prompt, $default_value, $attr) = @_;
  
  if ( defined $default_value ) {
    $prompt .= " [$default_value]";
  };
  
  $prompt .= " : ";
  
  READ:
  my $input = $OPTIONS{$name} || Term::Complete::Complete->($prompt, @{ $attr->{COMPLETE_LIST} || [] });
  
  if ( !$input && !defined $default_value ) {
    goto READ;
  }
  
  if ( defined $attr->{CHECK} && !$attr->{CHECK}->($input) ) {
    delete $OPTIONS{$name};
    goto READ;
  }
  
  $OPTIONS{$name} = $input;
  
  return $input;
}

#**********************************************************
=head2 check_used_perl_modules()

  Reads list of modules needed for normal using ABillS

=cut
#**********************************************************
sub check_used_perl_modules {
  
  my $cpanm = `which cpanm`;
  chomp($cpanm);
  
  if ( !$cpanm ) {
    print "cpanminus is not installed \n";
    `cpan App::cpanminus`;
  }
  
  if ( $DEBUG > 2 ) {
    print "Checking for perl modules \n";
  }
  
  # Read file and form two-level array for $Module and Perl::Module
  my $cant_require_module = sub {
    my ($name) = shift;
    undef $@;
    $name =~ s/::/\//g;
    eval {require $name . '.pm'};
    $@;
  };
  
  my %perl_modules_for_Module = (
    'System'  => [
      'JSON',
      'Try::Tiny',
      'DBD::mysql',
      'DBI',
      'Digest::MD5',
      'Digest::SHA1',
      'Imager::QRCode',
      'Spreadsheet::WriteExcel',
      'XML::Simple',
      'Text::CSV'
    ],
    'Netlist' => [ 'Nmap::Parser' ]
  );
  
  foreach my $module ( 'System', keys %ENABLED_MODULES ) {
    if ( exists $perl_modules_for_Module{$module} ) {
      
      foreach my $perl_mod ( @{$perl_modules_for_Module{$module}} ) {
        if ( $DEBUG > 2 ) {
          print "  Checking for module $perl_mod \n";
        }
        
        if ( $cant_require_module->($perl_mod) ) {
          print "  Installing Perl module : $perl_mod \n";
          sleep 1;
          `cpanm $perl_mod`
        }
      }
    }
    
  }
  
  if ( $DEBUG ) {
    print "Finished checking perl modules \n";
  }
  
}

#**********************************************************
=head2 check_perl_version()

=cut
#**********************************************************
sub check_perl_version {
  my ($recommended_version) = shift;
  
  my $normalize = sub {
    my $literal = shift;
    my ($major, $minor, $subv) = $literal =~ /^(\d+)\.(\d{3})(\d*)/;
    
    $minor = int($minor || 0);
    $subv = int($subv || 0);
    
    "v$major.$minor.$subv";
  };
  
  if ( $DEBUG ) {
    print "Checking perl version. Current: $] Recommended: $recommended_version\n";
  }
  
  my $normalized_recommended = $normalize->($recommended_version);
  my $normalized_minimal = $normalize->($minimal_perl_version);
  my $normalized_current = $normalize->($]);
  
  if ( $] lt $minimal_perl_version ) {
    die "Your PERL version ($normalized_current) is lower then minimal $normalized_minimal. \n"
  }
  elsif ( $] lt $recommended_version ) {
    print "
  #################################################################
  #                    Outdated perl version                      #
  #################################################################
  
  Your PERL version ($normalized_current) is lower then recommended.
  Perl community works hard to make Perl faster and more stable.
  We as developers are using new stable features, so code needs higher versions of Perl
  Consider upgrading Perl at least to $normalized_recommended\n
  
  ";
  }
  
}

#**********************************************************
=head2 check_sql_version()

=cut
#**********************************************************
sub check_sql_version {
  print "Checking MySQL Server version \n" if ( $DEBUG );
  
  # Get version
  my $version_str = `mysql --version | awk -F' ' '{ print \$5 }'`;
  chomp $version_str;
  
  my $split_and_compare = sub {
    my ($ver_1, $ver_2) = @_;
    
    my @vers1 = split('\.', $ver_1);
    my @vers2 = split('\.', $ver_2);
    
    my $lower_length = ($#vers1 < $#vers2) ? $#vers1 : $#vers2;
    
    my $res = 1;
    for ( my $i = 0; $i <= $lower_length; $i++ ) {
      last if ( $vers1[$i] >= $vers2[$i] );
      if ( $vers1[$i] < $vers2[$i] ) {
        $res = 0;
      }
    }
    
    $res;
  };
  
  my $sql_version = 0;
  if ( $version_str && $version_str =~ /([0-9.]+)-?/ ) {
    $sql_version = $1;
  }
  
  print "  Current MySQL Server version : $sql_version \n" if ( $DEBUG > 2 );
  
  # Compare with recommended and show warning if less
  if ( $split_and_compare->($recommended_sql_version, $sql_version) ) {
    print "
  #################################################################
  #                    Outdated MySQL version                     #
  #################################################################
  
  Your MySQL version ($sql_version) is lower then recommended.
  Consider upgrading MySQL at least to $recommended_sql_version\n\n";
    return 0;
  }
  
  return 1;
}