package Users;
# Users manage functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.05;
@ISA     = ('Exporter');

@EXPORT = qw(config_list);

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

# User name expration
my $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$";    # configurable;

use main;
@ISA = ("main");
my $uid;


#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if ($#WHERE_RULES > -1);

  $admin->{MODULE} = '';
  $CONF->{MAX_USERNAME_LENGTH} = 10 if (!defined($CONF->{MAX_USERNAME_LENGTH}));

  if (defined($CONF->{USERNAMEREGEXP})) {
    $usernameregexp = $CONF->{USERNAMEREGEXP};
  }

  $self->{db}=$db;
  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  my $WHERE;

  if (defined($attr->{LOGIN}) && defined($attr->{PASSWORD})) {

    $WHERE = "WHERE u.id='$attr->{LOGIN}' and DECODE(u.password, '$CONF->{secretkey}')='$attr->{PASSWORD}'";
    if (defined($attr->{ACTIVATE})) {
      my $value = $self->search_expr("$attr->{ACTIVATE}", 'INT');
      $WHERE .= " and u.activate$value";
    }

    if (defined($attr->{EXPIRE})) {
      my $value = $self->search_expr("$attr->{EXPIRE}", 'INT');
      $WHERE .= " and u.expire$value";
    }

    if (defined($attr->{DISABLE})) {
      $WHERE .= " and u.disable='$attr->{DISABLE}'";
    }
  }
  elsif ($attr->{LOGIN}) {
    $WHERE = "WHERE u.id='$attr->{LOGIN}'";
  }
  else {
    $WHERE = "WHERE u.uid='$uid'";
  }

  if ($attr->{DOMAIN_ID}) {
    $WHERE .= "AND u.domain_id='$attr->{DOMAIN_ID}'";
  }

  my $password = "''";
  if ($attr->{SHOW_PASSWORD}) {
    $password = "DECODE(u.password, '$CONF->{secretkey}') AS password";
  }

  $self->query2("SELECT u.uid,
   u.gid, 
   g.name AS g_name,
   u.id AS login, 
   u.activate, 
   u.expire, 
   u.credit, 
   u.reduction, 
   u.registration, 
   u.disable,
   if(u.company_id > 0, cb.id, b.id) AS bill_id,
   if(c.name IS NULL, b.deposit, cb.deposit) AS deposit,
   u.company_id,
   if(c.name IS NULL, '', c.name) AS company_name, 
   if(c.name IS NULL, 0, c.vat) AS company_vat,
   if(c.name IS NULL, b.uid, cb.uid) AS bill_owner,
   if(u.company_id > 0, c.ext_bill_id, u.ext_bill_id) AS ext_bill_id,
   u.credit_date,
   u.reduction_date,
   if(c.name IS NULL, 0, c.credit) AS company_credit,
   u.domain_id,
   u.deleted,
   $password
     FROM users u
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN groups g ON (u.gid=g.gid)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
     $WHERE;",
   undef,
   { INFO => 1 }
  );

  if ((!$admin->{permissions}->{0} || !$admin->{permissions}->{0}->{8}) && ($self->{DELETED})) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  if ($CONF->{EXT_BILL_ACCOUNT} && $self->{EXT_BILL_ID} && $self->{EXT_BILL_ID} > 0) {
    $self->query2("SELECT b.deposit AS ext_bill_deposit, b.uid AS ext_bill_owner
     FROM bills b WHERE id='$self->{EXT_BILL_ID}';",
     undef,
     { INFO => 1 }
    );
  }

  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults_pi {
  my $self = shift;

  %DATA = (
    FIO            => '',
    PHONE          => 0,
    ADDRESS_STREET => '',
    ADDRESS_BUILD  => '',
    ADDRESS_FLAT   => '',
    COUNTRY_ID     => 0,
    EMAIL          => '',
    COMMENTS       => '',
    CONTRACT_ID    => '',
    PASPORT_NUM    => '',
    PASPORT_DATE   => '0000-00-00',
    PASPORT_GRANT  => '',
    ZIP            => '',
    CITY           => '',
    CREDIT_DATE    => '0000-00-00',
    REDUCTION_DATE => '0000-00-00',
    ACCEPT_RULES   => 0,
    LOCATION_ID    => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# pi_add()
#**********************************************************
sub pi_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => defaults_pi() });

  if ($DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
      $self->{errno}  = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
    }
  }

  #Info fields
  my $info_fields     = '';
  my $info_fields_val = '';

  my $list = $self->config_list({ PARAM => 'ifu*', SORT => 2 });
  if ($self->{TOTAL} > 0) {
    my @info_fields_arr = ();
    my @info_fields_val = ();

    foreach my $line (@$list) {
      if ($line->[0] =~ /ifu(\S+)/) {
        my $value = $1;
        push @info_fields_arr, $value;
        if (defined($attr->{$value})) {

          #attach
          if (ref $attr->{$value} eq 'HASH' && $attr->{$value}{filename}) {
            $self->attachment_add(
              {
                TABLE        => $value . '_file',
                CONTENT      => $attr->{$value}{Contents},
                FILESIZE     => $attr->{$value}{Size},
                FILENAME     => $attr->{$value}{filename},
                CONTENT_TYPE => $attr->{$value}{'Content-Type'}
              }
            );
            $attr->{$value} = $self->{INSERT_ID};
          }
          else {
            $attr->{$value} =~ s/^ +|[ \n]+$//g;
          }
        }
        else {
          $attr->{$value} = '';
        }
        push @info_fields_val, "'$attr->{$value}'";
      }
    }

    $info_fields     = ', ' . join(', ', @info_fields_arr) if ($#info_fields_arr > -1);
    $info_fields_val = ', ' . join(', ', @info_fields_val) if ($#info_fields_arr > -1);
  }

  my $prefix = '';
  my $sufix  = '';
  if ($attr->{CONTRACT_TYPE}) {
    ($prefix, $sufix) = split(/\|/, $attr->{CONTRACT_TYPE});
  }

  if ($DATA{STREET_ID} && $DATA{ADD_ADDRESS_BUILD} && ! $DATA{LOCATION_ID}) {
    my $list = $self->build_list({ STREET_ID => $DATA{STREET_ID}, 
                                   NUMBER    => $attr->{ADD_ADDRESS_BUILD}, 
                                   COLS_NAME => 1 
                                 });

    if ($self->{TOTAL} > 0) {
      $DATA{LOCATION_ID}=$list->[0]->{id};
    }
    else {
      $self->build_add({ NUMBER    => $DATA{ADD_ADDRESS_BUILD}, 
                         STREET_ID => $DATA{STREET_ID},  
                      });
      $DATA{LOCATION_ID}=$self->{INSERT_ID};
    }
  }

  $self->query2("INSERT INTO users_pi (uid, fio, phone, address_street, address_build, address_flat, country_id,
          email, contract_id, contract_date, comments, pasport_num, pasport_date,  pasport_grant, zip, 
          city, accept_rules, location_id, contract_sufix
           $info_fields)
           VALUES ('$DATA{UID}', '$DATA{FIO}', '$DATA{PHONE}', \"$DATA{ADDRESS_STREET}\", 
            \"$DATA{ADDRESS_BUILD}\", \"$DATA{ADDRESS_FLAT}\", '$DATA{COUNTRY_ID}',
            '$DATA{EMAIL}', '$DATA{CONTRACT_ID}', '$DATA{CONTRACT_DATE}',
            '$DATA{COMMENTS}',
            '$DATA{PASPORT_NUM}',
            '$DATA{PASPORT_DATE}',
            '$DATA{PASPORT_GRANT}',
            '$DATA{ZIP}',
            '$DATA{CITY}',
            '$DATA{ACCEPT_RULES}', '$DATA{LOCATION_ID}',
            '$sufix'
            $info_fields_val );", 'do'
  );

  return $self if ($self->{errno});

  $admin->action_add("$DATA{UID}", "PI", { TYPE => 1 });
  return $self;
}

