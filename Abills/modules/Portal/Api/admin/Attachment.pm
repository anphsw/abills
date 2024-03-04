package Portal::Api::admin::Attachment;

=head1 NAME

  Portal attachment manage

  Endpoints:
    /portal/attachment/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(dirname cmd next_month in_array);
use Control::Errors;

use Portal;
use Portal::Misc::Attachments;

my Portal $Portal;
my Control::Errors $Errors;
my Portal::Misc::Attachments $Attachments;

my %permissions = ();

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
    attr  => $attr
  };

  %permissions = %{$attr->{permissions} || {}};

  bless($self, $class);

  $Portal = Portal->new($db, $admin, $conf);
  $Attachments = Portal::Misc::Attachments->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_portal_attachment($path_params, $query_params)

  GET /portal/attachment

=cut
#**********************************************************
sub get_portal_attachment {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => ($query_params->{SORT} || 1) > 5 ? 5 : ($query_params->{SORT} || 1),
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
    DESC      => $query_params->{DESC},
  );

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0')
      ? $query_params->{$param}
      : '_SHOW';
  }

  my $results = $Portal->attachment_list({
    ID          => '_SHOW',
    FILENAME    => '_SHOW',
    FILE_SIZE   => '_SHOW',
    FILE_TYPE   => '_SHOW',
    UPLOADED_AT => '_SHOW',
    %$query_params,
    %PARAMS,
  });

  map { $_->{src} = $self->_portal_make_link($_->{filename}); $_ } @$results;

  return {
    list => $results,
    total => $Portal->{TOTAL}
  };
}


#**********************************************************
=head2 get_portal_attachment_id($path_params, $query_params)

  GET /portal/attachment/:id/

=cut
#**********************************************************
sub get_portal_attachment_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $results = $Portal->attachment_info($path_params->{id});

  if ($results->{FILENAME}) {
    $results->{SRC} = $self->_portal_make_link($results->{FILENAME});
  };

  return $results;
}

#**********************************************************
=head2 post_portal_attachment($path_params, $query_params)

  POST /portal/attachment

=cut
#**********************************************************
sub post_portal_attachment {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %result = (
    status      => 0,
    attachments => [],
  );

  my $regex_pattern = qr/FILE/;
  my @files = grep { /$regex_pattern/ } keys %{$query_params};

  return $Errors->throw_error(1440007) if (!scalar @files);

  my $files_count_limit = 5;
  my $files_uploaded = 0;
  foreach my $file (sort @files) {
    if ($files_uploaded >= $files_count_limit) {
      $result{warning} = "Limit of attachments. Count limit is $files_count_limit files. Files which processed is present in attachments array.";

      last;
    }

    my $file_obj = $query_params->{$file};
    $file_obj->{CONTENT_TYPE} = $file_obj->{'CONTENT-TYPE'} if (!$file_obj->{CONTENT_TYPE});
    next if ref $query_params->{$file} ne 'HASH';
    my @keys = ('CONTENT_TYPE', 'SIZE', 'CONTENTS', 'FILENAME');
    next if (map {$file_obj->{$_} } grep exists($file_obj->{$_}), @keys) != scalar @keys;

    if ($file_obj->{CONTENTS} =~ /^[\n\r]/g) {
      $file_obj->{CONTENTS} =~ s/^.*\r?\n?//;
    }

    my $filename = $Attachments->save_picture({
      filename     => $file_obj->{FILENAME},
      Contents     => $file_obj->{CONTENTS},
    });

    my $add_status = $Portal->attachment_add({
      UPLOADED_AT  => $main::DATE,
      FILENAME     => $filename,
      FILE_SIZE    => $file_obj->{SIZE},
      FILE_TYPE    => $file_obj->{CONTENT_TYPE},
    });


    if ($add_status) {
      push @{$result{attachments}}, {
        status    => 0,
        message   => 'Successfully added file',
        filename  => $filename,
        src       => $self->_portal_make_link($filename)
      }
    }
    else {
      my $error_result = $Attachments->{errno} ? {
          errno    => $Attachments->{errno},
          errstr => ($Attachments->{errstr} || '') . ": $filename",
      } : $Errors->throw_error(1440006, { lang_vars => { FILENAME => $filename }});

      push @{$result{attachments}}, $error_result;
    }
  }

  return \%result;
}

#**********************************************************
=head2 delete_portal_attachment_id($path_params, $query_params)

  DELETE /portal/attachment/:id/

=cut
#**********************************************************
sub delete_portal_attachment_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  # We need take info for attachment by id, because we need to delete file by filename.
  my $info = $Portal->attachment_info($path_params->{id});
  if (!$info->{FILENAME}) {
    return $info;
  };

  $Portal->attachment_del($path_params->{id});

  my $result = $Attachments->delete_picture($info->{FILENAME});

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return { result => 'Successfully deleted' };
}

#**********************************************************
=head2 _portal_make_link($filename)

  Arguments:
    $filename - string

  Returns:
    $src - link to file from web

=cut
#**********************************************************
sub _portal_make_link {
  my $self = shift;
  my ($filename) = @_;

  my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  my $maybe_base = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}" : '';
  my $base_attach_link = ($self->{conf}{BILLING_URL} || $maybe_base) . '/images/attach/portal/';

  return $base_attach_link . $filename;
}

1;
