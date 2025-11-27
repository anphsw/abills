package Info_fields;

=head2

  Info_fields

=cut

use strict;
use parent qw(dbcore);
my $MODULE = 'Info_fields';

#**********************************************************
# Init
#**********************************************************
sub new {
  my ($class, $db, $admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };
  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 fields_info($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub fields_info {
  my ($self, $id) = @_;

  $self->query("SELECT * FROM info_fields WHERE id = ? ;", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2  fields_add($attr) - Add info

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub fields_add {
  my ($self, $attr) = @_;

  $attr->{SQL_FIELD} = "_" . $attr->{SQL_FIELD};

  $self->query_add('info_fields', $attr);

  return $self;
}

#**********************************************************
=head2  fields_del() - Delete info

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub fields_del {
  my ($self, $attr) = @_;

  my $info_field = $self->fields_list({ ID => $attr, COLS_NAME => 1 });
  my $field = $info_field->[0];

  if ($field->{type} && $field->{type} == 2 && $field->{sql_field}){
    my $list_table = $field->{sql_field}.'_list';
    $self->info_list_table_del({ TABLE => $list_table} );
  }

  $self->query_del('info_fields', { ID => $attr });

  return $self->{result};
}

#**********************************************************
=head2 fields_list($attr) - list

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub fields_list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

 my @search_fields = (
   [ 'ID',              'INT', 'id',          1 ],
   [ 'NAME',            'STR', 'name',        1 ],
   [ 'SQL_FIELD',       'STR', 'sql_field',   1 ],
   [ 'TYPE',            'INT', 'type',        1 ],
   [ 'PRIORITY',        'INT', 'priority',    1 ],
   [ 'COMPANY',         'INT', 'company',     1 ],
   [ 'ABON_PORTAL',     'INT', 'abon_portal', 1 ],
   [ 'USER_CHG',        'INT', 'user_chg',    1 ],
   [ 'REQUIRED',        'INT', 'required',    1 ],
   [ 'MODULE',          'STR', 'module',      1 ],
   [ 'COMMENT',         'STR', 'comment',     1 ],
   [ 'DOMAIN_ID',       'INT', 'domain_id',   1 ],
   [ 'PARENT_ID',       'INT', 'parent_id',   1 ],
   [ 'PARENT_VALUE_ID', 'INT', 'parent_value_id',   1 ]
 );

  my $WHERE = $self->search_former($attr, \@search_fields, { WHERE => 1 });

  if ($attr->{NOT_ALL_FIELDS}) {
    my $sql = <<"SQL";
SELECT $self->{SEARCH_FIELDS} id
FROM info_fields
  $WHERE
ORDER BY $SORT $DESC;
SQL

    $self->query($sql, undef,  $attr);
  }
  else {
    my $sql = <<"SQL";
SELECT *
FROM info_fields
       $WHERE
ORDER BY $SORT $DESC;
SQL

    $self->query($sql, undef, { COLS_NAME => 1, COLS_UPPER => 1 });
  }

  my $list = $self->{list};
  $self->query("SELECT COUNT(*) AS total FROM info_fields $WHERE;", undef, { INFO => 1 });

  return $list || [];
}


#**********************************************************
=head2 fields_change($attr) - change

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub fields_change {
  my ($self, $attr) = @_;

  $attr->{REQUIRED} //= 0;
  $attr->{ABON_PORTAL} //= 0;
  $attr->{USER_CHG} //= 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'info_fields',
    DATA         => $attr,
  });

  return $self->{result};
}

#**********************************************************
=head2 info_field_attach_add($attr) - Info fields attach add

  Arguments:
    $attr
      COMPANY_PREFIX
  Returns:
    Object

=cut
#**********************************************************
sub info_field_attach_add {
  my ($self, $attr) = @_;

  my $insert_id = 0;

  require Attach;
  Attach->import();
  my $Attach = Attach->new($self->{db}, $self->{admin}, $self->{conf});

  my $fields_list = $self->fields_list({
    NAME      => '_SHOW',
    SQL_FIELD => '_SHOW',
    TYPE      => 13,
    COMPANY   => $attr->{COMPANY_PREFIX} || 0
  });

  return $attr if ($self->{TOTAL} < 1);

  if ($attr->{UID}) {
    require Users;
    Users->import();
    my $users = Users->new($self->{db}, $self->{admin}, $self->{conf});

    $self->{USER_INFO} = $users->pi({ UID => $attr->{UID} });
  }

  
  foreach my $field (@{$fields_list}) {
    my $field_name = $field->{SQL_FIELD};
    my $type       = 13;

    if (ref $attr->{uc($field_name)} eq 'HASH' && $attr->{uc($field_name)}{filename}) {
      if ($self->{conf}->{ATTACH2FILE}) {
        if ($self->{USER_INFO} && $self->{USER_INFO}{uc($field_name)}) {
          $Attach->attachment_del({
            ID         => $self->{USER_INFO}{uc($field_name)},
            TABLE      => $field_name . '_file',
            DEL_BY_FILEPATH => 1,
            UID        => $self->{USER_INFO}{UID},
            SKIP_ERROR => 1
          })
        }
      }

      my $filename = $self->_get_field_filename({
        %{$attr},
        TYPE       => $type,
        FILE_NAME  => $attr->{uc($field_name)}{filename},
        FIELD_NAME => $field_name,
        USER_INFO  => $self->{USER_INFO}
      });

      $Attach->attachment_add({
        TABLE             => $field_name . '_file',
        CONTENT           => $attr->{uc($field_name)}{Contents},
        FILESIZE          => $attr->{uc($field_name)}{Size},
        FILENAME          => $filename,
        CONTENT_TYPE      => $attr->{uc($field_name)}{'Content-Type'},
        UID               => $attr->{UID},
        DIRECTORY_TO_SAVE => $attr->{UID} ? "/info_fields/$attr->{UID}/$field_name/" : "/info_fields/$field_name/",
        FIELD_NAME        => $field_name
      });

      if ($Attach->{errno}) {
        $self->{errno} = $Attach->{errno};
        $self->{errstr} = $Attach->{errstr};
      }
      else {
        $attr->{uc($field_name)} = $Attach->{INSERT_ID};
        $insert_id = $Attach->{INSERT_ID};
      }
    }
    else {
      delete $attr->{uc($field_name)};
    }
  }

  return $attr;
}

#**********************************************************
=head2 _get_field_filename($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub _get_field_filename {
  my ($self, $attr) = @_;

  my $fill_constants = [ 'UID', 'CONTRACT_ID', 'FIELD_NAME', 'LOGIN' ];

  my $filename = $attr->{FILE_NAME};
  my $field_info = $self->fields_list({
    SQL_FIELD => $attr->{FIELD_NAME},
    TYPE      => $attr->{TYPE},
    COMPANY   => $attr->{COMPANY_PREFIX} ? 1 : 0,
    COLS_NAME => 1
  });
  return $filename if !$self->{TOTAL} || $self->{TOTAL} < 1;

  my $pattern = ($field_info && $field_info->[0]) ? $field_info->[0]{PATTERN} : '';
  return $filename if (!$pattern);

  if ($attr->{USER_INFO}) {
    for my $key (@$fill_constants) {
      next if !defined($attr->{USER_INFO}{$key});
      my $placeholder = '%' . $key . '%';
      my $value = $attr->{USER_INFO}{$key};
      $pattern =~ s/\Q$placeholder\E/$value/xg;
    }
  }

  $pattern =~ s/%([A-Z_]+)%/$1/xg;

  my ($extension) = $filename =~ /(\.[^\.]+)$/xm;
  $extension = '' if (!$extension);

  return $pattern . $extension;
}


#**********************************************************
=head2 info_field_add($attr) - Infofields add
  Arguments:
    $attr
      FIELD_ID
      FIELD_TYPE
      COMPANY_ADD
      CAN_BE_CHANGED_BY_USER
      USERS_PORTAL

  Returns:
    $self
=cut
#**********************************************************
sub info_field_add {
  my ($self, $attr) = @_;

  my @column_types = (
    " varchar(120) not null default ''",
    " int(11) NOT NULL default '0'",
    " smallint unsigned NOT NULL default '0' ",
    " text not null ",
    " tinyint(11) NOT NULL default '0' ",
    " content longblob NOT NULL",
    " varchar(100) not null default ''",
    " int(11) unsigned NOT NULL default '0'",
    " varchar(12) not null default ''",
    " varchar(120) not null default ''",
    " varchar(20) not null default ''",
    " varchar(50) not null default ''",
    " varchar(50) not null default ''",
    " int unsigned NOT NULL default '0' ",
    " INT(11) UNSIGNED NOT NULL DEFAULT '0' REFERENCES users(uid) ",
    " varchar(120) not null default ''",
    " varchar(120) not null default ''",
    " varchar(120) not null default ''",
    " varchar(120) not null default ''",
    " tinyint(2) not null default '0' ",
    " DATE not null default '0000-00-00' ",
  );

  $attr->{FIELD_TYPE} = 0 if (!$attr->{FIELD_TYPE});

  my $column_type  = $column_types[ $attr->{FIELD_TYPE} ] || " varchar(120) not null default ''";
  my $field_prefix = 'ifu';

  #Add field to table
  my $field_name = '_'. $attr->{FIELD_ID};
  my $sql = "ALTER TABLE users_pi ADD COLUMN $field_name  $column_type;";
  if ($attr->{COMPANY_ADD}) {
    $field_prefix = 'ifc';
    $sql = "ALTER TABLE companies ADD COLUMN $field_name  $column_type;";
  }

  $self->query($sql, 'do');

  if (!$self->{errno} || ($self->{errno} && $self->{errno} == 3)) {
    if ($attr->{FIELD_TYPE} == 2) {
      $sql = <<"SQL";
  CREATE TABLE _$attr->{FIELD_ID}_list (
     id smallint unsigned NOT NULL primary key auto_increment,
     name varchar(120) not null default 0
  ) DEFAULT CHARSET=$self->{conf}->{dbcharset};
SQL

      $self->query($sql, 'do');
    }
    elsif ($attr->{FIELD_TYPE} == 13) {
      $sql = <<"SQL";
      CREATE TABLE `_$attr->{FIELD_ID}_file` (`id` int(11) unsigned NOT NULL PRIMARY KEY auto_increment,
          `filename` varchar(250) not null default '',
          `content_size` varchar(30) not null  default '',
          `content_type` varchar(250) not null default '',
          `content` longblob NOT NULL,
          `create_time` datetime NOT NULL default '0000-00-00 00:00:00') DEFAULT CHARSET=$self->{conf}->{dbcharset};
SQL

      $self->query($sql, 'do');
    }
  }

  $self->{admin}->system_action_add("IF:_$attr->{FIELD_ID}:$attr->{NAME}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 info_field_del($attr)

  Arguments:
    $attr
      FIELD_ID
      SECTION
  Returns:
    Object

=cut
#**********************************************************
sub info_field_del {
  my ($self, $attr) = @_;

  if (!$self->{errno} || $self->{errno} == 3) {
    $self->{admin}->system_action_add("IF:_$attr->{FIELD_ID}", { TYPE => 10 });
  }

  return $self;
}

#**********************************************************
=head2 info_list_add($attr)

=cut
#**********************************************************
sub info_list_add {
  my ($self, $attr) = @_;

  if(! $attr->{LIST_TABLE}) {
    $self->{errno}=100;
    $self->{errstr}='NO list table';
    return $self;
  }

  $self->query_add($attr->{LIST_TABLE}, $attr);

  return $self;
}

#**********************************************************
=head2 info_list_del($attr) - Info list del value

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub info_list_del {
  my ($self, $attr) = @_;

  $self->query_del($attr->{LIST_TABLE}, $attr);

  return $self;
}

#**********************************************************
=head2 info_lists_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub info_lists_list {
  my ($self, $attr) = @_;

  $self->query("SELECT id, name FROM `$attr->{LIST_TABLE}` ORDER BY name;",
    undef,
    $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 info_list_info($id, $attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub info_list_info {
  my ($self, $id, $attr) = @_;

  $self->query("SELECT id, name FROM `$attr->{LIST_TABLE}` WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 info_list_change($id, $attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub info_list_change {
  my ($self, undef, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => $attr->{LIST_TABLE},
    DATA         => $attr
  });

  return $self->{result};
}

#**********************************************************
=head2 info_list_table_del($attr) - deleting info list's table

  Attr:
   TABLE - table name

=cut
#**********************************************************
sub info_list_table_del {
  my ($self, $attr) = @_;

  my $table = $attr->{TABLE};
  $self->query("DROP TABLE IF EXISTS $table;", undef, $attr);

  return $self;
}

#**********************************************************
=head2 info_list_multi_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub info_list_multi_add {
  my ($self, $attr) = @_;

  my $result = {};
  return $result if !$attr->{INFO_FIELDS_CUSTOM_OPTION_SELECTS};

  my @info_fields = split(',\s?', $attr->{INFO_FIELDS_CUSTOM_OPTION_SELECTS});

  foreach my $info_field (@info_fields) {
    if (!$attr->{$info_field}) {
      next;
    }

    $self->info_list_add({
      LIST_TABLE => lc($info_field) . '_list',
      NAME       => $attr->{$info_field}
    });

    if (!$self->{errno}) {
      $attr->{$info_field} = $self->{INSERT_ID};
      $result->{$info_field} = $self->{INSERT_ID};
    }
  }

  return $result;
}

1;