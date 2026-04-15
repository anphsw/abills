#!/usr/bin/perl

use strict;
use warnings;

our ($libpath, $Bin, %conf, $db, $Admin, $base_dir, @MODULES);

BEGIN {
  use FindBin '$Bin';
  $libpath = $Bin . '/../../';
}

use lib $Bin;
use lib $libpath;
use lib $libpath . 'lib';
use lib $libpath . 'Abills/mysql';

do 'libexec/config.pl';

use Abills::AI::Integrations::Confluence;
use Abills::AI::Qdrant;
use Abills::AI::Embeddings;
use Data::UUID;
use Abills::Base qw(parse_arguments);
use Abills::SQL;
use Admins;
use Encode qw(decode_utf8 encode is_utf8);

my $argv = parse_arguments(\@ARGV);

my $debug = ($argv->{DEBUG}) ? $argv->{DEBUG} : 0;
my $space = $argv->{SPACE} || undef;
my $chunk_size = $argv->{CHUNK_SIZE} || 800;
my $overlap = $argv->{OVERLAP} || 100;

use utf8;
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

$db = Abills::SQL->connect(
  $conf{dbtype},
  $conf{dbhost},
  $conf{dbname},
  $conf{dbuser},
  $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef }
);

$Admin = Admins->new($db, \%conf);
$Admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

my $Confluence = Abills::AI::Integrations::Confluence->new(\%conf, {
  DEBUG => $debug > 5 ? 1 : 0,
  SPACE => $space
});

my $Qdrant = Abills::AI::Qdrant->new(\%conf, { DEBUG => $debug > 5 ? 1 : 0 });
my $Embeddings = Abills::AI::Embeddings->new($db, $Admin, \%conf, { DEBUG => 1});
my $ug = Data::UUID->new;

if ($argv->{CLEAR_COLLECTION}) {
  print "Clearing collection 'docs_confluence'...\n";
  my $delete_result = $Qdrant->delete_collection('docs_confluence');

  if ($delete_result && $delete_result->{status} && ref $delete_result->{status} eq 'HASH') {
    if ($delete_result->{status}{error}) {
      print "ERROR: $delete_result->{status}{error}\n";
      exit 1;
    }
  }
  print "Collection cleared.\n";
}

print "Creating/checking collection 'docs_confluence'...\n";
my $create_result = $Qdrant->create_collection({
  name        => 'docs_confluence',
  vector_size => $conf{AI_VECTOR_SIZE} || 768,
  distance    => 'Cosine'
});

if ($create_result && $create_result->{status} && ref $create_result->{status} eq 'HASH') {
  if ($create_result->{status}{error} &&
    $create_result->{status}{error} ne 'Wrong input: Collection `docs_confluence` already exists!') {
    print "ERROR: $create_result->{status}{error}\n";
    exit 1;
  }
}
print "Collection ready.\n\n";

print "=" x 60 . "\n";
print "1. Downloading pages from Confluence...\n";
print "=" x 60 . "\n";
my $pages = $Confluence->fetch_pages();

my $total_pages = scalar(@$pages);
print "Found $total_pages pages.\n\n";

if ($total_pages == 0) {
  print "No pages found. Exiting.\n";
  exit 0;
}

print "=" x 60 . "\n";
print "2. Processing and indexing pages...\n";
print "=" x 60 . "\n";

my $processed_pages = 0;
my $total_chunks = 0;
my $skipped_pages = 0;

