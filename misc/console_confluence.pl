#!/usr/bin/perl
=head1 NAME

  Documentation helper for get link for documentation in console

=head1 ARGUMENTS

  WORD - word which you want to find in Confluence
  CONF - Find conf parameters and describe it
  help - read how to use

=cut
use strict;
no warnings 'layer';

BEGIN {
  our $libpath = '../';
  unshift(@INC,
    $libpath . '/lib/',
    $libpath
  );
}

use Abills::Base qw(parse_arguments);
use JSON qw(decode_json);
use HTTP::Request::Common;
use LWP::Simple;

my $main_url = 'http://abills.net.ua/wiki';

my $argv = parse_arguments(\@ARGV);

my $debug = $argv->{DEBUG} || 0;

if ($argv->{WORD} || $argv->{CONF}) {
  get_doc($argv);
}
else {
  print "To do a documentation search write: 'Internet'\n";
  print "To do search through documentation pages: 'Internet on page'\n";

  print "No param WORD please try again with it\n"
    . "Example: "
    . " console_confluence.pl WORD=Internet\n"
    . " Find config variables \n"
    . " console_confluence.pl CONF=ADMIN_MAIL\n\n";
}

#**********************************************************
=comments parse_page($attr)

  Arguments:
    $attr

  Results:
    $context

=cut
#**********************************************************
sub get_doc  {
  my ($attr) = @_;

  my $doc_url = q{};

  if ($attr->{CONF}) {
    $attr->{WORD}=$attr->{CONF};
    $attr->{WORD} =~ s/$attr->{WORD}/\$conf{$attr->{WORD}}/g;
  }

  if ($attr->{WORD} =~ /on\s+page|\$/) {
    $attr->{WORD} .= ' ' if ($attr->{WORD} !~ /\$/);
    $attr->{WORD} =~ s/\s+on\s+page\s+//g;
    $doc_url = "$main_url/rest/api/content/search?limit=500&cql=text~'$attr->{WORD}'";
  }
  else {
    $doc_url = "$main_url/rest/api/content/search?limit=500&cql=title~'$attr->{WORD}'";
  }

  if ($debug > 3) {
    print "Request: $doc_url\n";
  }

  my $Ua = LWP::UserAgent->new(
    ssl_opts => {
      verify_hostname => 0,
      SSL_verify_mode => 0
    },
  );

  my $get_request = HTTP::Request->new('GET', $doc_url);

  my $response = $Ua->request($get_request);
  $response = decode_json($response->{_content});

  my $count = 0;
  my $text = q{};
  foreach my $result (@{$response->{results}}) {
    next if ($result->{type} ne 'page');
    $count++;
    my $link = $result->{_links}->{webui};
    $text .= "$result->{title} URL: $main_url$link\n";
    if($attr->{WORD} =~ /\$/ ) {
      if (parse_page($main_url . $link, $attr->{WORD})) {
        return 1;
      }
    }
  }

  print "Found $count matches with $attr->{WORD}\n$text";

  return 1;
}

#**********************************************************
=comments parse_page($page, $word)

  Arguments:
    $page
    $word

  Results:
    $context

=cut
#**********************************************************
sub parse_page  {
  my ($page, $word)=@_;
  my $result = q{};

  my $Ua = LWP::UserAgent->new(
    ssl_opts => {
      verify_hostname => 0,
      SSL_verify_mode => 0
    }
  );

  if ($debug > 3) {
    print "PAGE: $page\n";
  }

  my $get_request = HTTP::Request->new('GET', $page);

  my $response = $Ua->request($get_request);

  my $context = $response->{_content};

  #$word = '\$conf{dbhost}';
  $word =~ s/\$/\\\$/g;
  #print "- $word -";
  $context =~ s/<br\/>/ /ig;
  if ($context =~ />$word\s?=\s?([a-z0-9'"\_@\,]+);<\/th><td class=\"confluenceTd\">([\W\_\-\.\,0-9\(\)\s]+)<\/td><\/tr>/ig
    || $context =~ />$word\s?=\s?([a-z0-9'"\_@\,]+);<\/th><td class=\"confluenceTd\">(.+)<\/td><\/tr><tr/ig
    || $context =~ />$word\s?=\s?([a-z0-9'"\_@\,]+);<\/th><td class=\"confluenceTd\">(.+)<\/td><\/tr>/ig ) {
    $result   = $2;
    my $value = $1;

    print " Value: $value \n Describe: $result\n URL: $page\n";
  }

  return $result;
}

1;