#**********************************************************
#
#**********************************************************
sub attachment_info () {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{ID}) {
    $WHERE .= " id='$attr->{ID}'";
  }

  my $content = (!$attr->{INFO_ONLY}) ? ',content' : '';

  my $table = $attr->{TABLE};

  $self->query2("SELECT id AS attachment_id, 
    filename, 
    content_type, 
    content_size AS filesize
    content AS content
   FROM `$table`
   WHERE $WHERE",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# Personal inforamtion
# pi()
#**********************************************************
sub pi {
  my $self = shift;
  my ($attr) = @_;

  my $UID = ($attr->{UID}) ? $attr->{UID} : $self->{UID};

  #Make info fields use
  my $info_fields     = '';
  my @info_fields_arr = ();

  my $list = $self->config_list({ PARAM => 'ifu*', SORT => 2 });
  if ($self->{TOTAL} > 0) {
    my %info_fields_hash = ();

    foreach my $line (@$list) {
      if ($line->[0] =~ /ifu(\S+)/) {
        push @info_fields_arr, $1;
        $info_fields_hash{$1} = "$line->[1]";
      }
    }
    $info_fields = ', ' . join(', ', @info_fields_arr) if ($#info_fields_arr > -1);

    $self->{INFO_FIELDS_ARR}  = \@info_fields_arr;
    $self->{INFO_FIELDS_HASH} = \%info_fields_hash;
  }

  $self->query2("SELECT pi.fio, 
  pi.phone, 
  pi.country_id,
  pi.address_street, 
  pi.address_build,
  pi.address_flat,
  pi.email,
  pi.contract_id,
  pi.contract_date,
  pi.contract_sufix,
  pi.comments,
  pi.pasport_num,
  pi.pasport_date,
  pi.pasport_grant,
  pi.zip,
  pi.city,
  pi.accept_rules,
  pi.location_id
  $info_fields
    FROM users_pi pi
    WHERE pi.uid='$UID';"
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  my @INFO_ARR = ();

  (
    $self->{FIO},      
    $self->{PHONE},       
    $self->{COUNTRY_ID},   
    $self->{ADDRESS_STREET}, 
    $self->{ADDRESS_BUILD}, 
    $self->{ADDRESS_FLAT}, 
    $self->{EMAIL},       
    $self->{CONTRACT_ID}, 
    $self->{CONTRACT_DATE}, 
    $self->{CONTRACT_SUFIX},
    $self->{COMMENTS}, 
    $self->{PASPORT_NUM}, 
    $self->{PASPORT_DATE}, 
    $self->{PASPORT_GRANT},  
    $self->{ZIP},           
    $self->{CITY},         
    $self->{ACCEPT_RULES}, 
    $self->{LOCATION_ID}, 
    @INFO_ARR
  ) = @{ $self->{list}->[0] };

  $self->{INFO_FIELDS_VAL} = \@INFO_ARR;

  my $i = 0;
  foreach my $val (@INFO_ARR) {
    $self->{ $info_fields_arr[$i] } = $val;
    $self->{ 'INFO_FIELDS_VAL_' . $i } = $val;
    $i++;
  }

  if (! $self->{errno} && $self->{LOCATION_ID}) {
    $self->query2("select d.id AS district_id, 
      d.city, 
      d.name AS address_district, 
      s.name AS address_street, 
      b.number AS address_build,
      s.id AS street_id
     FROM builds b
     LEFT JOIN streets s  ON (s.id=b.street_id)
     LEFT JOIN districts d  ON (d.id=s.district_id)
     WHERE b.id='$self->{LOCATION_ID}'",
     undef,
     { INFO => 1 }
    );

    if ($self->{errno} && $self->{errno} == 2) {
    	delete $self->{errno};
    }
  }
  

  $self->{TOTAL}=1;
  return $self;
}

#**********************************************************
# Personal Info change
# pi_change();
#**********************************************************
sub pi_change {
  my $self = shift;
  my ($attr) = @_;

  my %PI_FIELDS = (
    EMAIL          => 'email',
    FIO            => 'fio',
    PHONE          => 'phone',
    COUNTRY_ID     => 'country_id',
    ADDRESS_BUILD  => 'address_build',
    ADDRESS_STREET => 'address_street',
    ADDRESS_FLAT   => 'address_flat',
    ZIP            => 'zip',
    CITY           => 'city',
    COMMENTS       => 'comments',
    UID            => 'uid',
    CONTRACT_ID    => 'contract_id',
    CONTRACT_DATE  => 'contract_date',
    CONTRACT_SUFIX => 'contract_sufix',
    PASPORT_NUM    => 'pasport_num',
    PASPORT_DATE   => 'pasport_date',
    PASPORT_GRANT  => 'pasport_grant',
    ACCEPT_RULES   => 'accept_rules',
    LOCATION_ID    => 'location_id'
  );

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD}) {
    
    my $list = $self->build_list({ STREET_ID => $attr->{STREET_ID}, 
                                   NUMBER    => $attr->{ADD_ADDRESS_BUILD}, 
                                   COLS_NAME => 1 
                                 });

    if ($self->{TOTAL} > 0) {
      $attr->{LOCATION_ID}=$list->[0]->{id};
    }
    else {
      $self->build_add({ NUMBER    => $attr->{ADD_ADDRESS_BUILD}, 
                         STREET_ID => $attr->{STREET_ID},  
                      });

      $attr->{LOCATION_ID}=$self->{INSERT_ID};
    }
  }


  if (!$attr->{SKIP_INFO_FIELDS}) {
    my $list = $self->config_list({ PARAM => 'ifu*' });
    if ($self->{TOTAL} > 0) {
      foreach my $line (@$list) {
        if ($line->[0] =~ /ifu(\S+)/) {
          my $field_name = $1;
          $PI_FIELDS{$field_name} = "$field_name";
          my ($position, $type, $name) = split(/:/, $line->[1]);
          if ($type == 13) {

            #attach
            if (ref $attr->{$field_name} eq 'HASH' && $attr->{$field_name}{filename}) {
              $self->attachment_add(
                {
                  TABLE        => $field_name . '_file',
                  CONTENT      => $attr->{$field_name}{Contents},
                  FILESIZE     => $attr->{$field_name}{Size},
                  FILENAME     => $attr->{$field_name}{filename},
                  CONTENT_TYPE => $attr->{$field_name}{'Content-Type'}
                }
              );
              $attr->{$field_name} = $self->{INSERT_ID};
            }
            else {
              delete $attr->{$field_name};
            }
          }
          elsif ($type == 4) {
            $attr->{$field_name} = 0 if (!$attr->{$field_name});
          }
        }
      }
    }
  }

  my ($prefix, $sufix);
  if ($attr->{CONTRACT_TYPE}) {
    ($prefix, $sufix) = split(/\|/, $attr->{CONTRACT_TYPE});
    $attr->{CONTRACT_SUFIX} = $sufix;
  }

  $admin->{MODULE} = '';

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'users_pi',
      FIELDS       => \%PI_FIELDS,
      OLD_INFO     => $self->pi({ UID => $attr->{UID} }),
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# defauls user settings
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
    LOGIN          => '',
    ACTIVATE       => '0000-00-00',
    EXPIRE         => '0000-00-00',
    CREDIT         => 0,
    CREDIT_DATE    => '0000-00-00',
    REDUCTION      => '0.00',
    REDUCTION_DATE => '0000-00-00',
    SIMULTANEONSLY => 0,
    DISABLE        => 0,
    COMPANY_ID     => 0,
    GID            => 0,
    DISABLE        => 0,
    PASSWORD       => '',
    BILL_ID        => 0,
    EXT_BILL_ID    => 0,
    DOMAIN_ID      => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# groups_list()
#**********************************************************
sub groups_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  undef @WHERE_RULES;

  # Show groups
  if ($attr->{GIDS}) {
    if ($admin->{GIDS}) {
      my @result_gids = ();  
      my @admin_gids  = split(/, /, $admin->{GIDS});
      my @attr_gids   = split(/, /, $attr->{GIDS});

      foreach my $attr_gid ( @attr_gids ) {
        foreach my $admin_gid (@admin_gids)  {
          if ($admin_gid == $attr_gid) {
            push @result_gids, $attr_gid; 
            last;
          }
        }
      }

      $attr->{GIDS}=join(', ', @result_gids);
    }
    
    push @WHERE_RULES, "g.gid IN ($attr->{GIDS})";
  }
  elsif (defined($attr->{GID}) && $attr->{GID} ne '') {
    push @WHERE_RULES,  @{ $self->search_expr($attr->{GID}, 'INT', 'g.gid') };
  }
  elsif ($admin->{GIDS}) {
    push @WHERE_RULES, "g.gid IN ($admin->{GIDS})";
  }

  my $USERS_WHERE = '';
  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, "g.domain_id='$admin->{DOMAIN_ID}'";
    $USERS_WHERE = "AND u.domain_id='$admin->{DOMAIN_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT g.gid, g.name, g.descr, count(u.uid) AS users_count, g.allow_credit, g.disable_paysys, g.domain_id FROM groups g
        LEFT JOIN users u ON  (u.gid=g.gid $USERS_WHERE) 
        $WHERE
        GROUP BY g.gid
        ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total FROM groups g $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# group_info()
#**********************************************************
sub group_info {
  my $self = shift;
  my ($gid) = @_;

  $self->query2("SELECT *
    FROM groups g 
    WHERE g.gid='$gid';",
   undef, { INFO => 1 });

  return $self;
}

#**********************************************************
# group_info()
#**********************************************************
sub group_change {
  my $self = shift;
  my ($gid, $attr) = @_;

  $attr->{SEPARATE_DOCS} = ($attr->{SEPARATE_DOCS}) ? 1 : 0;
  $attr->{ALLOW_CREDIT}  = ($attr->{ALLOW_CREDIT}) ? 1 : 0;
  $attr->{DISABLE_PAYSYS}= ($attr->{DISABLE_PAYSYS}) ? 1 : 0;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM    => 'GID',
      TABLE           => 'groups',
      DATA            => $attr,
      EXT_CHANGE_INFO => "GID:$gid"
    }
  );

  return $self;
}

