package Maps::Import;

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Maps;
use Maps::Auxiliary;

use Abills::Base qw/in_array/;
use Maps::Shared qw/LAYER_ID_BY_NAME/;

#**********************************************************
=head2 new($db, $admin, $conf, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    lang    => $attr->{lang} || {},
    html    => $attr->{html} || undef,
    libpath => $attr->{libpath},
  };
  bless($self, $class);

  $self->{Maps}      = Maps->new($db, $admin, $conf);
  $self->{Auxiliary} = Maps::Auxiliary->new($db, $admin, $conf, { HTML => $self->{html}, LANG => $self->{lang} });
  $self->{Errors}    = Control::Errors->new($db, $admin, $conf, { lang => $attr->{lang}, module => 'Maps' });

  return $self;
}

#**********************************************************
=head2 _start_transaction() - Initialize transaction manager

  Arguments:
    None

  Returns:
    HASHREF
      {
        rollback => sub { ... }, # Rollback transaction if needed
        commit   => sub { ... }  # Commit transaction if needed
      }

  Example:
    my $transaction = $self->_start_transaction();
    $transaction->{commit}->();

=cut
#**********************************************************
sub _start_transaction {
  my ($self) = @_;

  my $db = $self->{Maps}{db}{db};
  my $manage_transaction = !$self->{Maps}{db}{TRANSACTION};

  if ($manage_transaction) {
    $db->{AutoCommit} = 0;
    $self->{Maps}{db}{TRANSACTION} = 1;
  }

  return {
    rollback => sub {
      return if !$manage_transaction;

      delete $self->{Maps}{db}{TRANSACTION};
      $db->rollback();
      $db->{AutoCommit} = 1;
    },
    commit => sub {
      return if !$manage_transaction;

      delete $self->{Maps}{db}{TRANSACTION};
      $db->commit();
      $db->{AutoCommit} = 1;
    }
  };
}

#**********************************************************
=head2 maps_import($attr) - Import maps data

  Arguments:
    $attr   - Extra attributes
       LIST   - List of map elements for import

  Returns:
   TRUE or hashref with error information

  Example:

    maps_import({
      LIST => [
        { TYPE => 'cable', ... },
        { TYPE => 'well',  ... }
      ]
    });

=cut
#**********************************************************
sub maps_import {
  my ($self, $attr) = @_;

  my $transaction = $self->_start_transaction();

  return if (!$attr->{LIST});

  foreach my $line (@{$attr->{LIST}}) {
    next if (!$line->{TYPE});

    if ($line->{TYPE} eq 'cable' || $line->{TYPE} eq 'well') {
      my $result = $self->_maps_cablecat_import($line);

      if ($result->{errno}) {
        $transaction->{rollback}->();
        return $result;
      }
    }
  }

  $transaction->{commit}->();
  return 1;
}

#**********************************************************
=head2 _maps_cablecat_import($line) - Import Cablecat map element

  Arguments:
    $line   - Map element data
       TYPE   - Element type (cable or well)

  Returns:
   Hashref with import result or empty hash

  Example:

    $self->_maps_cablecat_import({
      TYPE => 'cable'
    });

=cut
#**********************************************************
sub _maps_cablecat_import {
  my ($self, $line) = @_;

  if (!exists $self->{Cablecat}) {
    if (!in_array('Cablecat', \@main::MODULES) || ($self->{admin}{MODULES} && !$self->{admin}{MODULES}{Cablecat})) {
      $self->{Cablecat} = undef;
      return;
    }

    eval {require Cablecat;};

    if ($@) {
      $self->{Cablecat} = undef;
      return;
    }
    Cablecat->import();
    $self->{Cablecat} = Cablecat->new($self->{db}, $self->{admin}, $self->{conf});
  }

  return if (!$self->{Cablecat} || !$line->{TYPE});

  if ($line->{TYPE} eq 'cable') {
    return $self->_cablecat_cable_import($line);
  }

  if ($line->{TYPE} eq 'well') {
    return $self->_cablecat_well_import($line);
  }

  return {};
}