foreach my $page (@$pages) {
  if (length($page->{text}) <= 50) {
    $skipped_pages++;
    next;
  }

  $processed_pages++;

  $page->{encode_title} = is_utf8($page->{title}) ? encode('UTF-8',$page->{title}) : $page->{title};

  print "\n[$processed_pages/$total_pages] Processing: $page->{title}\n";
  print "URL: $page->{url}\n";
  print "Text length: " . length($page->{text}) . " characters\n";

  my @chunks = smart_chunk($page->{text}, $chunk_size, $overlap);

  print "Created " . scalar(@chunks) . " chunks\n";

  my $chunk_id = 0;
  my $success_count = 0;

  foreach my $chunk (@chunks) {
    next if length($chunk) < 20;

    my $embed_text = "Page: $page->{title}\n\nContent:\n$chunk";

    my $embed_text_bytes = is_utf8($embed_text) ? encode('UTF-8', $embed_text) : $embed_text;

    my $vector = $Embeddings->vector({ text => $embed_text_bytes });

    if ($vector) {
      my $uuid = $ug->create_str();

      my $result = $Qdrant->upsert({
        collection => 'docs_confluence',
        id         => $uuid,
        vector     => $vector,
        payload    => {
          source     => 'confluence',
          page_id    => $page->{id},
          title      => $page->{title},
          url        => $page->{url},
          text       => $chunk,
          chunk_id   => $chunk_id,
          total_chunks => scalar(@chunks),
          space      => $page->{space}
        }
      });
      sleep(0.5);

      if ($result && $result->{status} && ref $result->{status} eq 'HASH' && $result->{status}{error}) {
        print "  ERROR uploading chunk $chunk_id: $result->{status}{error}\n";
      }
      else {
        $success_count++;
        $total_chunks++;
      }
    }
    else {
      print "  ERROR: Failed to generate vector for chunk $chunk_id\n";
    }

    $chunk_id++;
  }

  print "Successfully indexed: $success_count chunks\n";
}

print "\n" . "=" x 60 . "\n";
print "SUMMARY\n";
print "=" x 60 . "\n";
print "Total pages found:      $total_pages\n";
print "Pages processed:        $processed_pages\n";
print "Pages skipped (short):  $skipped_pages\n";
print "Total chunks created:   $total_chunks\n";
print "\nDone!\n";

#**********************************************************
=head2 smart_chunk($text, $max_size, $overlap) - Split text into smart chunks

  Arguments:
    $text     - Source text
    $max_size - Maximum chunk size (characters)
    $overlap  - Overlap size between chunks (characters)

  Returns:
    List of text chunks

  Notes:
    - Text is split by paragraphs first
    - Paragraphs are combined until C<max_size> is reached
    - Long chunks are additionally split by sentence boundaries if possible
    - Overlap allows preserving context between adjacent chunks

  Example:

    my @chunks = smart_chunk(
      $text,
      1000,
      200
    );

=cut
#**********************************************************
sub smart_chunk {
  my ($text, $max_size, $overlap) = @_;

  return () if !$text;

  my @chunks = ();

  my @paragraphs = split /\n\n+/, $text;

  my $current_chunk = '';

  foreach my $para (@paragraphs) {
    $para =~ s/^\s+|\s+$//g;
    next if !$para;

    if (length($current_chunk) + length($para) + 2 <= $max_size) {
      $current_chunk .= ($current_chunk ? "\n\n" : '') . $para;
    }
    else {
      if ($current_chunk) {
        push @chunks, $current_chunk;

        if ($overlap > 0 && length($current_chunk) > $overlap) {
          my $overlap_text = substr($current_chunk, -$overlap);
          $current_chunk = $overlap_text . "\n\n" . $para;
        }
        else {
          $current_chunk = $para;
        }
      }
      else {
        $current_chunk = $para;
      }

      while (length($current_chunk) > $max_size) {
        my $chunk_part = substr($current_chunk, 0, $max_size);

        if ($chunk_part =~ /^(.*[.!?])\s+(.*)$/s) {
          push @chunks, $1;
          $current_chunk = $2 . substr($current_chunk, $max_size);
        }
        else {
          push @chunks, $chunk_part;
          $current_chunk = substr($current_chunk, $max_size);
        }
      }
    }
  }

  if ($current_chunk) {
    push @chunks, $current_chunk;
  }

  return @chunks;
}

1;