#**********************************************************
# group_add()
#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('groups', { %$attr, DOMAIN_ID => $admin->{DOMAIN_ID} });

  $admin->system_action_add("GID:$DATA{GID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
# group_add()
#**********************************************************
sub group_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM groups WHERE gid='$id';", 'do');

  $admin->system_action_add("GID:$id", { TYPE => 10 });
  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub list {
  my $self   = shift;
  my ($attr) = @_;

  my @list   = ();

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();

  if ($attr->{UNIVERSAL_SEARCH}) {
    my @us_fields = ('u.uid:INT', 'u.id:STR', 'pi.fio:STR', 'pi.contract_id:STR', 'pi.email:STR', 'pi.phone:STR', 'pi.comments:STR');
    $self->{SEARCH_FIELDS_COUNT}+=5;
    $self->{SEARCH_FIELDS} = 'pi.fio,if(company.id IS NULL, b.deposit, cb.deposit) AS deposit,u.credit,';


    if ($CONF->{ADDRESS_REGISTER}) {
      $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=pi.location_id)
      LEFT JOIN streets ON (streets.id=builds.street_id)";
      push @us_fields, "CONCAT(streets.name, ' ', builds.number, ',', pi.address_flat):STR";
      $self->{SEARCH_FIELDS}.="CONCAT(streets.name, ' ', builds.number, ',', pi.address_flat) AS address_full,";
    }
    else {
      push @us_fields, "CONCAT(pi.address_street, ' ', pi.address_build, ',', pi.address_flat):STR";
      $self->{SEARCH_FIELDS}.="CONCAT(pi.address_street, ' ', pi.address_build, ',', pi.address_flat) AS address_full,";
    }
    
    $self->{EXT_TABLES} .= 'LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN companies company ON  (u.company_id=company.id) 
      LEFT JOIN bills cb ON (company.bill_id=cb.id)';

    $self->{SEARCH_FIELDS} .= ' pi.phone, pi.contract_id,pi.email,pi.comments,';
    
    my @us_query  = ();
    foreach my $f (@us_fields) {
      my ($name, $type) = split(/:/, $f);
      push @us_query, @{ $self->search_expr("*$attr->{UNIVERSAL_SEARCH}*", "$type", "$name") };
    }

    @WHERE_RULES = ("(". join(' or ', @us_query) .")");
  }
  else {
    push @WHERE_RULES, @{ $self->search_expr_users({ %$attr, 
                      EXT_FIELDS => [ 
        'FIO',
        'DEPOSIT',
        'CREDIT',
        'CREDIT_DATE',
        'LOGIN_STATUS',
        'PHONE',
        'EMAIL',
        'ADDRESS_FLAT',
        'PASPORT_DATE',
        'PASPORT_NUM', 
        'PASPORT_GRANT',
        'CITY', 
        'ZIP',
        'GID',
        'CONTRACT_ID',
        'CONTRACT_SUFIX',
        'CONTRACT_DATE',
        'EXPIRE',

#        'CREDIT:skip',

        'REDUCTION',
        'REGISTRATION',
        'REDUCTION_DATE',
        'COMMENTS',
        'BILL_ID',
        'ACTIVATE',
        'EXPIRE',
        'DOMAIN_ID',
        'UID',
         ] }) };
  }

  if ($attr->{EXT_DEPOSIT}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{EXT_BILL_ID}, 'INT', 'if(company.id IS NULL,ext_b.id,ext_cb.id)', { EXT_FIELD => 'if(company.id IS NULL,ext_b.deposit,ext_cb.deposit) AS ext_deposit' }) };
    $self->{EXT_TABLES} .= "
            LEFT JOIN bills ext_b ON (u.ext_bill_id = ext_b.id)
            LEFT JOIN bills ext_cb ON  (company.ext_bill_id=ext_cb.id) ";
    if ($self->{EXT_TABLES} !~ /company /) {
    	$self->{EXT_TABLES} = "LEFT JOIN companies company ON  (u.company_id=company.id) ". $self->{EXT_TABLES};
    }
  }

  # Show debeters
  if ($attr->{DEBETERS}) {
    push @WHERE_RULES, "b.deposit<0";
  }

  if (defined($attr->{DISABLE}) && $attr->{DISABLE} ne '') {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DISABLE}, 'INT', 'u.disable') };
  }

  if ($attr->{ACTIVE}) {
    push @WHERE_RULES, "(u.expire = '0000-00-00' or u.expire>curdate()) and u.credit + if(company.id IS NULL, b.deposit, cb.deposit) > 0 and u.disable=0 ";
  }

  my $EXT_TABLES = $self->{EXT_TABLES};

  #Show last paymenst
  if ($attr->{PAYMENTS} || $attr->{PAYMENT_DAYS}) {
    my @HAVING_RULES = @WHERE_RULES;

    if ($attr->{PAYMENTS}) {
      my $value = @{ $self->search_expr($attr->{PAYMENTS}, 'INT') }[0];
      push @WHERE_RULES,  "p.date$value";
      push @HAVING_RULES, "max(p.date)$value";
      $self->{SEARCH_FIELDS} .= 'max(p.date) AS last_payments, ';
      $self->{SEARCH_FIELDS_COUNT}++;
    }
    elsif ($attr->{PAYMENT_DAYS}) {
      my $value = "now() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
      $value =~ s/([<>=]{1,2})//g;
      $value = $1 . $value;

      push @WHERE_RULES,  "p.date$value";
      push @HAVING_RULES, "max(p.date)$value";
      $self->{SEARCH_FIELDS} .= 'max(p.date) AS last_payments, ';
      $self->{SEARCH_FIELDS_COUNT}++;
    }

    my $HAVING = ($#HAVING_RULES > -1) ? "HAVING " . join(' and ', @HAVING_RULES) : '';
    $self->query2("SELECT u.id AS login, 
       $self->{SEARCH_FIELDS}
       u.uid, 
       u.company_id, 
       pi.email, 
       u.activate, 
       u.expire,
       u.gid,
       b.deposit,
       u.domain_id
     FROM users u
     LEFT JOIN payments p ON (u.uid = p.uid)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     $EXT_TABLES
     GROUP BY u.uid
     $HAVING
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
    );
    return $self if ($self->{errno});

    my $list = $self->{list};
    
    # Totas Records
    if ($self->{TOTAL} > 0) {
      if ($attr->{PAYMENT}) {
        $WHERE_RULES[$#WHERE_RULES] = @{ $self->search_expr($attr->{PAYMENTS}, 'INT', 'p.date') };
      }
      elsif ($attr->{PAYMENT_DAYS}) {
        my $value = "curdate() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
        $value =~ s/([<>=]{1,2})//g;
        $value = $1 . $value;
        $WHERE_RULES[$#WHERE_RULES] = "p.date$value";
      }

      $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

      $self->query2("SELECT count(DISTINCT u.uid) AS total FROM users u 
       LEFT JOIN payments p ON (u.uid = p.uid)
       LEFT JOIN users_pi pi ON (u.uid = pi.uid)
       LEFT JOIN bills b ON (u.bill_id = b.id)
      $WHERE;",
      undef,
      { INFO => 1 }
      );
    }

    return $list;
  }

  #Show last fees
  if ($attr->{FEES} || $attr->{FEES_DAYS}) {
    my @HAVING_RULES = @WHERE_RULES;
    if ($attr->{PAYMENTS}) {
      my $value = $self->search_expr($attr->{FEES}, 'INT');
      push @WHERE_RULES,  "f.date$value";
      push @HAVING_RULES, "max(f.date)$value";
      $self->{SEARCH_FIELDS} .= 'max(f.date) AS last_fees, ';
      $self->{SEARCH_FIELDS_COUNT}++;
    }
    elsif ($attr->{FEES_DAYS}) {
      my $value = "now() - INTERVAL $attr->{FEES_DAYS} DAY";
      $value =~ s/([<>=]{1,2})//g;
      $value = $1 . $value;

      push @WHERE_RULES,  "p.date$value";
      push @HAVING_RULES, "max(f.date)$value";
      $self->{SEARCH_FIELDS} .= 'max(f.date) AS last_fees, ';
      $self->{SEARCH_FIELDS_COUNT}++;
    }

    my $HAVING = ($#WHERE_RULES > -1) ? "HAVING " . join(' and ', @HAVING_RULES) : '';

    $self->query2("SELECT u.id AS login, 
       $self->{SEARCH_FIELDS}
       u.uid, 
       u.company_id, 
       pi.email, 
       u.activate, 
       u.expire,
       u.gid,
       b.deposit,
       u.domain_id
     FROM users u
     LEFT JOIN fees f ON (u.uid = f.uid)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     $EXT_TABLES
     GROUP BY u.uid
     $HAVING
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
    );
    return $self if ($self->{errno});

    my $list = $self->{list};
    
    if ($self->{TOTAL} > 0) {
      if ($attr->{FEES}) {
        $WHERE_RULES[$#WHERE_RULES] = @{ $self->search_expr($attr->{PAYMENTS}, 'INT', 'f.date') };
      }
      elsif ($attr->{FEES_DAYS}) {
        my $value = "curdate() - INTERVAL $attr->{FEES_DAYS} DAY";
        $value =~ s/([<>=]{1,2})//g;
        $value = $1 . $value;
        $WHERE_RULES[$#WHERE_RULES] = "f.date$value";
      }

      $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

      $self->query2("SELECT count(DISTINCT u.uid) AS total FROM users u 
       LEFT JOIN fees f ON (u.uid = f.uid)
       LEFT JOIN users_pi pi ON (u.uid = pi.uid)
       LEFT JOIN bills b ON (u.bill_id = b.id)
      $WHERE;",
      undef,
      { INFO => 1 }
      );
    }

    return $list;
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT u.id AS login, 
      $self->{SEARCH_FIELDS}
      u.uid
     FROM users u
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     $EXT_TABLES
     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr 
  );

  return $self if ($self->{errno});
  my $list = $self->{list};

  if ($self->{TOTAL} == $PAGE_ROWS || $PG > 0 || $attr->{FULL_LIST}) {
    $self->query2("SELECT count(u.id) AS total, 
     sum(if(u.expire<curdate() AND u.expire>'0000-00-00', 1, 0)) AS total_expired, 
     sum(u.disable) AS total_disabled,
     sum(u.deleted) AS total_deleted
     FROM users u 
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     $EXT_TABLES
    $WHERE",
    undef,
    { INFO => 1 }
    );

  }

  return $list;
}

#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => defaults() });

  if (!defined($DATA{LOGIN})) {
    $self->{errno}  = 8;
    $self->{errstr} = 'ERROR_ENTER_NAME';
    return $self;
  }
  elsif (length($DATA{LOGIN}) > $CONF->{MAX_USERNAME_LENGTH}) {
    $self->{errno}  = 9;
    $self->{errstr} = 'ERROR_LONG_USERNAME';
    return $self;
  }

  #ERROR_SHORT_PASSWORD
  elsif ($DATA{LOGIN} !~ /$usernameregexp/) {
    $self->{errno}  = 10;
    $self->{errstr} = 'ERROR_WRONG_NAME';
    return $self;
  }
  elsif ($DATA{EMAIL} && $DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
      $self->{errno}  = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
    }
  }

  $DATA{DISABLE} = int($DATA{DISABLE});
  my $registration = ($DATA{REGISTRATION}) ? "'$DATA{REGISTRATION}'" : 'now()';

  $self->query2("INSERT INTO users (uid, id, activate, expire, credit, reduction, 
           registration, disable, company_id, gid, password, credit_date, reduction_date, domain_id)
           VALUES ('$DATA{UID}', '$DATA{LOGIN}', '$DATA{ACTIVATE}', '$DATA{EXPIRE}', '$DATA{CREDIT}', '$DATA{REDUCTION}', 
           $registration,  '$DATA{DISABLE}', 
           '$DATA{COMPANY_ID}', '$DATA{GID}', 
           ENCODE('$DATA{PASSWORD}', '$CONF->{secretkey}'), '$DATA{CREDIT_DATE}', '$DATA{REDUCTION_DATE}', '$admin->{DOMAIN_ID}'
           );", 'do'
  );

  return $self if ($self->{errno});

  $self->{UID}   = $self->{INSERT_ID};
  $self->{LOGIN} = $DATA{LOGIN};

  $admin->{MODULE} = '';
  $admin->action_add("$self->{UID}", "LOGIN:$DATA{LOGIN}", { TYPE => 7 });

  if ($attr->{CREATE_BILL}) {
    $self->change(
      $self->{UID},
      {
        DISABLE         => int($DATA{DISABLE}),
        UID             => $self->{UID},
        CREATE_BILL     => 1,
        CREATE_EXT_BILL => $attr->{CREATE_EXT_BILL}
      }
    );
  }

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($uid, $attr) = @_;

  my %FIELDS = (
    UID            => 'uid',
    LOGIN          => 'id',
    ACTIVATE       => 'activate',
    EXPIRE         => 'expire',
    CREDIT         => 'credit',
    CREDIT_DATE    => 'credit_date',
    REDUCTION      => 'reduction',
    REDUCTION_DATE => 'reduction_date',
    SIMULTANEONSLY => 'logins',
    #COMMENTS       => 'comments',
    COMPANY_ID     => 'company_id',
    DISABLE        => 'disable',
    GID            => 'gid',
    PASSWORD       => 'password',
    BILL_ID        => 'bill_id',
    EXT_BILL_ID    => 'ext_bill_id',
    DOMAIN_ID      => 'domain_id',
    DELETED        => 'deleted'
  );

  my $old_info = $self->info($attr->{UID});

  if ($attr->{CREATE_BILL}) {
    use Bills;
    my $Bill = Bills->new($self->{db}, $admin, $CONF);
    $Bill->create({ UID => $self->{UID} });
    if ($Bill->{errno}) {
      $self->{errno}  = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }
    $attr->{BILL_ID} = $Bill->{BILL_ID};
    $attr->{DISABLE} = $old_info->{DISABLE};

    if ($attr->{CREATE_EXT_BILL}) {
      $Bill->create({ UID => $self->{UID} });
      if ($Bill->{errno}) {
        $self->{errno}  = $Bill->{errno};
        $self->{errstr} = $Bill->{errstr};
        return $self;
      }
      $attr->{EXT_BILL_ID} = $Bill->{BILL_ID};
    }
  }
  elsif ($attr->{CREATE_EXT_BILL}) {

    use Bills;
    my $Bill = Bills->new($self->{db}, $admin, $CONF);
    $Bill->create({ UID => $self->{UID} });
    $attr->{DISABLE} = $old_info->{DISABLE};

    if ($Bill->{errno}) {
      $self->{errno}  = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }
    $attr->{EXT_BILL_ID} = $Bill->{BILL_ID};
  }

  if (defined($attr->{CREDIT}) && $attr->{CREDIT} == 0) {
    $attr->{CREDIT_DATE} = '0000-00-00';
  }
  if (defined($attr->{REDUCTION}) && $attr->{REDUCTION} == 0) {
    $attr->{REDUCTION_DATE} = '0000-00-00';
  }

  if (!defined($attr->{DISABLE})) {
    $attr->{DISABLE} = 0;
  }

  #Make extrafields use
  $admin->{MODULE} = '';
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'users',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $old_info,
      DATA         => $attr,
      ACTION_ID    => $attr->{ACTION_ID},
    }
  );

  return $self->{result};
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{FULL_DELETE}) {
    my @clear_db = ('admin_actions', 'fees', 'payments', 'users_nas', 'users', 'users_pi', 'shedule');

    $self->{info} = '';
    foreach my $table (@clear_db) {
      $self->query2("DELETE from $table WHERE uid='$self->{UID}';", 'do');
      $self->{info} .= "$table, ";
    }

    $admin->{MODULE} = '';
    $admin->action_add($self->{UID}, "DELETE $self->{UID}:$self->{LOGIN}", { TYPE => 12 });
  }
  else {
    $self->change($self->{UID}, { DELETED => 1, ACTION_ID => 12, UID => $self->{UID} });
  }

  return $self->{result};
}

