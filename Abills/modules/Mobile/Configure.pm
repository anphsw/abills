package Mobile::Configure;

=head1 NAME

  Mobile configuration functions

  ERROR ID: 164ХХХХ

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Mobile;

my Control::Errors $Errors;
my Mobile $Mobile;

my %permissions = ();

#**********************************************************
=head2 new($db, $conf, $admin, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $attr->{lang} || {}
  };

  %permissions = %{$attr->{permissions} || {}};

  bless($self, $class);
  $Mobile = Mobile->new($db, $admin, $conf);
  $Errors = Control::Errors->new($db, $admin, $conf, { lang => $self->{lang}, module => 'Mobile' });

  return $self;
}

#**********************************************************
=head2 tariff_plan_add($attr)

=cut
#**********************************************************
sub tariff_plan_add {
  my $self = shift;
  my ($attr) = @_;

  return $Errors->throw_error(1640001) if !$attr->{SERVICE_ID};

  my $selected_categories = {};
  my $service_id = $attr->{SERVICE_ID};
  $service_id =~ s/,/;/g;
  delete $attr->{SERVICE_ID};

  my $selected_services = $Mobile->service_list({ ID => $service_id, CATEGORY_ID => '_SHOW', COLS_NAME => 1 });

  foreach my $service (@{$selected_services}) {
    if ($selected_categories->{$service->{category_id}}) {
      return $Errors->throw_error(1640002);
    }
    $selected_categories->{$service->{category_id}} = $service->{id};
  }
  
  my $mandatory_categories = $Mobile->category_list({ NAME => '_SHOW', MANDATORY => 1, COLS_NAME => 1 });
  my @unfilled_categories = ();

  foreach my $category (@{$mandatory_categories}) {
    next if $selected_categories->{$category->{id}};

    push @unfilled_categories, $category->{name};
  }
  
  if (scalar(@unfilled_categories)) {
    return $Errors->throw_error(1640003, { lang_vars => { CATEGORIES => join(', ', @unfilled_categories) } });
  }

  use Tariffs;
  my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  $Tariffs->add({ %{$attr}, MODULE => 'Mobile' });
  return $Tariffs if $Tariffs->{errno} || !$Tariffs->{TP_ID};

  $Mobile->tp_services_add({ SERVICE_ID => $service_id, TP_ID => $Tariffs->{TP_ID} });

  if ($Mobile->{errno}) {
    $Tariffs->del($Tariffs->{TP_ID});
    return $Mobile;
  }

  return $self;
}

#**********************************************************
=head2 tariff_plan_change($attr)

=cut
#**********************************************************
sub tariff_plan_change {
  my $self = shift;
  my ($attr) = @_;

  return $Errors->throw_error(1640001) if !$attr->{SERVICE_ID};

  my $selected_categories = {};
  my $service_id = $attr->{SERVICE_ID};
  $service_id =~ s/,/;/g;

  my $selected_services = $Mobile->service_list({ ID => $service_id, CATEGORY_ID => '_SHOW', COLS_NAME => 1 });

  foreach my $service (@{$selected_services}) {
    if ($selected_categories->{$service->{category_id}}) {
      return $Errors->throw_error(1640002);
    }
    $selected_categories->{$service->{category_id}} = $service->{id};
  }

  my $mandatory_categories = $Mobile->category_list({ NAME => '_SHOW', MANDATORY => 1, COLS_NAME => 1 });
  my @unfilled_categories = ();

  foreach my $category (@{$mandatory_categories}) {
    next if $selected_categories->{$category->{id}};

    push @unfilled_categories, $category->{name};
  }

  if (scalar(@unfilled_categories)) {
    return $Errors->throw_error(1640003, { lang_vars => { CATEGORIES => join(', ', @unfilled_categories) } });
  }

  use Tariffs;
  my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  $Tariffs->change($attr->{TP_ID}, { %{$attr}, MODULE => 'Mobile' });
  return $Tariffs if $Tariffs->{errno};

  $Mobile->tp_services_add({ SERVICE_ID => $service_id, TP_ID => $attr->{TP_ID} });
  return $Mobile if $Mobile->{errno};
  
  return $self;
}

1;
