#!/usr/bin/perl
=head1 NAME

  Documentation helper for get link for documentation in console

=head1 ARGUMENTS

  WORD - word which you want to find in Confluence
  CONF - Find conf parameters and describe it
  help - read how to use

=cut
use strict;


BEGIN {
  our $libpath = '../';
  unshift(@INC,
    $libpath . '/lib/',
    $libpath . '/Abills/modules/',
    $libpath
  );
}

use Abills::Base qw(parse_arguments show_hash);
use Config::Confluence qw(get_doc);

my $argv = parse_arguments(\@ARGV);
$argv->{MAIN_URL} //= 'https://abills.net.ua/wiki';

if ($argv->{WORD} || $argv->{CONF}) {
  show_console($argv);
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
=comments get_docs($attr)

  Arguments:
    $attr

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub show_console {
  my ($attr) = @_;
  my $docs = get_doc($attr);

  my $doc_count = $#{$docs};
  for (my $i = 0; $i <= $doc_count; $i++) {
    my $doc = $docs->[$i];
    print <<"[TEXT]";
    $i. WORD: $doc->{WORD}
    TITLE: $doc->{TITLE} ($doc->{URL})
    VALUE: $doc->{VALUE}
    DESCRIBE: $doc->{DESCRIBE}

[TEXT]
  }

  print "TOTAL: " . ($doc_count + 1) . "\n";

  return 1;
}

1;