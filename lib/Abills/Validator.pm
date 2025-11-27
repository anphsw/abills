package Abills::Validator;

use strict;
use warnings FATAL => 'all';

use parent 'Exporter';

use JSON;
use FindBin '$Bin';

use Abills::Base qw(_bp);

our @EXPORT = qw(
  json_compare
  xml_compare
);
our @EXPORT_OK = qw(
  json_compare
  xml_compare
);

#*******************************************************************
=head2 xml_compare($result, $compare) - Compare function

  Arguments:
    $result   - Request result
    $compare  - Compare result

  Return:
    TRUE or FALSE

=cut
#*******************************************************************
sub xml_compare {
  my ($attr) = @_;

  return 1 if (!$attr->{SCHEMA});

  require XML::LibXML;
  XML::LibXML->import();

  my $schema = XML::LibXML::Schema->new(location => $attr->{SCHEMA});
  my $parser = XML::LibXML->new();

  my $doc = $parser->parse_string($attr->{RESULT});

  eval { $schema->validate($doc) };

  if (!$@) {
    print "\nXML is VALID\n" if ($attr->{DEBUG} > 2);

    return 1;
  }

  if ($attr->{DEBUG} > 2) {
    print "\n\nXML is INVALID: $@\n\n";
  }

  return 0;
}

#*******************************************************************
=head2 json_compare($result, $compare) - Compare function

  Arguments:
    $result   - Request result
    $compare  - Compare result

  Return:
    TRUE or FALSE

=cut
#*******************************************************************
sub json_compare {
  my ($attr) = @_;

  return 1 if (!$attr->{SCHEMA});

  # modern JSON::Validator with support newer json schema than 4
  require JSON::Validator;
  JSON::Validator->import();

  my $validator = JSON::Validator->new;

  $validator->schema($attr->{SCHEMA});

  # we can not directly pass json sting and its strange
  my $response = decode_json($attr->{RESULT});

  my @errors = $validator->validate($response);

  if (!scalar @errors) {
    print "\nJSON is VALID\n" if ($attr->{DEBUG} > 2);

    return 1;
  }

  if ($attr->{DEBUG} > 2) {
    print "\n\nJSON is INVALID: $@\n\n";
    # real print do not delete
    _bp('', \@errors, { TO_CONSOLE => 1 });
  }

  return 0;
}

1;