#**********************************************************
# list_allow nass
#**********************************************************
sub nas_list {
  my $self = shift;
  my $list;
  $self->query2("SELECT nas_id FROM users_nas WHERE uid='$self->{UID}';");

  if ($self->{TOTAL} > 0) {
    $list = $self->{list};
  }
  else {
    $self->query2("SELECT nas_id FROM tp_nas WHERE tp_id='$self->{TARIF_PLAN}';");
    $list = $self->{list};
  }

  return $list;
}

#**********************************************************
# list_allow nass
#**********************************************************
sub nas_add {
  my $self = shift;
  my ($nas) = @_;

  $self->nas_del();
  foreach my $line (@$nas) {
    $self->query2("INSERT INTO users_nas (nas_id, uid) VALUES ('$line', '$self->{UID}');", 'do');
  }

  $admin->action_add($self->{UID}, "NAS " . join(',', @$nas));
  return $self;
}

#**********************************************************
# nas_del
#**********************************************************
sub nas_del {
  my $self = shift;

  $self->query2("DELETE FROM users_nas WHERE uid='$self->{UID}';", 'do');
  return $self if ($self->{db}->err > 0);

  $admin->action_add($self->{UID}, "DELETE NAS");
  return $self;
}

#**********************************************************
#
#**********************************************************
sub bruteforce_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("INSERT INTO users_bruteforce (login, password, datetime, ip, auth_state) VALUES 
        ('$attr->{LOGIN}', '$attr->{PASSWORD}', now(), INET_ATON('$attr->{REMOTE_ADDR}'), '$attr->{AUTH_STATE}');", 'do'
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub bruteforce_list {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $GROUP = 'GROUP BY login';
  my $count = 'count(login)';

  if ($attr->{AUTH_STATE}) {
    push @WHERE_RULES, "auth_state='$attr->{AUTH_STATE}'";
  }

  if ($attr->{LOGIN}) {
    push @WHERE_RULES, "login='$attr->{LOGIN}'";
    $count = 'auth_state';
    $GROUP = '';
  }

  my $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if ($#WHERE_RULES > -1);
  my $list;

  if (!$attr->{CHECK}) {
    $self->query2("SELECT login, password, datetime, $count, INET_NTOA(ip) FROM users_bruteforce
      $WHERE
      $GROUP
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;"
    );
    $list = $self->{list};
  }

  $self->query2("SELECT count(DISTINCT login) AS total FROM users_bruteforce $WHERE;", undef, { INFO => 1 });

  return $list;
}

#**********************************************************
#
#**********************************************************
sub bruteforce_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = "";

  if ($attr->{DATE}) {
    $WHERE = "datetime < $attr->{DATE}";
  }
  else {
    $WHERE = "login='$attr->{LOGIN}'";
  }

  $self->query2("DELETE FROM users_bruteforce
   WHERE $WHERE;", 'do'
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub web_session_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("DELETE  FROM web_users_sessions WHERE uid='$attr->{UID}';", 'do');

  $self->query2("INSERT INTO web_users_sessions 
        (uid, datetime, login, remote_addr, sid, ext_info) VALUES 
        ('$attr->{UID}', UNIX_TIMESTAMP(), '$attr->{LOGIN}', INET_ATON('$attr->{REMOTE_ADDR}'), '$attr->{SID}',
        '$attr->{EXT_INFO}');", 'do'
  );

  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub web_session_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE;

  if ($attr->{SID}) {
    $WHERE = "WHERE sid='$attr->{SID}'";
  }
  else {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  $self->query2("SELECT uid, 
    datetime, 
    login, 
    INET_NTOA(remote_addr) AS remote_addr, 
    UNIX_TIMESTAMP() - datetime AS activate,
    sid
     FROM web_users_sessions
     $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub web_sessions_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $GROUP = 'GROUP BY login';
  my $count = 'count(login)';

  if ($attr->{AUTH_STATE}) {
    push @WHERE_RULES, "auth_state='$attr->{AUTH_STATE}'";
  }

  if ($attr->{LOGIN}) {
    push @WHERE_RULES, "login='$attr->{LOGIN}'";
    $count = 'auth_state';
    $GROUP = '';
  }

  my $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if ($#WHERE_RULES > -1);
  my $list;

  if (!$attr->{CHECK}) {
    $self->query2("SELECT uid, datetime, login, INET_NTOA(remote_addr), sid 
     FROM web_users_sessions
      $WHERE
      $GROUP
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
    );
    $list = $self->{list};
  }

  $self->query2("SELECT count(DISTINCT login) AS total FROM web_users_sessions $WHERE;", undef, {INFO => 1 });

  return $list;
}

#**********************************************************
#
#**********************************************************
sub web_session_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("DELETE FROM web_users_sessions
   WHERE sid='$attr->{SID}';", 'do'
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub info_field_add {
  my $self = shift;
  my ($attr) = @_;

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
  );

  $attr->{FIELD_TYPE} = 0 if (!$attr->{FIELD_TYPE});

  my $column_type  = $column_types[ $attr->{FIELD_TYPE} ];
  my $field_prefix = 'ifu';

  #Add field to table
  if ($attr->{COMPANY_ADD}) {
    $field_prefix = 'ifc';
    $self->query2("ALTER TABLE companies ADD COLUMN _" . $attr->{FIELD_ID} . " $column_type;", 'do');
  }
  else {
    $self->query2("ALTER TABLE users_pi ADD COLUMN _" . $attr->{FIELD_ID} . " $column_type;", 'do');
  }

  if (!$self->{errno} || ($self->{errno} && $self->{errno} == 3)) {
    if ($attr->{FIELD_TYPE} == 2) {
      $self->query2("CREATE TABLE _$attr->{FIELD_ID}_list (
       id smallint unsigned NOT NULL primary key auto_increment,
       name varchar(120) not null default 0
       )DEFAULT CHARSET=$CONF->{dbcharset};", 'do'
      );
    }
    elsif ($attr->{FIELD_TYPE} == 13) {
      $self->query2("CREATE TABLE `_$attr->{FIELD_ID}_file` (`id` int(11) unsigned NOT NULL PRIMARY KEY auto_increment,
         `filename` varchar(250) not null default '',
         `content_size` varchar(30) not null  default '',
         `content_type` varchar(250) not null default '',
         `content` longblob NOT NULL,
         `create_time` datetime NOT NULL default '0000-00-00 00:00:00') DEFAULT CHARSET=$CONF->{dbcharset};", 'do'
      );
    }

    $self->config_add(
      {
        PARAM     => $field_prefix . "_$attr->{FIELD_ID}",
        VALUE     => "$attr->{POSITION}:$attr->{FIELD_TYPE}:$attr->{NAME}:$attr->{USERS_PORTAL}",
        DOMAIN_ID => $admin->{DOMAIN_ID} || 0
      }
    );

  }

  return $self;
}

#**********************************************************
#
#**********************************************************
sub info_field_del {
  my $self = shift;
  my ($attr) = @_;

  my $sql = '';
  if ($attr->{SECTION} eq 'ifc') {
    $sql = "ALTER TABLE companies DROP COLUMN $attr->{FIELD_ID};";
  }
  else {
    $sql = "ALTER TABLE users_pi DROP COLUMN $attr->{FIELD_ID};";
  }

  $self->query2($sql, 'do');

  if (!$self->{errno} || $self->{errno} == 3) {
    $self->config_del("$attr->{SECTION}$attr->{FIELD_ID}");
  }

  return $self;
}

#**********************************************************
#
#**********************************************************
sub info_list_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("INSERT INTO $attr->{LIST_TABLE} (name) VALUES ('$attr->{NAME}');", 'do');

  return $self;
}

#**********************************************************
#
#**********************************************************
sub info_list_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("DELETE FROM $attr->{LIST_TABLE} WHERE id='$attr->{ID}';", 'do');

  return $self;
}

#**********************************************************
#
#**********************************************************
sub info_lists_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT id, name FROM $attr->{LIST_TABLE} ORDER BY name;",
  undef,
  $attr);

  return $self->{list};
}

