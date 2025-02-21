package Expert::Api::user::Faqs;

=head1 NAME

  Equipment Onu

  Endpoints:
    /user/equipment/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Expert::db::Expert;

my Expert $Expert;
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

  $Expert = Expert->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_equipment($path_params, $query_params)

  Endpoint GET /user/equipment/

=cut
#**********************************************************
sub get_user_expert_faqs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Expert->faq_list({
    TITLE     => '_SHOW',
    BODY      => '_SHOW',
    TYPE      => '_SHOW',
    ICON      => '_SHOW',
    PRIORITY  => '_SHOW',
    SORT      => $query_params->{SORT} // 'priority',
    DESC      => $query_params->{DESC} // 'DESC',
    COLS_NAME => 1,
  });
}

1;
