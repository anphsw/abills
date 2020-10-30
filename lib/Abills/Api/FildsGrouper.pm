package Abills::Api::FildsGrouper;

sub group_filds {
  my ($result) = @_;

  if(ref $result eq 'ARRAY') {
    foreach(@$result) {
      $_ = group($_)
    }
  }
  else {
    $result = group($result)
  }

  return $result;
}

sub group {
  my ($result) = @_;

  foreach my $fild_name (keys %$result) {
    if($fild_name =~ m/(.*)_(\d*)$/gm) {
      delete $result->{$fild_name};
    }
  }

  foreach my $fild_name (keys %$result) {
    if($fild_name =~ m/(.*)_ALL$/gm) {
      my $old_fild_name = $fild_name;
      $fild_name =~ s/_ALL$//gm;

      my @list = split (', ', $result->{$old_fild_name});
      $result->{$fild_name} = \@list;
      delete $result->{$old_fild_name};
    }
  }

  return $result;
}

1;