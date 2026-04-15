package Abills::Experimental::Variable_listener;
=head1 NAME

  Abills::Experimental::Variable_listener - Module for listening variable changes through all the code (debug)

=head1 SYNOPSIS

  use Abills::Experimental::Variable_listener;

  # Hash - track key/value changes
  tie %COOKIES, 'Abills::Experimental::Variable_listener';

  # Scalar - track read/write
  tie $config_value, 'Abills::Experimental::Variable_listener', $initial_value;

  # Array - track element changes
  tie @params, 'Abills::Experimental::Variable_listener';

=head1 DESCRIPTION

  Logs all variable modifications to /tmp/variable_listener.log for debugging.
  Supports TIEHASH, TIESCALAR, TIEARRAY.

=cut

use strict;
use warnings FATAL => 'all';

use Scalar::Util qw(reftype);
use Abills::Base qw(_bp _caller);

#**********************************************************
=head2 TIESCALAR($class, $value)

=cut
#**********************************************************
sub TIESCALAR {
  my ($class, $value) = @_;
  my $self = defined $value ? \$value : \undef;
  bless $self, $class;

  my $caller = _caller({ NO_PRINT => 1 });
  _bp('tie scalar', {
    initial_value => $value,
    caller        => $caller,
  }, { TO_FILE => '/tmp/variable_listener.log' });

  return $self;
}

#**********************************************************
=head2 TIESCALAR($class, @init)

=cut
#**********************************************************
sub TIEARRAY {
  my ($class, @init) = @_;
  my $self = bless \@init, $class;

  my $caller = _caller({ NO_PRINT => 1 });
  _bp('tie array', {
    initial_size => scalar @init,
    caller       => $caller,
  }, { TO_FILE => '/tmp/variable_listener.log' });

  return $self;
}

#**********************************************************
=head2 FETCH($self)

=cut
#**********************************************************
sub FETCH {
  my $self = shift;
  my $type = reftype($self) || '';

  if ($type eq 'SCALAR') {
    my $val = $$self;
    _bp('scalar fetch', { value => $val, caller => _caller({ NO_PRINT => 1 }) }, { TO_FILE => '/tmp/variable_listener.log' });
    return $val;
  }
  elsif ($type eq 'ARRAY') {
    my $idx = shift;
    my $val = $self->[$idx];
    _bp('array fetch', { index => $idx, value => $val, caller => _caller({ NO_PRINT => 1 }) }, { TO_FILE => '/tmp/variable_listener.log' });
    return $val;
  }
  else {
    my $key = shift;
    return $self->{$key};
  }
}

#**********************************************************
=head2 STORE($self)

=cut
#**********************************************************
sub STORE {
  my $self = shift;
  my $type = reftype($self) || '';

  if ($type eq 'SCALAR') {
    my $value = shift;
    my $old   = $$self;
    _bp('scalar store', { old_value => $old, new_value => $value, caller => _caller({ NO_PRINT => 1 }) }, { TO_FILE => '/tmp/variable_listener.log' });
    $$self = $value;
    return;
  }
  elsif ($type eq 'ARRAY') {
    my ($idx, $value) = @_;
    my $old = $self->[$idx];
    _bp('array store', { index => $idx, old_value => $old, new_value => $value, caller => _caller({ NO_PRINT => 1 }) }, { TO_FILE => '/tmp/variable_listener.log' });
    $self->[$idx] = $value;
    return;
  }
  elsif ($type eq 'HASH') {
    my ($key, $value) = @_;
    _bp('update', { key => $key, value => $value, old_value => $self->{$key}, caller => _caller({ NO_PRINT => 1 }) }, { TO_FILE => '/tmp/variable_listener.log' });
    $self->{$key} = $value;
  }
}

#**********************************************************
=head2 FETCHSIZE($self)

=cut
#**********************************************************
sub FETCHSIZE {
  my $self = shift;
  return scalar @$self;
}

#**********************************************************
=head2 STORESIZE($self, $count)

=cut
#**********************************************************
sub STORESIZE {
  my ($self, $count) = @_;
  my $old_size = scalar @$self;

  my $caller = _caller({ NO_PRINT => 1 });
  _bp('array storesize', {
    old_size => $old_size,
    new_size => $count,
    caller   => $caller,
  }, { TO_FILE => '/tmp/variable_listener.log' });

  $#{$self} = $count - 1;
}

