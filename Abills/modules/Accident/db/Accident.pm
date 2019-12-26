package Accident;
=head1 NAME

  Accident - module for Accident log

=head1 SYNOPSIS

  use Accident;
  my $Accident = Accident->new($db, $admin, \%conf);

=cut

use strict;
use parent qw(dbcore);

my ($admin, $CONF);

#*******************************************************************

=head2 new()

=cut

#*******************************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head2 add() - Add element accident log tables

  Arguments:
     attr - form attribute

  Returns:
    self - result operation

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('accident_log', $attr, {
    AL_DATE => 'NOW()'
  });

  return $self;
}

#**********************************************************
=head2  del() - Delete accident log tables

 Arguments:
     attr - form attribute

 Returns:
    self - result operation

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('accident_log', undef, $attr);

  return $self->{result};
}

#**********************************************************
=head2 change_element($attr) -  Change element

 Arguments:
     attr - form attribute date

 Returns:
    self - result operation

=cut
#**********************************************************
sub change_element {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'AL_ID',
      TABLE        => 'accident_log',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 list ($attr) - list for accident log

 Arguments:
     AL_ID              - Accident id
     AL_PRIORITY        - Accident priority status
     AL_DATE            - Date accident
     AL_STATUS          - Status accident
     AL_NAME            - Accident name
     AL_DESC            - Description
     ADDRESS_ID         - Districts accident
     FROM_DATE          -
     TO_DATE            -
     AL_AID             - Administration id
     AL_END_TIME        - Date end work
     AL_REALY_TIME      - Date end realy work
     STREET             - Street accident
     TYPE_ID            - Address type
     SKIP_STATUS        - Skip status
     BUILD_ID           - Build id
     STREET_ID          - Streat id
     DISTRICT_ID        - District id

 Returns:
    list

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if ($attr->{SKIP_STATUS}) {
    push @WHERE_RULES, "al.al_status != $attr->{SKIP_STATUS}";
  }

  if ($attr->{BUILD_ID} && $attr->{STREET_ID} && $attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "(ad.type_id = 3 AND ad.address_id = $attr->{STREET_ID})
                        OR (ad.type_id = 1 AND ad.address_id = $attr->{DISTRICT_ID})
                        OR (ad.type_id = 4 AND ad.address_id = $attr->{BUILD_ID})";
  }
  elsif ($attr->{STREET_ID} && $attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "(ad.type_id = 3 AND ad.address_id = $attr->{STREET_ID})
                        OR (ad.type_id = 1 AND ad.address_id = $attr->{DISTRICT_ID})";
  }
  elsif ($attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "ad.type_id = 1 AND ad.address_id = $attr->{DISTRICT_ID}";
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'AL_ID',                      'INT',    'al.al_id',         1 ],
      [ 'AL_DATE',                    'DATE',   'al.al_date',       1 ],
      [ 'AL_NAME',                    'STR',    'al.al_name',       1 ],
      [ 'AL_DESC',                    'STR',    'al.al_desc',       1 ],
      [ 'AL_PRIORITY',                'INT',    'al.al_priority',   1 ],
      [ 'AL_AID',                     'INT',    'al.al_aid',        1 ],
      [ 'AL_STATUS',                  'INT',    'al.al_status',     1 ],
      [ 'ADDRESS_ID',                 'INT',    'ad.address_id',    1 ],
      [ 'AL_END_TIME',                'DATE',   'al.al_end_time',   1 ],
      [ 'AL_REALY_TIME',              'DATE',   'al.al_realy_time', 1 ],
      [ 'TYPE_ID',                    'INT',    'ad.type_id',       1 ],
      [ 'FROM_DATE|TO_DATE',          'DATE',   "DATE_FORMAT(al.al_date, '%Y-%m-%d')", ],
    ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  $self->query("(SELECT $self->{SEARCH_FIELDS} al.al_id
      FROM accident_log al
   LEFT JOIN admins a ON al.al_aid = a.aid
   LEFT JOIN districts di ON di.id
   LEFT JOIN accident_address ad ON ad.ac_id = al.al_id
   LEFT JOIN builds b ON b.id
    $WHERE
    ORDER BY $SORT $DESC)
    UNION
    (SELECT $self->{SEARCH_FIELDS} al.al_id
      FROM accident_log al
   LEFT JOIN admins a ON al.al_aid = a.aid
   LEFT JOIN districts di ON di.id
   RIGHT JOIN accident_address ad ON ad.ac_id = al.al_id
   LEFT JOIN builds b ON b.id
    $WHERE
    GROUP BY al.al_id
 HAVING AVG(ad.type_id != 4)
    ORDER BY $SORT $DESC);",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 change_address ($attr) - change accident address

 Arguments:

 Returns:

=cut
#**********************************************************
sub change_address {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'AC_ID',
      TABLE        => 'accident_address',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 address_add ($attr) - add accident address

 Arguments:

 Returns:

=cut
#**********************************************************
sub address_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('accident_address', $attr);

  return $self;
}

#**********************************************************
=head2 address_del ($attr) - del accident address

 Arguments:

 Returns:

=cut
#**********************************************************
sub address_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM accident_address WHERE ac_id = ?", 'do', {
    Bind => [ $attr->{ID} ]
  });

  return $self->{result};
}

1;