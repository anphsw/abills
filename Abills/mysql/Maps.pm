package Maps;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.05;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");
my $CONF;

#**********************************************************
# Init Maps module
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  
  my $self = { };
  bless($self, $class);

  $self->{db}=$db;
  return $self;
}


#**********************************************************
# Districts list
#**********************************************************
sub districts_list {
  my $self = shift;
  my ($attr) = @_;
  
  my @WHERE_RULES  = ();
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  
  if(defined($attr->{ID})) {
    push @WHERE_RULES, "d.id = '$attr->{ID}'";
  }
 
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
  $self->query2("SELECT d.id, 
                        d.name,
                        d.country, 
                        d.city, 
                        d.zip,  
                        d.coordx, 
                        d.coordy, 
                        d.zoom
                        FROM districts AS d 
                        $WHERE
                        ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr);
  
  return $self->{list};
}


#**********************************************************
# Del districts
#**********************************************************
sub del_districts {
  my $self = shift;
  my ($attr) = @_; 

  $self->query2("UPDATE districts SET 
     coordy = '0', 
     coordx = '0', 
     zoom   = '0' 
    WHERE id = $attr->{ID};", 'do');

  return $self;
}

#**********************************************************
# Del build
#**********************************************************
sub del_build {
  my $self = shift;
  my ($attr) = @_; 
 
  $self->query2("UPDATE builds SET 
   coordy = '0', 
   coordx = '0' 
  WHERE id = '$attr->{BUILD_ID}';", 'do');
 
  $self->query2("DELETE FROM maps_wifi_zones WHERE coordx = '$attr->{DCOORDX}' AND coordy = '$attr->{DCOORDY}' ;   ", 'do');
  $self->query2("DELETE FROM maps_wells WHERE coordx = '$attr->{DCOORDX}' AND coordy = '$attr->{DCOORDY}' ;   ", 'do');
  $self->query2("DELETE FROM maps_routes_coords WHERE coordx = '$attr->{DCOORDX}' AND coordy = '$attr->{DCOORDY}' ;   ", 'do');
 
  return $self;
}

#**********************************************************
# users online list
#**********************************************************
sub users_online_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES  = ("status=1 or status=3");

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


   my $WHERE =  $self->search_former($attr, [
      ['ID',      'INT', 'd.id'       ],
      ['UID',     'INT', 'c.uid',     ],
    ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    }    
    );

  $self->query2("SELECT c.user_name AS login,  
      INET_NTOA(c.framed_ip_address) AS ip, 
      c.uid
    FROM `dv_calls` c
    $WHERE  
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr);

  return $self->{list};
}


#**********************************************************
# all users list
#**********************************************************
sub all_users_list {
  my $self = shift;
  my ($attr) = @_;
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
   $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  
   my $WHERE =  $self->search_former($attr, [
      ['ID',             'INT', 'd.id'       ],
      ['GID',            'INT', 'u.gid'      ],
      ['DISABLE',        'INT', 'u.disable', ],
      ['UID',            'INT', 'u.uid',     ],
    ],
    { WHERE => 1,
    }    
    );

  $self->query2("SELECT u.id AS login, 
                  pi.fio, 
                  ROUND(if(company.id IS NULL,b.deposit,cb.deposit),2) AS deposit,  
                  streets.name AS street_name, 
                  builds.number, 
                  builds.id AS build_id, 
                  pi.address_flat, 
                  u.uid, 
                  u.company_id, 
                  pi.email, 
                  u.activate, 
                  u.expire 
                FROM users u 
              LEFT JOIN users_pi pi ON (u.uid = pi.uid) 
              LEFT JOIN bills b ON (u.bill_id = b.id) 
              LEFT JOIN companies company ON (u.company_id=company.id) 
              LEFT JOIN bills cb ON (company.bill_id=cb.id) 
              LEFT JOIN builds ON (builds.id=pi.location_id) 
              LEFT JOIN streets ON (streets.id=builds.street_id)
              $WHERE 
            ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;

",
 undef,
 $attr); 
            
          
  return $self->{list};
}


#**********************************************************
# builds online list
#**********************************************************
sub build_online_list {
  my $self = shift;
  my ($attr) = @_;
  
  my @WHERE_RULES  = ("pi.uid = up.uid");
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  
  if(defined($attr->{ID})) {
    push @WHERE_RULES, "d.id = '$attr->{ID}'";
  }
  if(defined($attr->{DISTRICT_ID})) {
      push @WHERE_RULES, "s.district_id = '$attr->{DISTRICT_ID}'";
  }
  
   $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';


  $self->query2("SELECT  
                  b.number, 
                  s.name,  
                  b.map_x, 
                  b.map_y,
                  b.map_x2, 
                  b.map_y2,
                  b.map_x3, 
                  b.map_y3,
                  b.map_x4, 
                  b.map_y4 
                FROM 
                  users_pi pi 
                INNER JOIN dv_calls AS up  
                LEFT JOIN builds b ON (b.id=pi.location_id)
                LEFT JOIN streets s ON (s.id=b.street_id)
                $WHERE                         
              ORDER BY pi.location_id $DESC LIMIT $PG, $PAGE_ROWS;");

  return $self->{list};
}



#**********************************************************
# Nas list
#**********************************************************
sub nas_list {
 my $self = shift;
 my ($attr) = @_;

  my @WHERE_RULES  = ();

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $ext_fields = '';
  my $EXT_TABLES = '';
  if ($attr->{SHOW_MAPS_GOOGLE}) {
    $ext_fields = ",b.coordx, b.coordy";
    $EXT_TABLES = "INNER JOIN builds b ON (b.id=nas.location_id)";
    if ($attr->{DISTRICT_ID}) {
     push @WHERE_RULES, @{ $self->search_expr($attr->{DISTRICT_ID}, 'INT', 'streets.district_id', { EXT_FIELD => 'districts.name' }) };
     $EXT_TABLES .= "LEFT JOIN streets ON (streets.id=b.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
    }    
   }
  elsif ($attr->{SHOW_MAPS}) {
    $ext_fields = ",b.map_x, b.map_y, b.map_x2, b.map_y2, b.map_x3, b.map_y3, b.map_x4, b.map_y4";
    $EXT_TABLES = "INNER JOIN builds b ON (b.id=nas.location_id)";
    if ($attr->{DISTRICT_ID}) {
     push @WHERE_RULES, @{ $self->search_expr($attr->{DISTRICT_ID}, 'INT', 'streets.district_id', { EXT_FIELD => 'districts.name' }) };
     $EXT_TABLES .= "LEFT JOIN streets ON (streets.id=b.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
    }    
   }


  if(defined($attr->{TYPE})) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{TYPE}, 'STR', 'nas.nas_type') };
  }

  if(defined($attr->{DISABLE})) {
    push @WHERE_RULES, "nas.disable='$attr->{DISABLE}'";
  }

  if($attr->{NAS_IDS}) {
    push @WHERE_RULES, "nas.id IN ($attr->{NAS_IDS})";
  }

  if($attr->{DOMAIN_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DOMAIN_ID}, 'INT', 'nas.domain_id') };
   }

  if($attr->{MAC}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{MAC}, 'INT', 'nas.mac') };
   }

  if($attr->{GID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{GID}, 'INT', 'nas.gid') };
   }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query2("SELECT nas.id as nas_id, 
  nas.name as nas_name, 
  nas.nas_identifier, 
  nas.ip,  
  nas.nas_type, 
  ng.name,
  nas.disable, 
  nas.descr, 
  nas.alive,
  nas.mng_host_port, 
  nas.mng_user, 
  nas.rad_pairs, 
  nas.ext_acct,
  nas.auth_type
  $ext_fields,
  nas.mac
  FROM nas
  LEFT JOIN nas_groups ng ON (ng.id=nas.gid)
  $EXT_TABLES
  $WHERE
  ORDER BY $SORT $DESC;",
  undef,
  $attr);

 return $self->{list};
}

