package Config::Confluence;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

=head1 NAME

  Confluence content fetcher
    using CURL

=cut

use Abills::Fetcher;

our $VERSION = 0.01;

our @EXPORT_OK = qw(
  get_doc
  parse_page
);

#**********************************************************
=comments get_docs($attr)

  Arguments:
    $attr
      MAIN_URL
      DEBUG

  Results:
    \@context_arr

=cut
#**********************************************************
sub get_doc {
  my ($attr) = @_;

  my $main_url = $attr->{MAIN_URL} || 'https://abills.net.ua/wiki';
  my $doc_url = q{};
  my $debug = $attr->{DEBUG} || 0;

  if ($attr->{CONF}) {
    $attr->{WORD} = $attr->{CONF};
    $attr->{WORD} =~ s/$attr->{WORD}/\$conf{$attr->{WORD}}/xg;
  }

  if ($attr->{WORD} =~ /on\s+page|\$/xm) {
    $attr->{WORD} .= ' ' if ($attr->{WORD} !~ /\$/xm);
    $attr->{WORD} =~ s/\s+on\s+page\s+//xg;
    $doc_url = "$main_url/rest/api/content/search?limit=500&cql=text~'$attr->{WORD}'";
  }
  else {
    $doc_url = "$main_url/rest/api/content/search?limit=500&cql=title~'$attr->{WORD}'";
  }

  my @contents = ();

  if ($debug > 3) {
    print "Request: $doc_url\n";
  }

  my $response = web_request($doc_url, {
    JSON_RETURN => 1
  });

  my $count = 0;
  my $text = q{};
  foreach my $result (@{$response->{results}}) {
    next if ($result->{type} ne 'page');
    $count++;
    my $link = $result->{_links}->{webui};
    $text .= "$result->{title} URL: $main_url$link\n" if ($debug > 0);
    my ($result_, $describe);
    if ($attr->{WORD} =~ /\$/xm) {
      print "WORD: $attr->{WORD} Content: $main_url$link\n" if ($debug > 0);
      ($result_, $describe) = parse_page($main_url . $link, $attr->{WORD});
      if ($result_ && $result_ ne q{}) {
        print "$result_ DESCRIBE:  $describe \n" if ($debug > 0);
        #return 1;
      }
    }

    push @contents, {
      WORD     => $attr->{WORD},
      TITLE    => $result->{title},
      URL      => "$main_url$link",
      VALUE    => $result_,
      DESCRIBE => $describe
    }
  }

  print "Found $count matches with $attr->{WORD}\n$text" if ($debug > 0);

  return \@contents;
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
sub parse_page {
  my ($page, $word, $attr) = @_;
  my $result = q{};
  my $value = q{};
  my $debug  = $attr->{DEBUG} || 0;

  if ($debug > 3) {
    print "PAGE: $page\n";
  }

  my $content = web_request($page);

  if ($debug > 5) {
    print "$content\n";
  }

  $word =~ s/\$/\\\$/xg;
  $word =~ s/\{/\\\{/xg;
  $word =~ s/\}/\\\}/xg;
  $content =~ s/<br\/>/ /xig;
  #1 $conf{CHARTS_LONG_PAUSE} = 1;</th><td class="confluenceTd">Учитывать трафик с интервалом больше 5 минут. (Будет отображаться значение скорости за все интервалы)</td></tr><tr>

  my $get_varieble_dsc_expr = <<"EXPR";
>$word\\s?=\\s?([a-z0-9'"\\_\\\@\\,]+);<\\/th><td\\s+class=\\"confluenceTd\\">([\\W\\-\\_\\.\\,0-9\\(\\)\\s]+)<\\/td><\\/tr>
 | >$word\\s?=\\s?([a-z0-9'"\\_\\\@\,]+);<\\/th><td\\s+class=\\"confluenceTd\\">(.+)<\\/td><\\/tr><tr
 | >$word\\s?=\\s?([a-z0-9'"\\_\\\@\,]+);<\\/th><td\\s+class=\\"confluenceTd\\">(.+)<\\/td><\\/tr>
EXPR

  if ($content =~ /$get_varieble_dsc_expr/mxig) {
    $result = $2;
    $value = $1;

    print " Value: $value \n Describe: $result\n URL: $page\n" if ($debug > 1);
  }

  return ($value, $result, $page);
}


1;