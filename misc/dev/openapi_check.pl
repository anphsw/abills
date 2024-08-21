#!/usr/bin/perl

=head1 NAME

  openapi_check.pl

=head1 SYNOPSIS

  Difference between real API and OpenAPI description

  Arguments:
    PATH       - search path
      default: /usr/abills/
    STRICT     - strict search:
      1) doesnt ignore end /

=head1 PURPOSES

  + Check difference between real API and OpenAPI description

=cut

use strict;
use warnings;

BEGIN {
  use FindBin '$Bin';
  our $libpath = $Bin . '/../../';

  unshift(@INC,
    $libpath . '/lib/',
    $libpath
  );
}

use File::Find;

my @paths_files;
my @api_files;
my %paths_from_files;
my %paths_from_yaml;

use Abills::Base qw(parse_arguments);
use JSON qw(to_json);
use Pod::Usage qw/pod2usage/;

my $args = parse_arguments(\@ARGV);
my $probably_path = $Bin;
$probably_path =~ s|/[^/]+/[^/]+$|/|;
$probably_path //= '/usr/abills/';
my $base_dir = $args->{PATH} // $probably_path;

start();

#**********************************************************
=head2 start()

=cut
#**********************************************************
sub start {
  if ($args->{HELP}) {
    print pod2usage();
    return;
  }

  find_files($base_dir . 'Abills/Api/Paths', qr/\.pm$/, \@paths_files);
  find_files($base_dir . 'Abills/modules', qr/Api\.pm$/, \@api_files);

  foreach my $file (@paths_files, @api_files) {
    extract_paths_from_files($file);
  }

  extract_paths_from_yaml($base_dir . 'misc/api/bundle_admin.yaml');
  extract_paths_from_yaml($base_dir . 'misc/api/bundle_user.yaml');

  my %results = ();
  $results{in_perl_not_yaml} = [grep { not exists $paths_from_yaml{$_} } sort keys %paths_from_files];
  $results{in_yaml_not_perl} = [grep { not exists $paths_from_files{$_} } sort keys %paths_from_yaml];

  my $json = _get_configured_json();
  print $json->encode(\%results);
}

#**********************************************************
=head2 normalize_path($path)

=cut
#**********************************************************
sub normalize_path {
  my ($path) = @_;
  if (!$args->{STRICT}) {
    $path =~ s/\/$//;
  }
  return $path;
}

#**********************************************************
=head2 convert_openapi_path($path)

=cut
#**********************************************************
sub convert_openapi_path {
  my ($path) = @_;
  $path =~ s/\{([^\}]+)\}/':' . $1/ge;
  return $path;
}


#**********************************************************
=head2 extract_paths_from_files($file)

=cut
#**********************************************************
sub extract_paths_from_files {
  my ($file) = @_;
  open my $fh, '<', $file or die "Could not open '$file' $!";
  local $/ = undef;
  my $content = <$fh>;
  close $fh;

  while ($content =~ /\{[^}]*method\s*=>\s*'([^']+)'[^}]*path\s*=>\s*'([^']+)'[^}]*\}/g) {
    my $method = $1;
    my $path = normalize_path($2);
    $paths_from_files{"$method $path"} = 1;
  }
}

#**********************************************************
=head2 find_files($dir, $pattern, $file_list_ref)

=cut
#**********************************************************
sub find_files {
  my ($dir, $pattern, $file_list_ref) = @_;
  find(sub {
    push @$file_list_ref, $File::Find::name if /$pattern/;
  }, $dir);
}

#**********************************************************
=head2 extract_paths_from_yaml($file)

=cut
#**********************************************************
sub extract_paths_from_yaml {
  my ($file) = @_;
  open my $fh, '<', $file or die "Could not open '$file' $!";
  my $current_path;

  while (my $line = <$fh>) {
    if ($line =~ /^\s*\/([^:]+):?/) {
      $current_path = normalize_path("/$1");
    }
    if ($line =~ /^\s*(get|post|put|delete|patch|options|head):/) {
      my $method = uc($1);
      $current_path = convert_openapi_path($current_path) if defined $current_path;
      $paths_from_yaml{"$method $current_path"} = 1 if defined $current_path;
    }
  }

  close $fh;
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
