#!/usr/bin/perl

=head1 NAME

  documentation_link_parser.pl

=head1 SYNOPSIS

  Documentation link parser

  Dev Tool for:
    1) Links check of documentation
       This process can take around 5 minutes.

=head1 OPTIONS

    URL       - config search path
      default: http://abills.net.ua/wiki
    LINKS     - links check of documentation

=cut

use strict;
use warnings FATAL => 'all';

BEGIN {
  use FindBin '$Bin';
  our $libpath = $Bin . '/../../';

  unshift(@INC,
    $libpath . '/lib/',
    $libpath
  );
}

use Abills::Base qw/parse_arguments/;
use LWP::UserAgent;
use JSON;
use URI::Escape;

my $args = parse_arguments(\@ARGV);
my $base_url = $args->{PATH} // 'http://abills.net.ua/wiki';
my $api_url = $base_url . '/rest/api';
my $ua = LWP::UserAgent->new;
my $port_pattern = ':8090';
my $COMPILED_URL_PATTERN = qr/\/wiki|$port_pattern|doku.php/;
my $COMPILED_8090_PATTERN = qr/$port_pattern/;
my $COMPILED_DOKUPHP_PATTERN = qr/doku.php/;

# MAIN PAGE
my $start_page_id = '1277998';

start();

#**********************************************************
=head2 start()

=cut
#**********************************************************
sub start {
  if ($args->{LINKS}) {
    my %visited = ();
    my %pages_with_8090 = ();
    my %base_of_abs = ();
    my %pages_with_dokuphp = ();
    my $links_tree = build_links_tree($start_page_id, \%visited, \%pages_with_8090, \%pages_with_dokuphp, \%base_of_abs);

    my $json = _get_configured_json();

    print $json->encode({
      tree          => $links_tree,
      links_8090    => \%pages_with_8090,
      links_dokuphp => \%pages_with_dokuphp
    });
    return;
  }

  help();
}

#**********************************************************
=head2 fetch_page_content($page_id)

  Arguments:
    $page_id

  Returns:
    ($content, $err)

=cut
#**********************************************************
sub fetch_page_content {
  my ($page_id) = @_;
  my $url = "$api_url/content/$page_id?expand=body.view";
  my $response = $ua->get($url);
  my $err = ("Error fetching $url: " . $response->status_line) unless $response->is_success;
  return (decode_json($response->decoded_content), $err);
}

#**********************************************************
=head2 extract_links($html_content)

  Arguments:
    $html_content

  Returns:
    @urls

=cut
#**********************************************************
sub extract_links {
  my ($html_content) = @_;
  my @urls;

  while ($html_content =~ /<a\s+[^>]*href="([^"]+)"/g) {
    my $url = $1;
    if ($url =~ $COMPILED_URL_PATTERN) {
      push @urls, $url;
    }
  }

  return @urls;
}

#**********************************************************
=head2 build_links_tree($page_id, $visited, $pages_with_8090_links, $base_of_abs, $pages_with_dokuphp)

  Arguments:
    $page_id
    $visited
    $pages_with_8090_links
    $pages_with_dokuphp
    $base_of_abs

  Returns:
    @urls

=cut
#**********************************************************
sub build_links_tree {
  my ($page_id, $visited, $pages_with_8090_links, $pages_with_dokuphp, $base_of_abs) = @_;
  $visited->{$page_id} = 1;

  my ($content, $err) = fetch_page_content($page_id);
  if ($err) {
    delete $visited->{$page_id};
    $visited->{$page_id} = 'ERROR';
    return {};
  }
  my $html_content = $content->{body}->{view}->{value};

  my @links = extract_links($html_content);

  foreach my $link (@links) {
    if ($link =~ $COMPILED_8090_PATTERN) {
      $pages_with_8090_links->{$page_id} = 1;
    } elsif ($link =~ $COMPILED_DOKUPHP_PATTERN) {
      $pages_with_dokuphp->{$page_id} = 1;
    }
  }

  my %links_tree;

  foreach my $link (@links) {
    $link = "$base_url$link" if $link =~ /^\/wiki/;

    if ($link =~ /\/pages\/viewpage\.action\?pageId=(\d+)/) {
      my $linked_page_id = $1;
      next if $visited->{$linked_page_id};
      $links_tree{$linked_page_id} = build_links_tree($linked_page_id, $visited, $pages_with_8090_links, $pages_with_dokuphp, $base_of_abs);
    } elsif ($link =~ /\/display\/(.+)/) {
      my $linked_page_id = resolve_page_id($link, $base_of_abs);
      if (!$linked_page_id) {
        print "PAGE NOT EXIST: ", $link, "\n";
        next;
      }
      next if $visited->{$linked_page_id};
      $links_tree{$linked_page_id} = build_links_tree($linked_page_id, $visited, $pages_with_8090_links, $pages_with_dokuphp, $base_of_abs);
    }
  }

  return \%links_tree;
}

#**********************************************************
=head2 resolve_page_id($url, $base_of_abs) - extract pageId from space pages

  Arguments:
    $url         - full url without ids
      example: http://abills.net.ua/wiki/display/AB/Paysys
    $base_of_abs - cache

  Returns:
    $page_id || undef

=cut
#**********************************************************
sub resolve_page_id {
  my ($url, $base_of_abs) = @_;

  if ($url =~ /\/display\/([^\/]+)\/([^#?]*)/) {
    my $space_key = $1;
    my $page_title = uri_unescape($2);
    $page_title =~ s/\+/ /g;
    if ($base_of_abs->{$page_title}) {
      return $base_of_abs->{$page_title};
    }

    my $search_url = "$api_url/content?title=" . uri_escape($page_title) . "&spaceKey=" . uri_escape($space_key);
    my $response = $ua->get($search_url);

    if ($response->is_success) {
      my $result = decode_json($response->decoded_content);

      if ($result->{results} && @{$result->{results}}) {
        $base_of_abs->{$page_title} = $result->{results}[0]->{id};
        return $result->{results}[0]->{id};
      }
    } else {
      warn "Error fetching $search_url: ", $response->status_line;
    }
  }

  return undef;
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
=head2 help()

=cut
#**********************************************************
sub help {
  print << "[END]";
  Documentation link parser

  Dev Tool for:
    1) Incremental links check of documentation
       This process can take around 5 minutes.

  Params:
    URL       - config search path
      default: http://abills.net.ua/wiki
    LINKS     - links check of documentation

[END]
}