#**********************************************************
=head2 CLEAR($self)

=cut
#**********************************************************
sub CLEAR {
  my $self = shift;
  my $type = reftype($self) || '';

  if ($type eq 'ARRAY') {
    my $old = [ @$self ];
    _bp('array clear', { old_content => $old, caller => _caller({ NO_PRINT => 1 }) }, { TO_FILE => '/tmp/variable_listener.log' });
    @$self = ();
    return;
  }

  # HASH
  _bp('clear', { caller => _caller({ NO_PRINT => 1 }) }, { TO_FILE => '/tmp/variable_listener.log' });
  %$self = ();
}

#**********************************************************
=head2 PUSH($self)

=cut
#**********************************************************
sub PUSH {
  my $self = shift;
  my @vals = @_;

  my $caller = _caller({ NO_PRINT => 1 });
  _bp('array push', {
    values => \@vals,
    caller => $caller,
  }, { TO_FILE => '/tmp/variable_listener.log' });

  push @$self, @vals;
}

#**********************************************************
=head2 PUSH($self)

=cut
#**********************************************************
sub POP {
  my $self = shift;
  my $val  = pop @$self;

  my $caller = _caller({ NO_PRINT => 1 });
  _bp('array pop', {
    value  => $val,
    caller => $caller,
  }, { TO_FILE => '/tmp/variable_listener.log' });

  return $val;
}

#**********************************************************
=head2 SHIFT($self)

=cut
#**********************************************************
sub SHIFT {
  my $self = shift;
  my $val  = shift @$self;

  my $caller = _caller({ NO_PRINT => 1 });
  _bp('array shift', {
    value  => $val,
    caller => $caller,
  }, { TO_FILE => '/tmp/variable_listener.log' });

  return $val;
}

#**********************************************************
=head2 UNSHIFT($self)

=cut
#**********************************************************
sub UNSHIFT {
  my $self = shift;
  my @vals = @_;

  my $caller = _caller({ NO_PRINT => 1 });
  _bp('array unshift', {
    values => \@vals,
    caller => $caller,
  }, { TO_FILE => '/tmp/variable_listener.log' });

  unshift @$self, @vals;
}

#**********************************************************
=head2 SPLICE($self)

=cut
#**********************************************************
sub SPLICE {
  my $self = shift;
  my $offset = shift || 0;
  my $len    = shift;
  my @vals   = @_;

  my $old = [ splice @$self, $offset, $len, @vals ];

  my $caller = _caller({ NO_PRINT => 1 });
  _bp('array splice', {
    offset    => $offset,
    length    => $len,
    new_vals  => \@vals,
    removed   => $old,
    caller    => $caller,
  }, { TO_FILE => '/tmp/variable_listener.log' });

  return @$old;
}

#**********************************************************
=head2 TIEHASH($self)

=cut
#**********************************************************
sub TIEHASH {
  my $class = shift;
  my %hash = @_;

  _bp('tie hash', { caller => _caller({ NO_PRINT => 1 }) }, { TO_FILE => '/tmp/variable_listener.log' });

  return bless \%hash, $class;
}

#**********************************************************
=head2 DELETE($self, $key)

=cut
#**********************************************************
sub DELETE {
  my ($self, $key) = @_;
  _bp('hash delete', { key => $key, caller => _caller({ NO_PRINT => 1 }) }, { TO_FILE => '/tmp/variable_listener.log' });
  delete $self->{$key};
}

#**********************************************************
=head2 EXISTS($self, $key)

=cut
#**********************************************************
sub EXISTS {
  my ($self, $key) = @_;
  return exists $self->{$key};
}

#**********************************************************
=head2 FIRSTKEY($self, $key)

=cut
#**********************************************************
sub FIRSTKEY {
  my ($self) = @_;
  my $a = keys %$self;
  return each %$self;
}

#**********************************************************
=head2 FIRSTKEY($self, $key)

=cut
#**********************************************************
sub NEXTKEY {
  my ($self, $lastkey) = @_;
  return each %$self;
}

1;
