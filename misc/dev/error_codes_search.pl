#!/usr/bin/perl

=head1 NAME

  error_codes_search.pl

=head1 SYNOPSIS

  Error keys search

  Dev Tool for:
  1) Errors search
  2) Upload to confluence

=head1 OPTIONS

    PATH       - errors search path
      default: /usr/abills/
    LIST       - show errors output
    UPLOAD     - upload errors to confluence
    DEBUG      - show debug info

=cut

use strict;
use warnings FATAL => 'all';

BEGIN {
  use FindBin '$Bin';
  our $libpath = $Bin . '/../../';

  require $libpath . 'libexec/config.pl';

  unshift(@INC,
    $libpath . '/lib/',
    $libpath . 'Abills/mysql',
    $libpath
  );
}

use JSON;
use File::Find;
use Encode qw/decode_utf8/;

use Abills::Base qw/parse_arguments encode_base64/;
use Abills::Fetcher qw/web_request/;
use Conf;

our %ERRORS_LANG_KEYS = ();
our %ERRORS_BASE_LIST = ();

our @KEYS_REGEXPS = (
  qr/\$Errors->throw_error\(\s*(\d+)(?=\s*[,\)])/m,
);

# .tpl - parse special _{(.+?)}_ variables
# .sql - parse standard statuses
our @ALLOWED_EXTENSIONS = ('pm', 'pl', 'cgi');

our %lang = ();
our %conf;
our $Conf;
require Abills::Misc;

my $args = parse_arguments(\@ARGV);
my $dirs = $args->{PATH} // '/usr/abills';

load_lang();
start();

#**********************************************************
=head2 start()

=cut
#**********************************************************
sub start {
  for my $dir (split /\;/, $dirs) {
    # Collect lang keys
    my @DIRS = ($dir,);
    my $options = { wanted => \&file_search };
    find($options, @DIRS);
  }

  if ($args->{UPLOAD}) {
    error_keys_search();

    my $output = format_error_keys(\%ERRORS_BASE_LIST, \%ERRORS_LANG_KEYS);
    _upload_to_confluence($output);
  }
  elsif ($args->{LIST}) {
    error_keys_search();

    my $output = format_error_keys(\%ERRORS_BASE_LIST, \%ERRORS_LANG_KEYS);
    my $json = _get_configured_json();
    print $json->encode($output);
  }
  else {
    help();
  }
}

#**********************************************************
=head2 file_search($is_module)

  Arguments:
    $is_module

=cut
#**********************************************************
sub file_search {
  my $name = $File::Find::name;
  my $dir = $File::Find::dir;

  return if $name eq $dir;

  if (my ($module) = $name =~ /\/([^\/]+)\/Errors.pm$/) {
    return file_process($name, $module);
  }
  elsif ($dir =~ /\/Errors\/?$/) {
    return file_process($name, '-');
  }
}

#**********************************************************
=head2 file_process($file_path, $module)

  Arguments:
    $file_path
    $module

