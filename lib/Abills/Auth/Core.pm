package Abills::Auth::Core;

=head1 NAME

  Authe core

=cut

use strict;
use warnings FATAL => 'all';


#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  my $auth_type = $attr->{AUTH_TYPE} || '';
  my $conf      = $attr->{CONF};
  my $self      = { conf => $conf };

  bless($self, $class);
  my $name = "Abills::Auth::$auth_type";
  eval " require $name ";

  if(! $@) {
   $name->import();
   our @ISA  = ($name);
  }
  else {
    print "Content-Type: text/html\n\n";
    print $@;
  }

  return $self;
}

#**********************************************************
=head2 check_access($attr)

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr)=@_;

  return $self->SUPER::check_access($attr);
}

#**********************************************************
=head2 get_info($attr)

  Arguments:
   CLIENT_ID

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub get_info {
  my $self = shift;
  my ($attr)=@_;

  return $self->SUPER::get_info($attr);
}


1;