#**********************************************************
# info_list__info()
#**********************************************************
sub info_list_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("select id, name FROM $attr->{LIST_TABLE} WHERE id='$id';", undef, { INFO => 1 });

  return $self;
}

#**********************************************************
# info_list_change()
#**********************************************************
sub info_list_change {
  my $self = shift;
  my ($id, $attr) = @_;

  my %FIELDS = (
    ID   => 'id',
    NAME => 'name'
  );

  my $old_info = $self->info_list_info($id, { LIST_TABLE => $attr->{LIST_TABLE} });

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => $attr->{LIST_TABLE},
      FIELDS       => \%FIELDS,
      OLD_INFO     => $old_info,
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# config_list()
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

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total FROM config $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# config_info()
#**********************************************************
sub config_info {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DOMAIN_ID} = 0 if (!$attr->{DOMAIN_ID});

  $self->query2("select param, value, domain_id FROM config WHERE param='$attr->{PARAM}' AND domain_id='$attr->{DOMAIN_ID}';", undef, { INFO => 1 });

  return $self;
}

#**********************************************************
# group_info()
#**********************************************************
sub config_change {
  my $self = shift;
  my ($param, $attr) = @_;

  my %FIELDS = (
    PARAM     => 'param',
    NAME      => 'value',
    DOMAIN_ID => 'domain_id'
  );

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'PARAM',
      TABLE        => 'config',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->config_info({ PARAMS => $param, DOMAIN_ID => $attr->{DOMAIN_ID} }),
      DATA         => $attr,
      %$attr
    }
  );

  return $self;
}

