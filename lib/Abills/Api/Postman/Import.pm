package Abills::Api::Postman::Import;

use strict;
use warnings FATAL => 'all';

use JSON qw(decode_json encode_json);
use Data::Compare qw(Compare);

use Abills::Base qw(load_pmodule);
use Abills::Api::Postman::Schemas;
use Abills::Api::Postman::Utils qw(read_file write_to_file);

my $json = JSON->new->utf8->space_before(0)->space_after(1)->indent(1)->canonical(1);
my $Schemas = Abills::Api::Postman::Schemas->new();

#**********************************************************
=head2 new($db, $attr)

  Public define props

    base_dir: str   - dir where installed abills
    import: int     - generate folders and schemas
      example:
        1 - yes
        0 - no
    conf: obj       - hash config of abills
    debug: int      - debug level of code execution
    type: int       - type of tests
      example:
        0 - user
        1 - admin
    new_schemas:    - offer to save only new schemas

  Local define props

    tests_path: str - work directory path
    errors: int     - count of errors
    preview: str    - string tree of structure

=cut
#**********************************************************
sub new {
  my ($class, $attr) = @_;

  my $self = {
    conf        => $attr->{conf} || $attr->{CONF},
    debug       => $attr->{debug} || $attr->{DEBUG} || 0,
    errors      => 0,
    base_dir    => $attr->{base_dir} || '/usr/abills/',
    preview     => '',
    tests_path  => '',
    import      => $attr->{import} ? 1 : 0,
    type        => $attr->{type} || 'user',
    new_schemas => $attr->{new_schemas} ? 1 : 0
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 process($collection)

  Arguments
    $collection: obj - result object of function Abills::Api::Postman::Api::collection_info

=cut
#**********************************************************
sub process {
  my $self = shift;
  my ($collection) = @_;

  print "Postman tests import process start\n";

  if ($collection->{error}) {
    print "\nPostman error: " . ($collection->{error}->{name} || '')
        . ' Error message: ' . ($collection->{error}->{message} || '') . "\n\n";
  }
  else {
    my $items = $collection->{collection}->{item};
    $self->_structure_generate($items);

    if (!$self->{import}) {
      print "Preview of import:\n";
      print $self->{preview};
      return 0;
    }

    $self->{errors} += $Schemas->{errors} || 0;
    print "\n\nImport process ended. Count of errors: $self->{errors}\n";
  }

  return 1;
}

#**********************************************************
=head2 _structure_generate($items, $path, $structure, $delimiter)

  Arguments
    $items: obj     - items in folders
    $path: str      - abills path of work directory
    $delimiter: str - whitespaces for build correct intends for preview

=cut
#**********************************************************
sub _structure_generate {
  my $self = shift;
  my ($items, $path, $delimiter) = @_;

  $path //= '';
  $delimiter //= '';

  foreach my $item (@{$items}) {
    $item->{name} =~ s/\s+/_/g;
    $item->{name} = lc($item->{name});

    if (!$item->{item}) {
      $self->{preview} .= "$delimiter$item->{name} (request)\n";
      $self->_schemas_generate($item) if ($self->{import});
    }
    else {
      next if (!scalar(@{$item->{item}}));

      $self->{preview} .= "$delimiter$item->{name}\n";
      $self->_folders_create($item, "$path$item->{name}/") if ($self->{import});
      $self->_structure_generate($item->{item}, "$path$item->{name}/", "$delimiter  ");
    }
  }

  return 1;
}

#**********************************************************
=head2 _folders_create($item, $full_path) create folders

  Arguments
    $item: obj      - folder info
    $full_path: str - path of folder from postman

=cut
#**********************************************************
sub _folders_create {
  my $self = shift;
  my ($item, $full_path) = @_;

  my @paths = $full_path =~ /([^\/]+)/gm;
  my $module_name = ucfirst(shift @paths);

  $self->{tests_path} = '';
  my $module_path = $self->{base_dir} . 'Abills/modules/' . $module_name;

  if (-d $module_path) {
    unshift(@paths, 't', 'schemas', $self->{type});

    $self->{tests_path} = $module_path;
  }
  else {
    if (!-d "$self->{base_dir}t/Api/$module_name") {
      print "Module $module_name not exists. Full module path - $module_path\n";
      print "Do you want save tests in $self->{base_dir}t/Api/?\n";
      print "Apply? (y/N): ";
      chomp(my $choice = <STDIN>);

      return 0 if (lc($choice) ne 'y');
    }

    unshift(@paths, $module_name, 'schemas', $self->{type});

    $self->{tests_path} = "$self->{base_dir}t/Api";
  }

  foreach my $path (@paths) {
    if (!-d "$self->{tests_path}/$path") {
      $self->_folder_create("$self->{tests_path}/$path");
    }

    $self->{tests_path} .= "/$path";
  }

  $self->_folder_create_id($item, $self->{tests_path});

  return 1;
}

#**********************************************************
=head2 _folders_create($path) create folder

  Arguments
    $path: str - path where create folder

=cut
#**********************************************************
sub _folder_create {
  my $self = shift;
  my ($path) = @_;

  print "Folder not exists. $path\n";

  if (mkdir $path) {
    print "Folder created\n";
  }
  else {
    print "Skip. Folder not created. $!\n";
    $self->{errors}++;
  }

  return 1;
}

#**********************************************************
=head2 _folder_create_id($path) create id of folder

  Arguments
    $item: obj - folder info
    $path: str - path where create folder

=cut
#**********************************************************
sub _folder_create_id {
  my $self = shift;
  my ($item, $path) = @_;

  my $file_path = "$path/.postman-id";

  my $id = '';
  if (-f $file_path) {
    $id = read_file($file_path);
    return 0 if (!defined($id));
  }

  return 1 if ($id && $id eq $item->{id});

  if ($id) {
    $id =~ s/\s\n\r//gm;
    print "Local folder id $file_path not equals to incoming folder id. Local id - $id. Incoming $item->{id}\n";
    print "Do you want change folder id to $item->{id}?\n";
    print "Apply? (y/N): ";

    chomp(my $choice = <STDIN>);

    if (lc($choice) eq 'y') {
      write_to_file($file_path, $item->{id});
    }
  }
  else {
    write_to_file($file_path, $item->{id});
  }

  return 1;
}

#**********************************************************
=head2 _schemas_generate($request) generate schemas

  Arguments
    $request: str - request object from postman

=cut
#**********************************************************
sub _schemas_generate {
  my $self = shift;
  my ($request) = @_;

  my $path = $self->{tests_path};

  if (!$self->{import}) {
    return 0;
  }
  elsif (!$path) {
    print "ERROR. Unknown path for request $request->{name}. Skip generate schemas.\n";
    $self->{errors}++;
    return 0;
  }
  elsif (!-d $path) {
    print "ERROR. Not exists path for request $request->{name} $path. Skip generate schemas. Skip generate schemas.\n";
    $self->{errors}++;
    return 0;
  }

  my $request_schema = $Schemas->generate_request_schema($request);
  my $response_schema = $Schemas->generate_response_schema($request);

  my $request_schema_json = $json->encode($request_schema);
  my $response_schema_json = $json->encode($response_schema);

  $self->_schema_check('request', lc($request_schema->{name}), $request_schema, $request_schema_json);
  $self->_schema_check('schema', lc($request_schema->{name}), $response_schema, $response_schema_json);

  if ($self->{debug} > 2) {
    $self->{preview} .= "\nREQUEST SCHEMA\n$request_schema_json\nRESPONSE_SCHEMA\n$response_schema\n"
  }

  return 1;
}

#**********************************************************
=head2 _schema_check($name, $folder, $schema, $content) check schemas

  Arguments
    $name: str    - name of schema
    $schema: obj  - hash of schemas
    $content: str - json str of schema

=cut
#**********************************************************
sub _schema_check {
  my $self = shift;
  my ($name, $folder, $schema, $content) = @_;

  return if (!$self->{import});

  if (!-d "$self->{tests_path}/$folder") {
    $self->_folder_create("$self->{tests_path}/$folder");
  }

  my $schema_path = "$self->{tests_path}/$folder/$name.json";

  my $local_schema_json = '';
  if (-f $schema_path) {
    $local_schema_json = read_file($schema_path);
    return 0 if (!defined($local_schema_json));

    my $local_schema = eval {decode_json($local_schema_json)};
    if ($@) {
      print "Failed decode json of local schema. Path $schema_path\n";
      $self->_save_schema($schema_path, $content);
      $@ = undef;
      return 0;
    }
    my $result = Compare($local_schema, $schema);

    return 1 if ($result);

    print "Local schema not the same from Postman.\n";
    $self->_save_schema($schema_path, $content);
  }
  else {
    $self->_save_schema($schema_path, $content);
  }

  return 1;
}

#**********************************************************
=head2 read_file($path) read file content

  Arguments
    $path: str    - path where save schema
    $content: str - json str of schema

=cut
#**********************************************************
sub _save_schema {
  my $self = shift;
  my ($path, $content) = @_;

  if (-f $path) {
    return 1 if ($self->{new_schemas});
    print "Do you want overwrite local schema from Postman schema?\n";
  }
  else {
    print "Do you want save remote Postman schema?\n";
  }

  print "Apply? (y/N): ";

  chomp(my $choice = <STDIN>);

  return 0 if (lc($choice) ne 'y');

  write_to_file($path, $content);

  return 1;
}

1;
