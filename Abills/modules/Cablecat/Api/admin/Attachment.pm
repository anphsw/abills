package Cablecat::Api::admin::Attachment;

=head1 NAME

  Cablecat Attachment manage

  Endpoints:
    /cablecat/attachment

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;

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
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_cablecat_attachment($path_params, $query_params)

  Endpoint POST /cablecat/attachment/

=cut
#**********************************************************
sub post_cablecat_attachment {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my @file_names = ();
  foreach my $key (keys %{$query_params}) {
    next if ref $query_params->{$key} ne 'HASH' || !$query_params->{$key}{filename};

    my $file_name = $query_params->{$key}{filename};
    if ($file_name =~ /([^\.]+)\.([a-z0-9\_]+)$/i) {
      my $file_extension = $2;
      $file_name = Abills::Base::txt2translit($1) . '_' . time() . '.' . $file_extension;
    }

    if (main::upload_file($query_params->{$key}, { FILE_NAME => $file_name, PREFIX => 'cablecat', REWRITE => 1 })) {
      push @file_names, $file_name;
    }
  }

  return { files => \@file_names };
}

1;