=cut
#**********************************************************
sub file_process {
  my ($file_path, $module) = @_;

  my $content = '';
  open(my $fh, '<', $file_path);
  while(<$fh>) {
    $content .= $_;
  }
  close($fh);

  my %matches = $content =~ /(\d+)\s*=>\s*['"](.+?)['"]/gm;
  $ERRORS_LANG_KEYS{$module} //= {};

  while (my ($k, $v) = each %matches) {
    if ($ERRORS_LANG_KEYS{$module}{$k}) {
      print "ERROR, ALREADY HAVE $k value $v\n" if ($args->{DEBUG});
    }
    else {
      $ERRORS_LANG_KEYS{$module}{$k} = $v;
    }
  }
}

#**********************************************************
=head2 code_file_search()

=cut
#**********************************************************
sub code_file_search {
  my $name = $File::Find::name;
  my $dir = $File::Find::dir;

  if ($dir eq $name) {
    return 1;
  }
  my $file_name = substr($name, length($dir) + 1);

  my ($extension) = $name =~ /([^.]+)$/;

  if (grep { $_ eq $extension } @ALLOWED_EXTENSIONS) {
    code_file_process($name, $dir);
    return 1;
  }
}

#**********************************************************
=head2 code_file_process()

=cut
#**********************************************************
sub code_file_process {
  my ($file_path, $dir) = @_;

  open(my $fh, '<', $file_path);
  while(<$fh>) {
    for my $regex (@KEYS_REGEXPS) {
      my @matches = $_ =~ /$regex/g;
      for my $match (@matches) {
        $ERRORS_BASE_LIST{$match} = 1;
      }
    }
  }
  close($fh);
}

#**********************************************************
=head2 error_keys_search($all_keys, $used_keys)

=cut
#**********************************************************
sub error_keys_search {
  for my $path (split /\;/, $dirs) {
    my @DIRS = ($path,);
    my $options = { wanted => \&code_file_search };

    find($options, @DIRS);
  }
}

#**********************************************************
=head2 format_error_keys($list, $langs)

=cut
#**********************************************************
sub format_error_keys {
  my ($list, $langs) = @_;

  my %unique_errno;
  $unique_errno{$_} = 1 for keys %$list;
  $unique_errno{$_} = 1 for map { keys %$_ } values %$langs;

  my @output = ();

  for my $k (sort keys %unique_errno) {
    my $obj = {
      errno  => $k,
      errstr => '',
      errmsg => ''
    };

    my ($module) = grep { exists $langs->{$_}{$k} } keys %$langs;

    if ($module) {
      $obj->{errstr} = $langs->{$module}{$k};
      $obj->{errmsg} = $lang{$langs->{$module}{$k}} || '';
      $obj->{module} = $module;
    }
    else {
      $obj->{module} = '-';
    }

    my $is_user = $k / 1000 % 2;
    $obj->{type} = $is_user ? 'USER' : 'ADMIN';

    push @output, $obj;
  }

  return \@output;
}

sub load_lang {
  my @langs = ('russian', 'english');
  for my $key (@langs) {
    eval {
      require $::libpath . "/language/$key.pl";
    };

    my $modules_dir = $::libpath . 'Abills/modules';
    my @files = ();

    find(
      sub {
        if (/lng_$key\.pl$/) { # Match files named lng_english.pl
          push @files, $File::Find::name;
        }
      },
      $modules_dir
    );

    # Loop through each found file and require it
    foreach my $file (@files) {
      eval {
        require $file;
      };
      if ($@) {
        warn "Failed to load $file: $@\n";
      }
    }
  }
}

#**********************************************************
=head2 _get_configured_json()

  Returns:
    JSON

=cut
#**********************************************************
sub _get_configured_json {
  JSON->new->utf8->space_before(0)->space_after(1)->indent(1)->canonical(1)
}

#**********************************************************
=head2 _upload_to_confluence($values)

  Arguments:
    $values - formatted err keys

=cut
#**********************************************************
sub _upload_to_confluence {
  my ($values) = @_;

  if (!$conf{CONFLUENCE_PERSONAL_TOKEN}) {
    print "Undefined \$conf{CONFLUENCE_PERSONAL_TOKEN}.\n";
    return 1;
  }

  my @headers = (
    "Content-Type: application/json",
    "Authorization: Bearer $conf{CONFLUENCE_PERSONAL_TOKEN}",
  );

  my $page_id = 157646873;
  my $url = "http://abills.net.ua/wiki/rest/api/content/$page_id?expand=version,body.view";
  my $current = web_request($url, {
    CURL        => 1,
    HEADERS     => \@headers,
    JSON_RETURN => 1,
    JSON_UTF8   => 1,
  });

  my $version = ::get_version();
  my $desc = "<i>Данная страница документации генерируется автоматически.</i>";
  $desc .= "<br></br>";
  $desc .= "<br></br>";
  $desc .= "Версия <b>ABillS</b>: $version";

  my $body = {
    "id" => $current->{id},
    "type" => "page",
    "title" => $current->{title},
    "version" => {
      "number" => $current->{version}{number} + 1,
    },
    "body" => {
      "storage" => {
        "value"          => decode_utf8($desc . _make_table($values)),
        "representation" => "storage"
      }
    }
  };

  my $output = web_request($url, {
    CURL        => 1,
    HEADERS     => \@headers,
    JSON_RETURN => 1,
    JSON_BODY   => $body,
    METHOD      => 'PUT'
  });

  if ($args->{DEBUG}) {
    require Data::Dumper;
    print Data::Dumper::Dumper($output);
  }
}

#**********************************************************
=head2 _make_table($errors)

  Arguments:
    $errors - formatted err keys

=cut
#**********************************************************
sub _make_table {
  my ($errors) = @_;
  my $table = '<table><tr><th>Errno</th><th>Errstr</th><th>Errmsg</th><th>Type</th><th>Module</th></tr>';
  foreach my $err (@$errors) {
    my $module = $err->{module} || '';
    my $type = $err->{type} || '';
    $table .= "<tr><td>$err->{errno}</td><td>$err->{errstr}</td><td>$err->{errmsg}</td><td>$type</td><td>$module</td></tr>";
  }
  $table .= '</table>';
  return $table;
}

#**********************************************************
=head2 help()

=cut
#**********************************************************
sub help {
  print << "[END]";
  Error keys search

  Dev Tool for:
  1) Errors search
  2) Upload to confluence

  Params:
    PATH       - errors search path
      default: /usr/abills/
    LIST       - show errors output
    UPLOAD     - upload errors to confluence
    DEBUG      - show debug info

[END]
}

1;
