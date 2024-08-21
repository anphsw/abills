package Abills::Experimental::Variable_listener;
=head NAME

  Module for listening hash changes through all the code

  Example:
    use Abills::Experimental::Variable_listener;
    tie %COOKIES, 'Abills::Experimental::Variable_listener';

=cut

#TODO: add multiple support if will needed TIESCALAR and TIEARRAY
use strict;
use warnings FATAL => 'all';

use Abills::Base qw(_bp);

# sub TIESCALAR {
#   my $class = shift;
#   my $value = shift;
#   my $self = \$value;
#   bless $self, $class;
#   return $self;
# }

sub TIEHASH {
  my $class = shift;
  my %hash = @_;

  my $caller = _caller();

  _bp('tie hash', {
    caller => $caller
  }, { TO_FILE => '/tmp/variable_listener.log' });

  return bless \%hash, $class;
}

sub DELETE {
  my ($self, $key) = @_;
  my $caller = _caller();

  _bp('delete', {
    caller => $caller
  }, { TO_FILE => '/tmp/variable_listener.log' });

  delete $self->{$key};
}

sub CLEAR {
  my ($self) = @_;
  my $caller = _caller();

  _bp('clear', {
    caller => $caller
  }, { TO_FILE => '/tmp/variable_listener.log' });

  %$self = ();
}

sub EXISTS {
  my ($self, $key) = @_;
  return exists $self->{$key};
}

sub FIRSTKEY {
  my ($self) = @_;
  my $a = keys %$self;
  return each %$self;
}

sub NEXTKEY {
  my ($self, $lastkey) = @_;
  return each %$self;
}

sub FETCH {
  my $self = shift;
  my $key = shift;
  return $self->{$key};
}

sub STORE {
  my ($self, $key, $value) = @_;

  my $caller = _caller();

  _bp('update', {
    key       => $key,
    value     => $value,
    old_value => $self->{$key},
    caller    => $caller,
  }, { TO_FILE => '/tmp/variable_listener.log' });

  $self->{$key} = $value;
}

sub _caller {
  my $caller = qq{};
  my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash);
  my $i = 1;
  my @r = ();
  while (@r = caller($i)) {
    ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = @r;
    $caller .= "  $filename:$line $subroutine\n";
    $i++;
  }

  return $caller;
}

1;