#**********************************************************
=head2 _cablecat_cable_import($line) - Import Cablecat cable

  Arguments:
    $line   - Cable data
       GEOMETRY   - Geometry information
         TYPE        - Geometry type (polyline)
         COORDINATES - List of polyline points

  Returns:
   Hashref with error information or empty hash

  Example:

    $self->_cablecat_cable_import({
      TYPE     => 'cable',
      GEOMETRY => {
        TYPE        => 'polyline',
        COORDINATES => [ [30.1, 50.4], [30.2, 50.5] ]
      }
    });

=cut
#**********************************************************
sub _cablecat_cable_import {
  my ($self, $line) = @_;

  if (!$line->{GEOMETRY} || !$line->{GEOMETRY}{COORDINATES} || !$line->{GEOMETRY}{TYPE} || $line->{GEOMETRY}{TYPE} ne 'polyline') {
    return $self->{Errors}->throw_error(1380001);
  }

  my $cable_id = $self->{Cablecat}->cables_add($line);
  if ($self->{Cablecat}{errno}) {
    return {
      errno  => $self->{Cablecat}{errno},
      errstr => $self->{Cablecat}{errstr}
    };
  }

  my $external_object_id = $self->{Auxiliary}->maps_add_external_object(7, $line);
  return $self->{Errors}->throw_error(1380001) if (!$external_object_id);

  $self->{Cablecat}->cables_change({ ID => $cable_id, POINT_ID => $external_object_id });
  if ($self->{Cablecat}{errno}) {
    return {
      errno  => $self->{Cablecat}{errno},
      errstr => $self->{Cablecat}{errstr}
    };
  }

  $self->{Maps}->polylines_add({ OBJECT_ID => $external_object_id, LAYER_ID => 10 });
  if ($self->{Maps}{errno}) {
    return {
      errno  => $self->{Maps}{errno},
      errstr => $self->{Maps}{errstr}
    };
  }

  my $polyline_id = $self->{Maps}->{INSERT_ID};
  my @points = ();
  foreach my $point (@{$line->{GEOMETRY}{COORDINATES}}) {
    next if (!$point || ref $point ne 'ARRAY');

    push @points, { COORDX => $point->[0], COORDY => $point->[1] };
  }

  if ($polyline_id) {
    $self->{Maps}->polyline_points_add({
      POLYLINE_ID => $polyline_id,
      POINTS      => \@points
    });

    if ($self->{Maps}{errno}) {
      return {
        errno  => $self->{Maps}{errno},
        errstr => $self->{Maps}{errstr}
      };
    }
  }

  return {};
}

#**********************************************************
=head2 _cablecat_well_import($line) - Import Cablecat well

  Arguments:
    $line   - Well data
       GEOMETRY   - Geometry information
         TYPE        - Geometry type (point)
         COORDINATES - Point coordinates

  Returns:
   Hashref with error information or empty hash

  Example:

    $self->_cablecat_well_import({
      TYPE     => 'well',
      GEOMETRY => {
        TYPE        => 'point',
        COORDINATES => [30.1, 50.4]
      }
    });

=cut
#**********************************************************
sub _cablecat_well_import {
  my ($self, $line) = @_;

  if (!$line->{GEOMETRY} || !$line->{GEOMETRY}{COORDINATES} || !$line->{GEOMETRY}{TYPE} || $line->{GEOMETRY}{TYPE} ne 'point') {
    return $self->{Errors}->throw_error(1380001);
  }

  my $external_object_id = $self->{Auxiliary}->maps_add_external_object(1, {
    COORDX => $line->{GEOMETRY}{COORDINATES}[0],
    COORDY => $line->{GEOMETRY}{COORDINATES}[1]
  });
  return $self->{Errors}->throw_error(1380001) if (!$external_object_id);

  $self->{Cablecat}->wells_add({ %$line, POINT_ID => $external_object_id });
  if ($self->{Cablecat}{errno}) {
    return {
      errno  => $self->{Cablecat}{errno},
      errstr => $self->{Cablecat}{errstr}
    };
  }

  return {};
}

1;