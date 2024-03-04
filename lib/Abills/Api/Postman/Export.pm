package Abills::Api::Postman::Export;

use strict;
use warnings FATAL => 'all';

use JSON qw(decode_json);
use Data::Compare qw(Compare);
use Abills::Base qw(in_array json_former);
use Abills::Api::Postman::Constants qw(VARIABLES);
use Abills::Api::Postman::Utils qw(read_file write_to_file);
use Abills::Api::Postman::Api;
use Abills::Api::Postman::Schemas;

my Abills::Api::Postman::Api $Postman;
my $json = JSON->new->utf8->space_before(0)->space_after(1)->indent(1)->canonical(1);
my $Schemas = Abills::Api::Postman::Schemas->new();

#**********************************************************
=head2 new($db, $attr)

  Public define props

    base_dir: str   - dir where installed abills
    conf: obj       - hash config of abills
    debug: int      - debug level of code execution
    module: str     - module tests which need to export
    type: str       - type of tests
      example:
        user
        admin

  Local define props

    errors: int     - count of errors
    preview: str    - string tree of structure

=cut
#**********************************************************
sub new {
  my ($class, $attr) = @_;

  my $module = ucfirst(lc($attr->{module} || ''));

  my $self = {
    conf     => $attr->{conf} || $attr->{CONF} || 0,
    debug    => $attr->{debug} || $attr->{DEBUG},
    errors   => 0,
    base_dir => $attr->{base_dir} || '/usr/abills/',
    module   => $module,
    type     => $attr->{type} || 'user',
    preview  => '',
    export   => $attr->{export} ? 1 : 0,
  };

  bless($self, $class);

  $Postman = Abills::Api::Postman::Api->new({
    conf          => $self->{conf},
    debug         => $self->{debug},
    collection_id => $self->{type} eq 'admin' ? $self->{conf}->{POSTMAN_ADMIN_COLLECTION_ID} : $self->{conf}->{POSTMAN_USER_COLLECTION_ID},
  });

  return $self;
}

#**********************************************************
=head2 process() base running function

  Arguments

=cut
#**********************************************************
sub process {
  my $self = shift;

  print "Postman tests export process start\n";

  if (!$self->{module}) {
    print "Export process ended. Export module not selected.";
    return 0;
  }

  my $dir_path = $self->_get_dir_path();

  if (!$dir_path) {
    print "\nTests not exists for module: $self->{module} and type $self->{type}";
    print "Export process ended.\n\n";
    return 0;
  }

  # get collection
  my $collection = $Postman->collection_info();

  if ($collection->{error}) {
    print "\nPostman error: " . ($collection->{error}->{name} || '')
      . ' Error message: ' . ($collection->{error}->{message} || '') . "\n";
    print "Export process ended.\n\n";
    return 0;
  }

  $self->{collection} = $collection->{collection};

  $self->_collection_variables();

  my $root_dir_id = $self->_get_dir_id($dir_path);
  $self->{dir_path} = $dir_path;
  $self->{new} = !$root_dir_id;
  $self->_read_tests($dir_path, $root_dir_id);

  print "\n\nExport process ended. Count of errors: $self->{errors}\n";

  return 1;
}

#**********************************************************
=head2 _collection_variables() create base collection variables

=cut
#**********************************************************
sub _collection_variables {
  my $self = shift;

  my $vars = $self->{collection}->{variable} || [];
  my @new_values;

  if (scalar @{$vars}) {
    @new_values = grep { my $element = $_->{key} || ''; !grep { $_->{key} && $_->{key} eq $element; } @{$vars} } @{+VARIABLES};
  }
  else {
    @new_values = (VARIABLES);
  }

  return 0 if (!scalar @new_values);

  print "In Postman not present all global variables. Do you want add it?\n";
  print "Apply? (y/N): ";

  chomp(my $choice = <STDIN>);

  return 0 if (lc($choice) ne 'y');

  my $result = $Postman->collection_update({
    request => {
      collection => {
        variables => [ @new_values, @{$vars} ],
      }
    },
  });

  if ($result->{error}) {
    print "Failed add variables to Postman\n";
    print "\nPostman error: " . ($result->{error}->{name} || '')
      . ' Error message: ' . ($result->{error}->{message} || '') . "\n";

    $self->{errors}++;
  }
  else {
    print "Successfully created collection variables\n";
  }

  return 1;
}

