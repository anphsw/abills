package Api::Controllers::Admin::Global;

=head1 NAME

  ADMIN API Global

  Endpoints:
    /global/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;

my Control::Errors $Errors;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_global($path_params, $query_params)

  Endpoint POST /global/

=cut
#**********************************************************
sub post_global {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my DBI $db = $self->{db}->{db};
  $db->{AutoCommit} = 0;
  $self->{db}->{TRANSACTION} = 1;

  if (!$query_params->{REQUESTS} || ref $query_params->{REQUESTS} ne 'ARRAY') {
    return {
      errno  => 10154,
      errstr => 'No field requests',
    };
  }

  my %results = (
    result  => 'OK',
    results => [],
  );

  my $id = -1;
  my %new_user;

  require Abills::Api::Handle;
  Abills::Api::Handle->import();
  my $handle = Abills::Api::Handle->new($self->{db}, $self->{admin}, $self->{conf}, {
    html           => $self->{html},
    lang           => $self->{lang},
    direct         => 1
  });

  foreach my $request (@{$query_params->{REQUESTS}}) {
    ++$id;

    if ($id == 20) {
      push @{$results{results}}, {
        url        => $request->{URL} || '',
        response   => {},
        successful => 'false',
        errno      => 10155,
        errstr     => 'Fatal error, not executed. Limit of execution equals 20',
        id         => $id,
      };
      last;
    }

    # handling routes for new user registration
    if (%new_user && $request->{URL} =~ /{UID}/) {
      $request->{URL} =~ s/{UID}/$results{uid}/;

      # handle params sent like "billId": "{BILL_ID}"
      if ($request->{BODY} && ref $request->{BODY} eq 'HASH') {
        foreach my $key (keys %{$request->{BODY}}) {
          if ($request->{BODY}->{$key} && $request->{BODY}->{$key} =~ /((?<=\{)[a-zA-z0-9_]+(?=\}))/g) {
            my $value = $1 || '';
            my $new_value = $new_user{$value} || '';
            $request->{BODY}->{$key} =~ s/{$value}/$new_value/g;
          }
        }
      }
    }

    if ($results{errno}) {
      push @{$results{results}}, {
        url        => $request->{URL} || '',
        response   => {},
        successful => 'false',
        errno      => 10149,
        errstr     => 'Fatal error, not executed',
        id         => $id,
      };
      next;
    }

    # verify url and method valid or not
    if (!$request->{URL} || ref $request->{URL} ne '' || !$request->{METHOD} || ref $request->{METHOD} ne '') {
      $results{result} = 'Not valid method or url parameter';
      $results{errno} = 10150;
      push @{$results{results}}, {
        url        => $request->{URL},
        response   => {},
        successful => 'false',
        errno      => 10150,
        errstr     => 'Not valid method or url parameter',
        id         => $id,
      };
      next;
    }

    my ($result, $status) = $handle->api_call({
      PATH   => $request->{URL},
      METHOD => $request->{METHOD},
      PARAMS => $request->{BODY},
    });

    # catch error if it present
    if ($result && ref $result eq 'HASH' && ($result->{errno} || $result->{error})) {
      $results{result} = 'Execution failed';
      $results{errno} = $result->{errno} || $result->{error};
      push @{$results{results}}, {
        url        => $request->{URL},
        response   => $result,
        successful => 'false',
        id         => $id,
      };
      next;
    }

    # handle user registration
    if ($request->{METHOD} eq 'POST' && $request->{URL} eq '/users/') {
      $results{uid} = $result->{UID};
      require Users;
      Users->import();
      my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
      $Users->info($results{uid});
      $Users->pi({ UID => $results{uid} });
      %new_user = %$Users;
    }

    push @{$results{results}}, {
      response   => $result || '',
      status     => $status || 200,
      url        => $request->{URL},
      method     => $request->{METHOD},
      successful => 'true',
      id         => $id,
    };
  }

  if ($results{errno}) {
    $db->rollback();
  }
  else {
    $db->commit();
  }

  $db->{AutoCommit} = 1;

  return \%results;
}

1;