#**********************************************************
# group_add()
#**********************************************************
sub config_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("INSERT INTO config (param, value, domain_id) values ('$attr->{PARAM}', '$attr->{VALUE}', '$attr->{DOMAIN_ID}');", 'do');

  return $self;
}

#**********************************************************
# group_add()
#**********************************************************
sub config_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM config WHERE param='$id';", 'do');
  return $self;
}

#**********************************************************
# district_list()
#**********************************************************
sub district_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
      ['ID',          'INT',  'd.id'       ],
      ['NAME',        'STR',  'd.name'     ],
      ['COMMENTS',    'STR',  'd.comments' ],
    ],
    { WHERE => 1,
    }
    );

  $self->query2("SELECT d.id, d.name, d.country, d.city, zip, count(s.id) AS street_count, 
       d.coordx, d.coordy, d.zoom 
     FROM districts d
     LEFT JOIN streets s ON (d.id=s.district_id)
   $WHERE 
   GROUP BY d.id
   ORDER BY $SORT $DESC",
   undef,
   $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total FROM districts d $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# district_info()
#**********************************************************
sub district_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("select id, name, country, 
 city, zip, comments, coordx, coordy, zoom
  FROM districts WHERE id='$attr->{ID}';",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# district_info()
#**********************************************************
sub district_change {
  my $self = shift;
  my ($id, $attr) = @_;

  my %FIELDS = (
    ID       => 'id',
    NAME     => 'name',
    COUNTRY  => 'country',
    CITY     => 'city',
    ZIP      => 'zip',
    COMMENTS => 'comments',
    COORDX   => 'coordx',
    COORDY   => 'coordy',
    ZOOM     => 'zoom',
  );

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'districts',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->district_info({ ID => $id }),
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# district_add()
#**********************************************************
sub district_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add("districts", $attr);

  $admin->system_action_add("DISTRICT:$self->{INSERT_ID}:$attr->{NAME}", { TYPE => 1 }) if (!$self->{errno});
  return $self;
}

#**********************************************************
# district_del()
#**********************************************************
sub district_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM districts WHERE id='$id';", 'do');

  $admin->system_action_add("DISTRICT:$id", { TYPE => 10 }) if (!$self->{errno});
  return $self;
}

#**********************************************************
# street_list()
#**********************************************************
sub street_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
      ['NAME',        'STR',  's.name'],
      ['DISTRICT_ID', 'STR',  's.district_id' ],
    ],
    { WHERE => 1,
    }
    );

  my $EXT_TABLE        = '';
  my $EXT_FIELDS       = '';
  my $EXT_TABLE_TOTAL  = '';
  my $EXT_FIELDS_TOTAL = '';
  if ($attr->{USERS_INFO} && !$admin->{MAX_ROWS}) {
    $EXT_TABLE        = 'LEFT JOIN users_pi pi ON (b.id=pi.location_id)';
    $EXT_FIELDS       = ', count(pi.uid) AS users_count';
    $EXT_TABLE_TOTAL  = 'LEFT JOIN builds b ON (b.street_id=s.id) LEFT JOIN users_pi pi ON (b.id=pi.location_id)';
    $EXT_FIELDS_TOTAL = ', count(DISTINCT b.id), count(pi.uid), sum(b.flats) / count(pi.uid)';
  }

  my $sql = "SELECT s.id, s.name AS street_name, 
    d.name AS disctrict_name, 
    count(DISTINCT b.id) AS build_count $EXT_FIELDS FROM streets s
  LEFT JOIN districts d ON (s.district_id=d.id)
  LEFT JOIN builds b ON (b.street_id=s.id)
  $EXT_TABLE 
  $WHERE 
  GROUP BY s.id
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;";

  $self->query2($sql, undef, $attr);

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    my $sql = "SELECT count(DISTINCT s.id) $EXT_FIELDS_TOTAL FROM streets s 
     $EXT_TABLE_TOTAL  $WHERE";
    $self->query2($sql);
    ($self->{TOTAL}, $self->{TOTAL_BUILDS}, $self->{TOTAL_USERS}, $self->{DENSITY_OF_CONNECTIONS}) = @{ $self->{list}->[0] };
  }

  return $list;
}