#**********************************************************
=head2 _get_dir_path() return where stored tests

  Arguments

=cut
#**********************************************************
sub _get_dir_path {
  my $self = shift;

  my $module_dir = "$self->{base_dir}Abills/modules/$self->{module}/t/schemas/$self->{type}";

  return $module_dir if (-d $module_dir);

  my $tests_dir = "$self->{base_dir}t/Api/$self->{module}/schemas/$self->{type}";

  return $tests_dir if (-d $tests_dir);

  return '';
}

#**********************************************************
=head2 _get_dir_id($dir_path) get .postman-id of folder

  Arguments
    dir_path: str - working directory

=cut
#**********************************************************
sub _get_dir_id {
  my $self = shift;
  my ($dir_path) = @_;

  my $file_path = "$dir_path/.postman-id";

  return '' if (!-f $file_path);

  my $id = read_file($file_path);
  $id =~ s/\s\n\r//gm if ($id);

  return $id || '';
}

#**********************************************************
=head2 _read_tests($dir, $folder_id) get all tests from working module

  Arguments
    dir: str        - working directory
    folder_id: str  - .postman-id of folder

=cut
#**********************************************************
sub _read_tests {
  my $self = shift;
  my ($dir, $folder_id) = @_;

  opendir(my $dh, $dir) or die "Cannot open directory $dir: $!";
  my @files = readdir($dh);
  closedir($dh);

  if (!$folder_id) {
    my $id = $self->_get_dir_id($dir);
    if ($id) {
      $folder_id = $id;
    }
    else {
      $folder_id = $self->_create_dir($dir);
    }

    if (!$folder_id) {
      print "Failed work with directory $dir.\n";
      return 0;
    }
  }

  foreach my $file (@files) {
    next if $file eq '.' or $file eq '..';

    my $path = "$dir/$file";

    if (-d $path) {
      $self->{preview} .= "Directory: $path\n";
      $self->_read_tests($path, $folder_id);
    }
    else {
      $self->{preview} .= "File: $path\n";

      if ($file eq 'schema.json' || $file eq 'request.json') {

        my $schemas = $self->_get_schemas($dir);
        if (!$schemas) {
          print "Error. Can not get schemas from path $dir. Skip\n";
          $self->{errors}++;
          return 0;
        }

        if ($self->{new}) {
          $self->_new_request($dir, $folder_id, $schemas);
        }
        else {
          $self->_update_request($dir, $folder_id, $schemas);
        }
        last;
      }
    }
  }
}

#**********************************************************
=head2 _create_dir($dir_path) create dir in Postman base on local info

  Arguments
    dir: str        - working directory

=cut
#**********************************************************
sub _create_dir {
  my $self = shift;
  my ($dir) = @_;

  my $parent_id = '';
  my $folder_name = '';
  my $is_root_dir = $dir =~ /schemas\/$self->{type}$/g;
  if ($is_root_dir) {
    $folder_name = lc($self->{module});
  }
  else {
    if ($dir =~ /^(.*\/)[^\/]+$/) {
      my $parent_path = $1;
      my $id = $self->_get_dir_id($parent_path);
      $parent_id = $id if ($id);
    }
    ($folder_name) = $dir =~ m{([^/]+)/[^/]+/?$};
  }

  my $attr = {
    folder_name => $folder_name
  };
  $attr->{folder_id} = $parent_id if ($parent_id);

  my $folder = $Postman->folder_create({ folder_name => $folder_name });
  if ($folder->{error}) {
    print "Failed add directory to postman $folder_name";
    print "\nPostman error: " . ($folder->{error}->{name} || '')
      . ' Error message: ' . ($folder->{error}->{message} || '') . "\n";

    $self->{errors}++;
    return '';
  }
  my $file_path = "$dir/.postman-id";
  my $id = $folder->{data}->{id};
  write_to_file($file_path, $id);

  return $id;
}

