package Conf;

=head1 NAME

  Config

=cut

use strict;
use main;
our (@EXPORT_OK, %EXPORT_TAGS);
use Exporter;
our @ISA = ('main', 'Exporter');

our $VERSION = 2.00;

our @EXPORT = qw(
  config_list
);

my $admin;
my $CONF;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = 'Config';
  my $self = {};

  bless($self, $class);
  $self->{db}=$db;
  $self->{admin}=$admin;
  $self->{conf}=$CONF;

  $self->query2("SELECT param, value FROM config WHERE domain_id = ?",
    undef,
    { Bind => [
      $admin->{DOMAIN_ID} || 0
       ]});

  foreach my $line (@{ $self->{list} }) {
    $CONF->{$line->[0]}=$line->[1];
  }

  return $self;
}


#**********************************************************
=head2 config_list($attr) - Config option list

  Arguments:
    $attr
      PARAM
      VALUE
      DOMAIN_ID
      CONF_ONLY - do not show total

  Returns:
    \@list

=cut
#**********************************************************
sub config_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my @WHERE_RULES = ();

  if ($attr->{PARAM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PARAM}, 'STR', 'param') };
  }

  if ($attr->{VALUE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{VALUE}, 'STR', 'value') };
  }

  push @WHERE_RULES, 'domain_id=\'' . ($admin->{DOMAIN_ID} || $attr->{DOMAIN_ID} || 0) . '\'';

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT param, value FROM config $WHERE ORDER BY $SORT $DESC", undef, $attr);
  my $list = $self->{list};

  if (!$attr->{CONF_ONLY} || $self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total FROM config $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 config_info($attr) - Get config information

  Arguments:
    $attr
      PARAM
      DOMAIN_ID

=cut
#**********************************************************
sub config_info {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DOMAIN_ID} = 0 if (!$attr->{DOMAIN_ID});

  $self->query2("SELECT param, value, domain_id FROM config WHERE param= ? AND domain_id= ? ;",
    undef,
    { INFO => 1,
      Bind => [
      $attr->{PARAM},
      $attr->{DOMAIN_ID} ]
    });

  return $self;
}

#**********************************************************
=head2 config_change($param, $attr)

=cut
#**********************************************************
sub config_change {
  my $self = shift;
  my ($param, $attr) = @_;

  #my %FIELDS = (
  #  PARAM     => 'param',
  #  value      => 'value',
  #  DOMAIN_ID => 'domain_id'
  #);

  $self->changes2(
    {
      CHANGE_PARAM => 'PARAM',
      TABLE        => 'config',
#      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->config_info({ PARAMS => $param, DOMAIN_ID => $attr->{DOMAIN_ID} }),
      DATA         => $attr,
      %$attr
    }
  );

  return $self;
}

#**********************************************************
=head2 config_add($attr)

  Arguments:
    $attr - hash_ref
      PARAM   -
      VALUE   -
      REPLACE -

  Returns:
    Conf instance

=cut
#**********************************************************
sub config_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('config', $attr, { REPLACE => ($attr->{REPLACE}) ? 1 : undef });

  return $self;
}

#**********************************************************
=head2 config_del($id)

=cut
#**********************************************************
sub config_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('config', undef,  { param => $id });

  return $self;
}

#**********************************************************
=head2 add() - Add config variables

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('config_variables', $attr);

  return $self;
}

#**********************************************************
=head2 del($id) - Del config variables

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('config_variables', undef, {  param=> $id });

  return $self;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'PARAM',
      TABLE        => 'config_variables',
      DATA         => $attr
    }
  );

  return $self;
}


#**********************************************************
=head2 info($attr)

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT * FROM config_variables
    WHERE param= ? ;",
   undef,
   { INFO => 1,
     Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ($attr->{COMMENTS}) {
    $attr->{COMMENTS}='*'. $attr->{COMMENTS}. '*';
  }

  my $WHERE = $self->search_former($attr, [
      ['PARAM',     'STR',  'param',      ],
      ['COMMENTS',  'STR',  'comments',   ],
    ],
    { WHERE => 1,
    }
  );

  $self->query2("SELECT *
        FROM config_variables
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0) {
    $self->query2("SELECT count(*) AS total FROM config_variables $WHERE",
      undef, { INFO => 1 });
  }

  return $list;
}


1