#**********************************************************
# list maps_routes
#**********************************************************
sub list_routes {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES  = ();  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  
  my $ext_fields = '';

  if(defined($attr->{ID})) {
    push @WHERE_RULES, "r.id='$attr->{ID}'";
  } 
    
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
  $self->query2("SELECT   r.id,
                r.name, 
                r.type, 
                r.descr, 
                r.nas1, 
                r.nas2,
                r.nas1_port,
                r.nas2_port,
                r.length
                FROM maps_routes AS r
              
                $WHERE
                ORDER BY $SORT $DESC;");

  return $self->{list};
}

#**********************************************************
# Route info
#**********************************************************
sub route_info {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);
  my @WHERE_RULES  = ();  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if(defined($attr->{ID})) {
    push @WHERE_RULES, "id='$attr->{ID}'";
  } 

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

  $self->query2("SELECT id,
      name, 
      type, 
      descr, 
      nas1, 
      nas2,
      nas1_port,
      nas2_port,
      length
      FROM maps_routes 
      $WHERE
      ORDER BY $SORT $DESC;",
   undef, { INFO => 1 });
  
  return $self;  
}




#**********************************************************
# Add route
#**********************************************************
sub add_route {
  my $self = shift;
  my ($attr) = @_;
   
   $self->query_add('maps_routes', $attr);
  return 0;  
}


