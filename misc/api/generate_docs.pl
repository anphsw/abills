#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use lib '../../';
use lib '../../lib/';

my $base_dir = '/usr/abills/';

get_docs();

#**********************************************************
=head2 get_docs() - parse swagger code

   Arguments:

  Return:
   generate yaml file

=cut
#**********************************************************
sub get_docs {

  generate_swagger('admin');
  generate_swagger('user');

  print "OK\n";
}

#**********************************************************
=head2 generate_swagger($type) - generate swagger

  Arguments:
   type: string - type of swagger which need to generate

=cut
#**********************************************************
sub generate_swagger {
  my ($type) = @_;

  my $base_swagger = _read_swagger("misc/api/$type.yaml");

  my $schemas = {
    core    => {},
    modules => {}
  };

  my $parameters = {
    core    => {},
    modules => {}
  };

  my $swagger = _parse_swagger({
    swagger    => $base_swagger,
    spaces     => '',
    root_dir   => '',
    schemas    => $schemas,
    parameters => $parameters
  });

  $swagger = _fill_schemas({
    swagger    => $swagger,
    schemas    => $schemas,
    parameters => $parameters
  });

  _write_swagger("misc/api/bundle_$type.yaml", $swagger);

  return 1;
}

#**********************************************************
=head2 _parse_swagger() - parse swagger code

   Arguments:
    swagger   - base swagger code
    spaces    - number of spaces before string
    root_dir  - flag for first call

  Return:
   parsed swagger yaml string

=cut
#**********************************************************
sub _parse_swagger {
  my ($attr) = @_;

  my $swagger = $attr->{swagger};
  my $schemas = $attr->{schemas};
  my $parameters = $attr->{parameters};

  my @matches = $swagger =~ /^\s+\-?\s?\$ref: "\.\.?.+/gm;

  foreach my $match (@matches) {
    my ($_spaces) = $match =~ /^\s+/g;
    my $root_dir = $attr->{root_dir} || '';
    $match =~ s/^\s+//g;
    my ($path) = $match =~ /(?<=\s\"|:\")(.*)(?=\")/gm;

    my $swagger_path = "misc/api/$root_dir/$path";
    $swagger_path =~ s{(?<=\w)(\.)(?=/)}{};
    my ($component) = $swagger_path =~ /schemas.*\/([^\/]+)\.yaml/gm;
    my ($parameter) = $swagger_path =~ /parameters.*\/([^\/]+)\.yaml/gm;

    print "[Path]      $swagger_path\n";

    my $new_swagger = _read_swagger("misc/api/$root_dir/$path");
    $root_dir .= '/' if ($root_dir);
    $root_dir .= $path;
    $root_dir =~ s{(?:/[^/]+)\.yaml$}{};
    $root_dir =~ s{(?<=\w)(\.)(?=/)}{};

    my $parsed_swagger = _parse_swagger({
      spaces     => ($component || $parameter) ? "      " : $_spaces,
      swagger    => $new_swagger,
      root_dir   => $root_dir,
      schemas    => $schemas,
      parameters => $parameters
    });

    $match = quotemeta($match);

    if ($component) {
      # Try to get module prefix
      my ($prefix) = $swagger_path =~ /modules\/(.*?)\//gm;
      my $is_module = !!$prefix;
      if (!$prefix) {
        # Try to get core-based prefix
        ($prefix) = $swagger_path =~ /misc\/api\/\.?\/?.*?\/(.*?)\//gm;
        $prefix = ucfirst($prefix);
      }
      $prefix //= "";
      my $capitalized_component_file_name = ucfirst($component);
      my $key = $prefix . $capitalized_component_file_name;
      $parsed_swagger =~ s/\n\z//gm;
      $schemas->{$is_module ? "modules" : "core"}->{$key} = $parsed_swagger;
      $swagger =~ s{$path}{#/components/schemas/$key}gm;
      print "[Component] $key\n";
    }
    elsif ($parameter) {
      my ($prefix) = $swagger_path =~ /modules\/(.*?)\//gm;
      my $is_module = !!$prefix;
      if (!$prefix) {
        # Try to get core-based prefix
        ($prefix) = $swagger_path =~ /misc\/api\/\.?\/?.*?\/(.*?)\//gm;
        $prefix = ucfirst($prefix);
      }
      $prefix //= "";
      my $capitalized_component_file_name = ucfirst($parameter);
      my $key = $prefix . $capitalized_component_file_name;
      $parsed_swagger =~ s/\n\z//gm;
      $parameters->{$is_module ? "modules" : "core"}->{$key} = $parsed_swagger;
      $swagger =~ s{$path}{#/components/parameters/$key}gm;
      print "[Parameter] $key\n";
    }
    else {
      $swagger =~ s/(?:(?<=\n)|(?<=\r\n))\s+$match/$parsed_swagger/gm;
    }
  }

  if ($attr->{spaces}) {
    my (@raws) = $swagger =~ /.*\r?\n?/gm;
    my $new_swagger = q{};
    foreach my $raw (@raws) {
      next if (!$raw);
      $new_swagger .= "$attr->{spaces}$raw";
    }

    return $new_swagger;
  }
  else {
    return $swagger;
  }
}

sub _fill_schemas {
  my ($attr) = @_;

  my $schemas = $attr->{schemas};
  my $swagger = $attr->{swagger};
  my $parameters = $attr->{parameters};

  for my $core_key (sort keys %{$schemas}) {
    for my $key (sort keys %{$schemas->{$core_key}}) {
      $swagger =~ s/  securitySchemes/    $key\:\n$schemas->{$core_key}->{$key}\n  securitySchemes/gm;
    }
  }

  for my $core_key (sort keys %{$parameters}) {
    for my $key (sort keys %{$parameters->{$core_key}}) {
      $swagger =~ s/  schemas/    $key\:\n$parameters->{$core_key}->{$key}\n  schemas/gm;
    }
  }

  return $swagger;
}
#**********************************************************
=head2 _read_swagger() - read swagger file from misc swagger yaml file

  Arguments:
    path - path of file of yaml swagger specification

  Return:
   return ADMIN or USER REST API

=cut
#**********************************************************
sub _read_swagger {
  my ($path) = @_;
  my $content = '';

  open(my $fh, '<', $base_dir . $path) or die "Can't open '$base_dir$path': $!";
  while (<$fh>) {
    $content .= $_;
  }
  close($fh);

  return $content;
}

#**********************************************************
=head2 _write_swagger() - write new file of swagger

  Arguments:
    path - path of file of yaml swagger specification

=cut
#**********************************************************
sub _write_swagger {
  my ($path, $swagger) = @_;

  open(my $fh, '>', $base_dir . $path) or die "Can't open '$base_dir$path': $!";
  print $fh $swagger;
  close($fh);
}

1;
