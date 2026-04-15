package Abills::AI::Integrations::Confluence;

use strict;
use warnings;
use Abills::Fetcher qw/web_request/;
use JSON qw/decode_json/;
use MIME::Base64;
use HTML::Entities qw/decode_entities/;
use Time::HiRes qw/sleep/;

#**********************************************************
=head2 new($class, $conf, $attr) - Confluence client constructor

  Creates a new Confluence API client instance and initializes
  connection credentials, space settings, and request options.

  Arguments:
    $class - Class name
    $conf  - Configuration hash reference
             HASHREF
               CONFLUENCE_HOST  - Base Confluence URL
               CONFLUENCE_USER  - Username or email
               CONFLUENCE_TOKEN - API token
    $attr  - Extra attributes
             HASHREF
               SPACE      - Confluence space key
               DEBUG      - Enable debug mode
               EXPAND     - Fields to expand in API responses
                            (default: body.storage,version)
               RATE_LIMIT - Delay between requests in seconds
                            (default: 0.5)

  Returns:
    Object instance of Confluence client

  Notes:
    - RATE_LIMIT can be used to avoid hitting Confluence
      API rate limits.
    - EXPAND controls which fields are included in
      page responses.

  Example:

    my $confluence = Abills::Confluence->new(
      {
        CONFLUENCE_HOST  => 'https://company.atlassian.net/wiki',
        CONFLUENCE_USER  => 'user@example.com',
        CONFLUENCE_TOKEN => 'api-token'
      },
      {
        SPACE      => 'DEV',
        DEBUG      => 1,
        RATE_LIMIT => 1
      }
    );

=cut
#**********************************************************
sub new {
  my ($class, $conf, $attr) = @_;

  $conf //= {};
  $attr //= {};

  my $self = {
    host       => $conf->{CONFLUENCE_HOST},
    user       => $conf->{CONFLUENCE_USER},
    token      => $conf->{CONFLUENCE_TOKEN},
    space      => $attr->{SPACE},
    debug      => $attr->{DEBUG},
    expand     => $attr->{EXPAND} || 'body.storage,version',
    rate_limit => $attr->{RATE_LIMIT} || 0.5
  };

  bless $self, $class;
  return $self;
}

#**********************************************************
=head2 fetch_pages() - Fetch and parse Confluence pages

  Retrieves pages from Confluence via REST API, optionally
  limited to a specific space, and converts page content
  from HTML to plain text.

  Returns:
    ARRAYREF - List of pages with extracted content.
               Each element is a HASHREF:
                 id    - Page ID
                 title - Page title
                 text  - Page content as plain text
                 url   - Web URL to the page
                 space - Space key or 'ALL'

  Notes:
    - Uses pagination with start/limit.
    - Stops fetching after 200 items to prevent overload.
    - Applies rate limiting between requests.
    - Requires valid Confluence API credentials.

  Example:

    my $pages = $confluence->fetch_pages();

    foreach my $page (@$pages) {
      print "$page->{title}\n";
    }

=cut
#**********************************************************
sub fetch_pages {
  my ($self) = @_;

  my $api_url = "$self->{host}/rest/api/content?type=page&expand=$self->{expand}";
  if ($self->{space}) {
    $api_url .= "&spaceKey=$self->{space}";
  }

  my $start = 0;
  my $limit = 50;
  my @all_pages = ();

  while (1) {
    my $result = web_request("$api_url&start=$start&limit=$limit", {
      HEADERS => [
        "Authorization: Bearer $self->{token}",
        "Content-Type: application/json"
      ],
      CURL    => 1,
      DEBUG   => $self->{debug}
    });

    my $json = eval {decode_json($result)};
    last if $@ || !$json->{results} || scalar(@{$json->{results}}) == 0;

    foreach my $page (@{$json->{results}}) {
      my $raw_html = $page->{body}->{storage}->{value};
      my $clean_text = $self->_html_to_text($raw_html);

      my $link = "$self->{host}$page->{_links}->{webui}";

      push @all_pages, {
        id    => $page->{id},
        title => $page->{title},
        text  => $clean_text,
        url   => $link,
        space => $self->{space} || 'ALL'
      };
    }

    $start += $limit;

    sleep($self->{rate_limit}) if $self->{rate_limit} > 0;
  }

  return \@all_pages;
}

#**********************************************************
=head2 _html_to_text($html_text) - Convert Confluence HTML to plain text

  Converts Confluence storage-format HTML into readable
  plain text by stripping tags, decoding entities, and
  preserving meaningful structures such as code blocks,
  lists, headings, links, and tables.

  Arguments:
    $html_text - HTML content in Confluence storage format
                 TEXT

  Returns:
    TEXT - Cleaned plain-text representation of the content

  Notes:
    - Removes <script> and <style> blocks entirely.
    - Preserves code blocks (<ac:plain-text-body>) by
      temporarily extracting and restoring them.
    - Converts Confluence macros, links, headings, lists,
      and tables into text-friendly formats.
    - Decodes HTML entities.
    - Normalizes whitespace and excessive newlines.

  Intended for:
    - Preparing Confluence pages for indexing
    - Text analysis, embeddings, or search
    - AI/RAG pipelines

  Example:

    my $text = $self->_html_to_text($page->{body}->{storage}->{value});
    print $text;