#**********************************************************
# street_info()
#**********************************************************
sub street_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("select id, name, district_id FROM streets WHERE id='$attr->{ID}';", undef, { INFO => 1 });

  return $self;
}

#**********************************************************
# street_change()
#**********************************************************
sub street_change {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'streets',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# street_add()
#**********************************************************
sub street_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add("streets", $attr);

  $admin->system_action_add("STREET:$self->{INSERT_ID}:$attr->{NAME}", { TYPE => 1 }) if (!$self->{errno});
  return $self;
}

#**********************************************************
# street_del()
#**********************************************************
sub street_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM streets WHERE id='$id';", 'do');

  $admin->system_action_add("STREET:$id", { TYPE => 10 }) if (!$self->{errno});
  return $self;
}

#**********************************************************
# build_list()
#**********************************************************
sub build_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();
  
  if ($SORT == 1 && $DESC eq '') {
    $SORT = "length(b.number), b.number";
  }

  if ($attr->{SHOW_MAPS_GOOGLE}) {
    $self->{SEARCH_FIELDS} = ",b.coordx, b.coordy";
    push @WHERE_RULES, "(b.coordx<>0 and b.coordy)";
  }

  my $WHERE = $self->search_former($attr, [
      ['NUMBER',      'STR', 'b.number'      ],
      ['DISTRICT_ID', 'INT', 's.district_id' ],
      ['STREET_ID',   'INT', 'b.street_id'   ],
      ['FLORS',       'INT', 'b.flors'       ],
      ['ENTRANCES',   'INT', 'b.entrances'   ],
      ['SHOW_MAPS',   '', '', 'b.map_x, b.map_y, b.map_x2, b.map_y2, b.map_x3, b.map_y3, b.map_x4, b.map_y4' ],
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }
    );


  my $sql = '';
  if ($attr->{CONNECTIONS}) {
    $sql = "SELECT b.number, b.flors, b.entrances, b.flats, s.name AS street_name, 
     count(pi.uid) AS users_count, ROUND((count(pi.uid) / b.flats * 100), 0) AS users_connections,
     b.added, $self->{SEARCH_FIELDS} b.id

      FROM builds b
     LEFT JOIN streets s ON (s.id=b.street_id)
     LEFT JOIN users_pi pi ON (b.id=pi.location_id)
     $WHERE 
     GROUP BY b.id
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS
     ;";
  }
  else {
    $sql = "SELECT b.number, b.flors, b.entrances, b.flats, s.name, b.added, $self->{SEARCH_FIELDS} b.id FROM builds b
     LEFT JOIN streets s ON (s.id=b.street_id)
     $WHERE ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;";
  }

  $self->query2("$sql", undef, $attr);
  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total FROM builds b 
    LEFT JOIN streets s ON (s.id=b.street_id)
    $WHERE",
    undef,
    { INFO => 1 }
    );
  }
  return $list;
}

#**********************************************************
# build_info()
#**********************************************************
sub build_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("select * FROM builds WHERE id='$attr->{ID}';",
 undef,
 { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# build_change()
#**********************************************************
sub build_change {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'builds',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# build_add()
#**********************************************************
sub build_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('builds', $attr);

  $admin->system_action_add("BUILD:$self->{INSERT_ID}:$attr->{NAME}", { TYPE => 1 }) if (!$self->{errno});
  return $self;
}

#**********************************************************
# build_del()
#**********************************************************
sub build_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM builds WHERE id='$id';", 'do');

  $admin->system_action_add("BUILD:$id", { TYPE => 10 }) if (!$self->{errno});
  return $self;
}


1
