package Attach;
=head1 NAME

  Attach DB managment

=cut

use strict;
use warnings FATAL => 'all';

use strict;
use parent 'main';
use Conf;

my $admin;
my $CONF;
#my $SORT = 1;
#my $DESC = '';
#my $PG   = 1;
#my $PAGE_ROWS = 25;


#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db)  = shift;
  ($admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  if($CONF->{ATTACH2FILE}) {
    #$self->{ATTACH2FILE}=$CONF->{ATTACH2FILE};
    $self->{ATTACH2FILE}="$CONF->{TPL_DIR}/attach/";
  }

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 file2disc($attr) - Add to disck

=cut
#**********************************************************
sub file2disc {
  my $self = shift;
  my ($attr) = @_;

  my $filename = $self->{ATTACH2FILE}.'/'. $attr->{FILENAME};

  if (! -d $self->{ATTACH2FILE}) {
    $self->{errno} = 110;
    $self->{errstr} = "Folder not exists '$self->{ATTACH2FILE}'";
    mkdir($self->{ATTACH2FILE});
  }
  elsif(-f $filename) {
    $self->{errno} = 111;
    $self->{errstr} = "File exist '$self->{ATTACH2FILE}'";
  }
  elsif (open( my $fh, '>', $filename)) {
    print $filename;
    binmode $fh;
      print $fh $attr->{CONTENT};
    close($fh);
  }
  else {
    $self->{errno} = 112;
    $self->{errstr} = "Can't create file '$attr->{FILENAME}' $!";
  }

  return $self;
}

#**********************************************************
=head2 attachment_add($attr) - Add attachment

  Arguments:
    $attr
      TABLE    - Table name
      FILENAME
      CONTENT_TYPE
      FILESIZE
      CONTENT

  Returns:
    $self

=cut
#**********************************************************
sub attachment_add{
  my $self = shift;
  my ($attr) = @_;

  if($self->{ATTACH2FILE}) {
    $self->file2disc($attr);
    if($self->{errno}) {
      return $self;
    }
    else {
      $attr->{CONTENT} = "FILENAME: $attr->{FILENAME}";
    }
  }

  $self->query2( "INSERT INTO $attr->{TABLE}
        (filename, content_type, content_size, content, create_time)
        VALUES (?, ?, ?, ?, NOW())",
    'do', { Bind => [
        $attr->{FILENAME},
        $attr->{CONTENT_TYPE},
        $attr->{FILESIZE},
        $attr->{CONTENT} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 attachment_del($attr) - Add attachment

  Arguments:
    $attr
      TABLE    - Table name
      ID       - ID

  Returns:
    $self

=cut
#**********************************************************
sub attachment_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del($attr->{TABLE}, $attr);

  return $self;
}

#**********************************************************
=head2 attachment_info($attr)

=cut
#**********************************************************
sub attachment_info {
  my $self = shift;
  my ($attr) = @_;

  my $content = (!$attr->{INFO_ONLY}) ? ',content' : '';

  if(! $attr->{TABLE}) {
    return $self
  }

  my $table   = $attr->{TABLE};

  $self->query2("SELECT id AS attachment_id,
    filename,
    content_type,
    content_size AS filesize
    $content
   FROM `$table`
   WHERE id = ? ",
    undef,
    { INFO => 1,
      Bind => [
        $attr->{ID}
      ]
    }
  );

  return $self;
}


1;