=cut
#**********************************************************
sub _html_to_text {
  my ($self, $html_text) = @_;

  return "" if !$html_text;

  $html_text =~ s/<script\b[^>]*>.*?<\/script>//igs;
  $html_text =~ s/<style\b[^>]*>.*?<\/style>//igs;

  my %saved_data;
  my $counter = 0;

  $html_text =~ s{<ac:plain-text-body>(.*?)</ac:plain-text-body>}{
    my $content = $1;
    $content =~ s/<!\[CDATA\[(.*?)\]\]>/$1/gis;
    my $key = "___BLOCK_CODE_${counter}___";
    $saved_data{$key} = $content;
    $counter++;
    "\n\n$key\n\n";
  }egis;

  $html_text =~ s{<ac:structured-macro[^>]*ac:name="widget"[^>]*>.*?<ri:url\s+ri:value="([^"]+)"[^>]*/>.*?<\/ac:structured-macro>}{\n\nURL: $1\n\n}gis;

  $html_text =~ s{<ac:link[^>]*>.*?<ri:page\s+ri:content-title="([^"]+)"[^>]*/>.*?</ac:link>}{ $1 }gis;
  $html_text =~ s{<ac:link[^>]*>.*?<ri:url\s+ri:value="([^"]+)"[^>]*/>.*?</ac:link>}{ $1 }gis;

  $html_text =~ s/<ac:parameter[^>]*>.*?<\/ac:parameter>//gis;

  $html_text =~ s/<\/?ac:[^>]*>//gis;
  $html_text =~ s/<\/?ri:[^>]*>//gis;

  $html_text =~ s/<li[^>]*>/\n\-/gis;
  $html_text =~ s/<\/h[1-6]>/\n\n/gis;
  $html_text =~ s/<h[1-6][^>]*>/\n\n/gis;
  $html_text =~ s/<br\s*\/?>/\n/gis;
  $html_text =~ s/<\/p>/\n\n/gis;

  $html_text =~ s/<\/tr>/\n/gis;
  $html_text =~ s/<\/t[d|h]>/\t/gis;

  $html_text =~ s/<[^>]*>//gs;

  $html_text = decode_entities($html_text);

  foreach my $key (keys %saved_data) {
    my $val = $saved_data{$key};
    $html_text =~ s/\Q$key\E/$val/g;
  }

  $html_text =~ s/[ \t]+$//gm;
  $html_text =~ s/\n{3,}/\n\n/g;
  $html_text =~ s/^\s+//;
  $html_text =~ s/\s+$//;

  return $html_text;
}

#**********************************************************
=head2 fetch_single_page($page_id) - Fetch and parse a single Confluence page

  Retrieves a single Confluence page by its ID via the
  REST API and converts its HTML content into plain text.

  Arguments:
    $page_id - Confluence page ID
               TEXT | INT

  Returns:
    ARRAYREF - Array with one page hash on success
               or empty array reference on failure.
               Page structure:
                 id    - Page ID
                 title - Page title
                 text  - Page content as plain text
                 url   - Web URL to the page
                 space - Confluence space key

  Notes:
    - Uses expand=body.storage to retrieve full page content.
    - Converts HTML to text using internal _html_to_text().
    - Returns an array reference for API compatibility
      with fetch_pages().

  Example:

    my $page = $confluence->fetch_single_page(123456);
    return @$page;

    print $page->[0]->{title};

=cut
#**********************************************************
sub fetch_single_page {
  my ($self, $page_id) = @_;

  my $api_url = "$self->{host}/rest/api/content/$page_id?expand=body.storage";

  my $result = web_request($api_url, {
    HEADERS => [
      "Authorization: Bearer $self->{token}",
      "Content-Type: application/json"
    ],
    CURL    => 1,
    DEBUG   => $self->{debug}
  });

  my $page = eval {decode_json($result)};

  if ($@ || !$page || !$page->{id}) {
    return [];
  }

  my $raw_html = $page->{body}->{storage}->{value} // '';
  my $clean_text = $self->_html_to_text($raw_html);
  my $link = "$self->{host}$page->{_links}->{webui}";

  return [ {
    id    => $page->{id},
    title => $page->{title},
    text  => $clean_text,
    url   => $link,
    space => $page->{space}->{key} || 'UNKNOWN'
  } ];
}

1;