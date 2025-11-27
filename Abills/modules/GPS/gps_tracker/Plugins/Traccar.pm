package Traccar;
use warnings FATAL => 'all';
use strict;

use POSIX qw(strftime);

=head1 NAME

Abstract tracker


=head1 VERSION

  Version 0.2

=head1 SYNOPSIS


=cut

use parent qw(dbcore);

# Singleton reference;
my $instance;


=head2 new

Instantiation of singleton db object

=cut
sub new {

  unless (defined $instance) {
    my $class = shift;
    my $db = shift;
    my ($CONF) = @_;
    my $self = {};
    bless($self, $class);

    $instance = $self;
    #    $instance->{debug} = 1;
  }

  return $instance;
}

1;