#**********************************************************
# Del note
#**********************************************************
sub del_route {
  my $self = shift;
  my ($attr) = @_;

  $WHERE = '';
  my @WHERE_RULES  = ();  
  

  if ($attr->{ID}) {
    push @WHERE_RULES,  "id='$attr->{ID}' ";
  }

  if ($#WHERE_RULES > -1) {
    $WHERE = join(' and ', @WHERE_RULES);
    $self->query2("DELETE from maps_routes WHERE $WHERE;", 'do');
  }
  return $self->{result};
}

#**********************************************************
#  route change
#**********************************************************
sub route_change {
  my $self = shift;
  my ($attr) = @_; 
 
  $self->changes($admin,  {  CHANGE_PARAM => 'ID',
                TABLE        => 'maps_routes',
                DATA         => $attr,
                 } 
     );

  return $self;
}

#**********************************************************
# Add route info
#**********************************************************
sub add_route_info {
  my $self = shift;
  my ($attr) = @_;

   $self->query_add('maps_routes_coords', $attr);
   
   return 0;  
}

#**********************************************************
# list route info
#**********************************************************
sub list_route_info {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES  = ();  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  
  my $ext_fields = '';

  if(defined($attr->{ID})) {
    push @WHERE_RULES, "rc.routes_id='$attr->{ID}'";
  } 
    
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
  $self->query2("SELECT   rc.id,
                rc.routes_id, 
                rc.coordx, 
                rc.coordy 
                FROM maps_routes_coords AS rc
              
                $WHERE
                ORDER BY $SORT $DESC;");

  return $self->{list};
}

#**********************************************************
# list wifi zones
#**********************************************************
sub list_wifi {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES  = ();  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  
  my $ext_fields = '';

  if(defined($attr->{ID})) {
    push @WHERE_RULES, "r.id='$attr->{ID}'";
  } 
    
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
  $self->query2("SELECT   id,
                radius, 
                coordx,
                coordy
                FROM maps_wifi_zones 
              
                $WHERE
                ORDER BY $SORT $DESC;");

  return $self->{list};
}



#**********************************************************
# Add WiFi
#**********************************************************
sub add_wifi {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('maps_wifi_zones', {%$attr});

  return $self;  
}

#**********************************************************
# list wells
#**********************************************************
sub list_wells {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES  = ();  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if(defined($attr->{ID})) {
    push @WHERE_RULES, "r.id='$attr->{ID}'";
  } 
    
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
  $self->query2("SELECT   id,
      name, 
      coordx,
      coordy,
      comment
      FROM maps_wells 
      
      $WHERE
      ORDER BY $SORT $DESC;");

  return $self->{list};
}




#**********************************************************
# Add Well
#**********************************************************
sub add_well {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('maps_wells', {%$attr});

  return $self;  
}

1