#**********************************************************
=head2 _new_request($dir, $folder_id, $schemas) create new request

  Arguments
    dir: str        - working directory
    folder_id: str  - .postman-id of folder
    schemas: obj    - hash of function Abills::Api::Postman::Export::_get_schemas

=cut
#**********************************************************
sub _new_request {
  my $self = shift;
  my ($dir, $folder_id, $schemas) = @_;

  my $request = $Postman->request_add({
    folder_id => $folder_id,
    request   => $schemas->{postman_request},
  });

  if ($request->{error}) {
    print "Failed add directory to postman $schemas->{postman_request}->{name}";
    print "\nPostman error: " . ($request->{error}->{name} || '')
      . ' Error message: ' . ($request->{error}->{message} || '') . "\n";
    #TODO: maybe add automatically clean request?
    print "Chosen wrong collection or delete need delete file .postman-id in folder\n";

    $self->{errors}++;
    return 0;
  }
  else {
    print "Successfully exported test with from $dir\n";
    $schemas->{request_schema}->{postmanId} = $request->{data}->{id};
    my $request_schema_json = $json->encode($schemas->{request_schema});
    write_to_file("$dir/request.json", $request_schema_json)
  }

  return 1;
}

#**********************************************************
=head2 _update_request($dir, $folder_id, $schemas) update existing request

  Arguments
    dir: str        - working directory
    folder_id: str  - .postman-id of folder
    schemas: obj    - hash of function Abills::Api::Postman::Export::_get_schemas

=cut
#**********************************************************
sub _update_request {
  my $self = shift;
  my ($dir, undef, $schemas) = @_;

  my $id = $schemas->{request_schema}->{postmanId};

  if (!$id) {
    return $self->_new_request(@_);
  }

  my $request = $self->_get_request_by_id($self->{collection}->{item}, $id);

  my $request_schema_remote = $Schemas->generate_request_schema($request);
  my $response_schema_remote = $Schemas->generate_response_schema($request, 1);

  delete $schemas->{request_schema}->{params} if (ref $schemas->{request_schema}->{params} ne 'ARRAY');

  my $isSameRequest = Compare($schemas->{request_schema}, $request_schema_remote);
  my $isSameResponse = Compare($schemas->{response_schema}, $response_schema_remote);

  if ($isSameRequest && $isSameResponse) {
    return 1;
  }

  print "Postman and local schemas not the same from $dir. Do you want to change remote Postman schema?\n";
  print "Apply? (y/N): ";

  chomp(my $choice = <STDIN>);

  return 0 if (lc($choice) ne 'y');

  my $change_result = $Postman->request_change({
    request_id => $id,
    request    => $schemas->{postman_request},
  });

  if ($change_result->{error}) {
    print "Failed add directory to postman $id";
    print "\nPostman error: " . ($change_result->{error}->{name} || '')
      . ' Error message: ' . ($change_result->{error}->{message} || '') . "\n";

    $self->{errors}++;
    return 0;
  }
  else {
    print "Successfully changed test in Postman\n";
  }

  return 1;
}

#**********************************************************
=head2 _get_request_by_id($dir, $folder_id, $schemas) update existing request

  Arguments
    items: obj - items in collection folder
    id: str    - postman request id which need to find in collection

