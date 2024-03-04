package Abills::Api::Postman::Schemas;

use strict;
use warnings FATAL => 'all';

use JSON qw(decode_json);

#**********************************************************
=head2 new($db, $attr)

  Public define props

  Local define props

    errors: int     - count of errors

=cut
#**********************************************************
sub new {
  my ($class) = @_;

  my $self = {
    errors => 0,
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 generate_request_schema($item) generate request schemas

  Arguments
    $item: str - request object from postman

=cut
#**********************************************************
sub generate_request_schema {
  my $self = shift;
  my ($item) = @_;

  if (ref $item ne 'HASH') {
    print "Invalid and unknown request argument. Skip.\n";
    $self->{errors}++;
    return '';
  }

  my $request = $item->{request};

  $item->{name} =~ s/\s/_/gm;
  my $request_schema = {
    method    => $request->{method},
    postmanId => $item->{id},
    name      => uc($item->{name}),
  };

  $request_schema->{path} = join('/', @{$request->{url}->{path}});

  if ($request_schema->{path} =~ /^(.*[^\/])?$/) {
    $request_schema->{path} .= '/';
  }

  if ($request->{url}->{query} && scalar($request->{url}->{query})) {
    $request_schema->{params} = $request->{url}->{query}->[0];
  }

  if ($request->{body} && $request->{body}->{mode} && $request->{body}->{mode} eq 'raw') {
    my $body = eval {decode_json($request->{body}->{raw})};
    $@ = undef;
    if ($@) {
      print "Not valid request body for $item->{name} $@.\n";
      $self->{errors}++;
      $@ = undef;
      return '';
    }
    $request_schema->{body} = $body;
  }

  return $request_schema;
}

#**********************************************************
=head2 generate_response_schema($item) generate response schemas

  Arguments
    $item: str - request object from postman

=cut
#**********************************************************
sub generate_response_schema {
  my $self = shift;
  my ($item, $export) = @_;

  return {} if (!$item || $item->{event});
  $export //= 0;
  my $events = $item->{event};

  if (!$events || !scalar(@{$events})) {
    print "No test for $item->{name}\n";
    $self->{errors}++;
    return {};
  }

  my $script;

  foreach my $event (@{$events}) {
    next if (!$event->{listen} || $event->{listen} ne 'test');
    $script = $event->{script};
    last;
  }

  if (!$script) {
    print "No test for $item->{name}\n";
    $self->{errors}++;
    return {};
  }

  my $str = join('', map { s/\R//g; $_ } @{$script->{exec}});
  my ($obj) = $str =~ /const\s+schema\s+=\s+(\{(?:[^{}]|(?1))*\})/gm;

  $@ = undef;
  my $schema = eval {decode_json($obj)};
  if ($@) {
    print "Not valid schema for $item->{name} $@. \nSchema: " . ($obj || '') . " \n\n";
    $self->{errors}++;
    $@ = undef;
    return {};
  }

  return $schema;
}

1;