=cut
#**********************************************************
sub _get_request_by_id {
  my $self = shift;
  my ($items, $id) = @_;

  if (ref $items eq 'HASH') {
    for my $key (keys %$items) {
      if ($key eq 'id' && $items->{$key} eq $id) {
        return $items;
      } elsif (ref($items->{$key}) eq 'ARRAY' || ref($items->{$key}) eq 'HASH') {
        my $result = $self->_get_request_by_id($items->{$key}, $id);
        return $result if $result;
      }
    }
  }
  elsif (ref $items eq 'ARRAY') {
    for my $element (@$items) {
      my $result = $self->_get_request_by_id($element, $id);
      return $result if $result;
    }
  }

  return '';
}

#**********************************************************
=head2 _get_schemas($dir) convert local schemas to postman

  Arguments
    dir: str        - working directory

=cut
#**********************************************************
sub _get_schemas {
  my $self = shift;
  my ($dir) = @_;

  my $request_schema_json = read_file("$dir/request.json");
  my $response_schema_json = read_file("$dir/schema.json");

  $@ = undef;
  my $request_schema = eval { decode_json($request_schema_json) };
  my $response_schema = eval { decode_json($response_schema_json) };

  if ($@) {
    print "ERROR. Failed to decode json of schemas in folder $dir\n $@";
    $self->{errors}++;
    $@ = undef;
    return 0;
  }

  my $name = lc($request_schema->{name} || '');
  $name =~ s/_/ /gm;
  my $postman_request = {
    method => $request_schema->{method},
    url    => "{{BILLING_URL}}/" . ($request_schema->{path} || ''),
    name   => $name,
  };

  if ($request_schema->{path} =~ /:uid/) {
    $postman_request->{pathVariableData} = [
      {
        key   => 'uid',
        value => '{{UID}}'
      }
    ];
  }

  my @headers = ();

  if ($self->{type} eq 'user') {
    push @headers, { key => 'USERSID', value => '{{USERSID}}' };
  }
  else {
    push @headers, { key => 'KEY', value => '{{API_KEY}}' };
  }

  # in postman example field is headers
  $postman_request->{headerData} = \@headers;

  if ($request_schema->{body}) {
    $postman_request->{rawModeData} = json_former($request_schema->{body}, { ESCAPE_DQ => 1 });
    $postman_request->{dataMode} = 'raw';
    $postman_request->{dataOptions} = {
      raw => {
        language => 'json'
      }
    };
  }

  if ($request_schema->{params} && ref $request_schema eq 'ARRAY') {
    $postman_request->{queryParams} = $request_schema->{params};
  }

  $postman_request->{events} = $self->_get_postman_test($response_schema_json);

  return {
    postman_request => $postman_request,
    request_schema  => $request_schema,
    response_schema => $response_schema
  };
}

#**********************************************************
=head2 _get_schemas($dir) generate js test for request

  Arguments
    response_schema: str - json str of response schema

=cut
#**********************************************************
sub _get_postman_test {
  my $self = shift;
  my ($response_schema) = @_;

  $response_schema =~ s/"/\"/gm;
  my $pattern = qr/\r\n|\r|\n/;
  $response_schema =~ s/\$/\\\$/gm;
  my @lines = split($pattern, $response_schema);

  $lines[0] = 'const schema = ' . ($lines[0] || '');

  #TODO: make it more clever maybe do separate .js file with test
  my @script = (
    "const response = JSON.parse(responseBody);",
    "",
    "pm.test(\"Status code is 200\", () => {",
    "  pm.expect(pm.response.code).to.eql(200);",
    "});",
    "",
  );

  my @script_end = (
    "",
    "pm.test('Response body matches the JSON schema', function() {",
    "  const validationResult = tv4.validateMultiple(response, schema);",
    "",
    "  if (!validationResult.valid) {",
    "    const errorMessages = validationResult.errors.map(error => error.message);",
    "    pm.expect.fail('JSON schema validation failed: ' + errorMessages.join(' '));",
    "  }",
    "});",
    ""
  );

  push @script, @lines, @script_end;

  return [
    {
      'listen' => 'test',
      script => {
        'exec' => \@script,
        type   => 'text/javascript'
      },
    }
  ];
}

1;
