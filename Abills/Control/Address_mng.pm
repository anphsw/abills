=head1 NAME

  Address Manage functions

=cut


use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array load_pmodule);
use Address;

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html,
  @bool_vals,
  $users
);

my $Address = Address->new( $db, $admin, \%conf );

#**********************************************************
=head2 form_districts()

=cut
#**********************************************************
sub form_districts{
  $Address->{ACTION} = 'add';
  $Address->{LNG_ACTION} = "$lang{ADD}";

  if ( $FORM{IMPORT} ){
    my @rows = split( /[\r\n]+/, $FORM{IMPORT}{Contents} );
    my %steets_ids = ();
    my $counts = 0;
    foreach my $line ( @rows ){
      my %info = ();
      ($info{STREET_NAME},
        $info{NUMBER},
        $info{FLORS},
        $info{ENTRANCES},
        $info{FLATS},
        $info{CONTRACT_ID},
        $info{CONTRACT_DATE},
        $info{CONTRACT_PRICE},
        $info{COMMENTS}
      ) = split( /\t/, $line );

      while(my (undef, $v) = each %info) {
        $v =~ s/^\"|\"$//g if($v);
      }

      #Get street id
      if ( !$steets_ids{$info{STREET_NAME}} ){
        my $list = $Address->street_list( {
          STREET_NAME => $info{STREET_NAME},
          COLS_NAME   => 1
        } );

        if ( $Address->{TOTAL} > 0 ){
          $info{STREET_ID} = $list->[0]->{id};
        }
        else{
          $Address->street_add( {
            NAME        => $info{STREET_NAME},
            DISTRICT_ID => $FORM{ID}
          } );

          if ( _error_show( $Address ) ){
            last;
          }

          $info{STREET_ID} = $Address->{INSERT_ID};
        }

        $steets_ids{$info{STREET_NAME}} = $info{STREET_ID};
      }
      else{
        $info{STREET_ID} = $steets_ids{$info{STREET_NAME}};
      }

      $Address->build_add( \%info );
      _error_show( $Address );

      $counts++;
    }
    $html->message( 'info', $lang{IMPORT}, "$lang{ADDED}: $counts" );
  }
  elsif ( $FORM{IMPORT_ADDRESS} ) {
    form_address({ IMPORT_ADDRESS => 1 });
    return 0;
  }
  elsif ( $FORM{add} && $FORM{NAME} ){
    $Address->district_add( { %FORM } );

    if ( !$Address->{errno} ){
      if ( $FORM{FILE_UPLOAD} ){
        my $name = '';
        if ( $FORM{FILE_UPLOAD}{filename} && $FORM{FILE_UPLOAD}{filename} =~ /\.(\S+)$/i ){
          $name = $Address->{INSERT_ID} . '.' . lc( $1 );
        }
        upload_file( $FORM{FILE_UPLOAD}, { PREFIX => 'maps', FILE_NAME => $name, REWRITE => 1 } );
      }

      $html->message( 'info', $lang{DISTRICT}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{change} ){
    $Address->district_change( \%FORM );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{DISTRICTS}, "$lang{CHANGED}" );
      if ( $FORM{FILE_UPLOAD} ){
        my $name = '';
        if ( $FORM{FILE_UPLOAD}{filename} && $FORM{FILE_UPLOAD}{filename} =~ /\.([a-z0-9]+)$/i ){
          $name = $FORM{ID} . '.' . lc( $1 );
        }

        upload_file( $FORM{FILE_UPLOAD}, { PREFIX => 'maps', FILE_NAME => $name, REWRITE => 1 } );
      }
    }
  }
  elsif ( $FORM{chg} ){
    $Address->district_info( { ID => $FORM{chg} } );

    if ( !$Address->{errno} ){
      $Address->{ACTION} = 'change';
      $Address->{LNG_ACTION} = "$lang{CHANGE}";
      $FORM{add_form} = 1;
      $html->message( 'info', $lang{DISTRICTS}, "$lang{CHANGING}" );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Address->district_del( $FORM{del} );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{DISTRICTS}, "$lang{DELETED}" );
    }
  }

  _error_show( $Address );

  my $countries_hash;
  ($countries_hash, $Address->{COUNTRY_SEL}) = sel_countries( { COUNTRY => $Address->{COUNTRY} } );

  if ( $FORM{add_form} ){
    $html->tpl_show( templates( 'form_district' ), $Address );
  }

  my $list = $Address->district_list({ %LIST_PARAMS, COLS_NAME => 1 });
  my $table = $html->table({
    width      => '100%',
    caption    => $lang{DISTRICTS},
    title      => [ "#", $lang{NAME}, $lang{COUNTRY}, $lang{CITY}, $lang{ZIP}, $lang{STREETS}, $lang{MAP}, '-' ],
    ID         => 'DISTRICTS_LIST',
    FIELDS_IDS => $Address->{COL_NAMES_ARR},
    EXPORT     => 1,
    IMPORT     => "$SELF_URL?get_index=form_districts&import=1&header=2&IMPORT_ADDRESS=1",
    MENU       => "$lang{ADD}:index=$index&add_form=1:add",
  });

  my $two_confirmation = '';
      
  if ($conf{TWO_CONFIRMATION}) {
    $two_confirmation = $lang{DEL};
  }

  foreach my $line ( @{$list} ){
    my $map = $bool_vals[0];

    $map = form_add_map(undef, { DISTRICT_ID => $line->{id} });

    $table->addrow(
      $line->{id},
      $line->{name},
      ($line->{country} && $countries_hash->{ $line->{country} })  ? $countries_hash->{ $line->{country} } : q{},
      $line->{city},
      $line->{zip},
      $html->button( $line->{street_count},
        "index=" . get_function_index( 'form_streets' ) . "&DISTRICT_ID=$line->{id}" ),
      $map,
      $html->button( $lang{CHANGE}, "index=$index&chg=$line->{id}", { class => 'change' } )
      .' '. $html->button( $lang{DEL}, "index=$index&del=$line->{id}",
        { MESSAGE => "$lang{DEL} [$line->{id}] $line->{name}?", class => 'del', TWO_CONFIRMATION  => $two_confirmation } )
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_streets() - Street list

=cut
#**********************************************************
sub form_streets{

  $Address->{ACTION} = 'add';
  $Address->{LNG_ACTION} = "$lang{ADD}";

  if ( $FORM{BUILDS} ){
    form_builds();
    return 0;
  }
  elsif ( $FORM{add} ){
    $Address->street_add( { %FORM } );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_STREET}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{change} ){
    $Address->street_change( \%FORM );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_STREET}, "$lang{CHANGED}" );
    }
  }
  elsif ( $FORM{chg} ){
    $Address->street_info( { ID => $FORM{chg} } );

    if ( !$Address->{errno} ){
      $Address->{ACTION} = 'change';
      $Address->{LNG_ACTION} = "$lang{CHANGE}";
      $html->message( 'info', $lang{ADDRESS_STREET}, "$lang{CHANGING}" );
      $FORM{add_form} = 1;
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Address->street_del( $FORM{del} );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_STREET}, "$lang{DELETED}" );
    }
  }
  _error_show( $Address );

  $Address->{DISTRICTS_SEL} = sel_districts({ DISTRICT_ID => $Address->{DISTRICT_ID} });

  if ( $FORM{add_form} ){
    if ($conf{STREET_TYPE}) {
      $Address->{STREET_TYPE_SELECT} = _street_type_select($Address->{TYPE});
      $Address->{STREET_TYPE_VISIBLE} = 1;
    }
    $html->tpl_show( templates( 'form_street' ), $Address );
  }

  if ( $FORM{DISTRICT_ID} ){
    $LIST_PARAMS{DISTRICT_ID} = $FORM{DISTRICT_ID};
    $pages_qs .= "&DISTRICT_ID=$LIST_PARAMS{DISTRICT_ID}";
    $Address->district_info({ ID => $FORM{DISTRICT_ID} }) if(! $FORM{chg});
  }

  #$html->tpl_show(templates('form_street_search'), $Address);
  if($FORM{search_form}){
    form_search({ SEARCH_FORM => $html->tpl_show(templates('form_street_search'),
                                  { %$Address,  %FORM },
                                  { OUTPUT2RETURN => 1 }),
      PLAIN_SEARCH_FORM => 1});
  }

  if ( !$FORM{sort} ){
    $LIST_PARAMS{SORT} = 2;
  }

  my Abills::HTML $table;
  ($table) = result_former( {
    INPUT_DATA      => $Address,
    FUNCTION        => 'street_list',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'ID,STREET_NAME,BUILD_COUNT,USERS_COUNT',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    FILTER_COLS     => {
      build_count => 'form_show_link:ID:ID,add=1',
      users_count => 'search_link:form_search:STREET_ID,type=11',
    },
    EXT_TITLES      => {
      street_name   => $lang{NAME},
      district_name => $lang{DISTRICT},
      second_name   => $lang{SECOND_NAME},
      build_count   => $lang{BUILDS},
      users_count   => $lang{USERS}
    },
    TABLE           => {
      caption => $lang{STREETS}.': '. ($Address->{NAME} || q{}),
      qs      => $pages_qs,
      ID      => 'STREETS_LIST',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1&DISTRICT_ID=" . ($FORM{DISTRICT_ID} || '') . ":add; $lang{SEARCH}:index=$index&search_form=1&DISTRICT_ID=" . ($FORM{DISTRICT_ID} || '') . ":search",
      SHOW_COLS_HIDDEN => {
        DISTRICT_ID => $FORM{DISTRICT_ID}
      }
    },
    MAKE_ROWS       => 1,
  } );

  print $table->show();
  $table = $html->table(
    {
      rows       => [ [
        "$lang{STREETS}: " . $html->b( $Address->{TOTAL} ),
        "$lang{BUILDS}: " . $html->b( $Address->{TOTAL_BUILDS} || 0 ),
        "$lang{USERS}: " . $html->b( $Address->{TOTAL_USERS} || 0),
        "$lang{DENSITY_OF_CONNECTIONS}: " . $html->b( $Address->{DENSITY_OF_CONNECTIONS} || 0 )
      ] ]
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_builds() - Build managment

=cut
#**********************************************************
sub form_builds{

  $Address->{ACTION} = 'add';
  $Address->{LNG_ACTION} = "$lang{ADD}";

  my $maps_enabled = in_array( 'Maps2', \@MODULES );

  if ( !$FORM{qindex} && !$FORM{xml} && $FORM{BUILDS} ){
    my @header_arr = (
      "$lang{INFO}:index=$index&BUILDS=$FORM{BUILDS}" . (($FORM{chg}) ? "&chg=$FORM{chg}" : ''),
      "Media:index=$index&media=1&BUILDS=$FORM{BUILDS}" . (($FORM{chg}) ? "&chg=$FORM{chg}" : '')
    );

    print $html->table_header( \@header_arr, { TABS => 1 } );
  }

  if ( $FORM{media} ){
    form_location_media();
    return 1;
  }

  if ( $FORM{add} ){
    $Address->build_add( { %FORM } );

    if ( !$Address->{errno} ){

      $html->message( 'info', $lang{ADDRESS_BUILD},
        "$lang{ADDED}\n " );
    }
  }
  elsif ( $FORM{change} ){
    $FORM{PLANNED_TO_CONNECT} = $FORM{PLANNED_TO_CONNECT} ? $FORM{PLANNED_TO_CONNECT} : 0;
    $FORM{NUMBERING_DIRECTION} = $FORM{NUMBERING_DIRECTION} ? $FORM{NUMBERING_DIRECTION} : 0;
    $Address->build_change( \%FORM );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{CHANGED}" );
    }
  }
  elsif ( $FORM{chg} ){
    $Address->build_info( { ID => $FORM{chg} } );
    if ( !$Address->{errno} ){
      $Address->{PLANNED_TO_CONNECT_CHECK}=$Address->{PLANNED_TO_CONNECT}?'checked':'';
      $Address->{NUMBERING_DIRECTION_CHECK}=$Address->{NUMBERING_DIRECTION}?'checked':'';
      $Address->{ACTION} = 'change';
      $Address->{LNG_ACTION} = "$lang{CHANGE}";
      $FORM{add_form} = 1;
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{CHANGING}" );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Address->build_del( $FORM{del} );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{DELETED}" );
    }
  }

  _error_show( $Address );

  if ( $FORM{add_form} ){
    if ( $maps_enabled && $FORM{chg} ) {
      $Address->{MAP_BLOCK_VISIBLE} = 1;
    }
    $Address->{STREET_SEL} = sel_streets($Address);
    $html->tpl_show( templates( 'form_build' ), $Address );
  }

  my $street_name = '';
  if ($FORM{BUILDS}){
    $pages_qs .= "&BUILDS=$FORM{BUILDS}";

    my $street_list = $Address->street_list( {
      ID          => $FORM{BUILDS},
      STREET_NAME => '_SHOW',
      SECOND_NAME => '_SHOW',
      PAGE_ROWS   => 1,
      COLS_NAME   => 1
    } );

    if (!$Address->{errno} && $street_list && $street_list->[0]){
      $street_name = " : " . $street_list->[0]{street_name}
        . ( ($street_list->[0]{second_name}) ? " ( $street_list->[0]{second_name} )" : '');
    }
  }

  $LIST_PARAMS{DISTRICT_ID} = $FORM{DISTRICT_ID} if ($FORM{DISTRICT_ID});
  $LIST_PARAMS{STREET_ID} = $FORM{BUILDS};
  $LIST_PARAMS{PLANNED_TO_CONNECT}  = $FORM{PLANNED_TO_CONNECT};
  $LIST_PARAMS{NUMBERING_DIRECTION} = $FORM{NUMBERING_DIRECTION};

  my @status_bar = (
    "$lang{PLANNED_TO_CONNECT}:index=$index&BUILDS=" . ($FORM{BUILDS} || '') . "&PLANNED_TO_CONNECT=1",
    "$lang{ALL}:index=$index&BUILDS=" . ($FORM{BUILDS} || '')
  );

  result_former( {
    INPUT_DATA      => $Address,
    FUNCTION        => 'build_list',
    MAP             => 1,
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  =>
    'NUMBER,BLOCK,FLORS,ENTRANCES,FLATS,STREET_NAME,USERS_COUNT,USERS_CONNECTIONS,ADDED' . ($maps_enabled ? ',COORDX' : ''),
    FUNCTION_FIELDS => 'msgs_admin:$lang{MESSAGE}:location_id:&add_form=1,change,del',
    EXT_TITLES      => {
      number              => $lang{NUM},
      flors               => $lang{FLORS},
      entrances           => $lang{ENTRANCES},
      flats               => $lang{FLATS},
      street_name         => $lang{STREET},
      users_count         => $lang{USERS},
      users_connections   => "$lang{DENSITY_OF_CONNECTIONS} %",
      added               => $lang{ADDED},
      location_id         => 'LOCATION ID',
      coordx              => $lang{MAP},
      planned_to_connect  => $lang{PLANNED_TO_CONNECT},
      block               => $lang{BLOCK}
    },
    SKIP_USER_TITLE => 1,
    FILTER_COLS     => {
      users_count => 'search_link:form_search:LOCATION_ID,type=11',
      coordx      => 'form_add_map:ID:ID,COORDX,add=1',
      number      =>  in_array( 'Dom', \@MODULES )?'form_show_construct:ID:ID,':'',
    },
    # for button MESSAGE
    FILTER_VALUES => {
      street_name => sub {
        my ($number, $line) = @_;
        $line->{location_id} = $line->{id};
        return $number;
      }
    },
    TABLE           => {
      width            => '100%',
      caption          => $lang{BUILDS} . $street_name,
      qs               => $pages_qs,
      ID               => 'BUILDS_LIST',
      header           => $html->table_header(\@status_bar),
      EXPORT           => 1,
      SHOW_COLS_HIDDEN => { 'BUILDS' => $FORM{BUILDS} },
      MENU             => "$lang{ADD}:index=$index&add_form=1&BUILDS=$FORM{BUILDS}:add",
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}


#**********************************************************
=head2 form_show_construct()

=cut
#**********************************************************
sub form_show_construct{
  my ($id,$attr) = @_;

  return $html->button( $id, "index=". get_function_index('dom_info') ."&LOCATION_ID=$attr->{VALUES}->{ID}" );
}

#**********************************************************
=head2 form_show_link()

=cut
#**********************************************************
sub form_show_link{
  my ($params, $attr) = @_;

  return $html->button( $params, "index=$index&BUILDS=$attr->{VALUES}->{ID}" );
}

#**********************************************************
=head2 form_location_media($attr)

=cut
#**********************************************************
sub form_location_media{

  if ( $FORM{show} ){
    $Address->location_media_info( { ID => $FORM{show} } );
    print "Content-Type: $Address->{CONTENT_TYPE}\n\n";
    print "$Address->{CONTENT}";
    return 1;
  }
  elsif ( $FORM{add} ){
    $Address->location_media_add( {
        %FORM,
        LOCATION_ID  => $FORM{chg},
        CONTENT      => $FORM{FILE}{Contents},
        FILESIZE     => $FORM{FILE}{Size},
        FILENAME     => $FORM{FILE}{filename},
        CONTENT_TYPE => $FORM{FILE}{'Content-Type'},
      } );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Address->location_media_del( $FORM{del} );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{DELETED}" );
    }
  }

  _error_show( $Address );

  $html->tpl_show( templates( 'form_location_media' ), $Address );

  my $list = $Address->location_media_list( { LOCATION_ID => $FORM{chg}, COLS_NAME => 1 } );

  foreach my $line ( @{$list} ){
    my $del_btn = $html->button( $lang{DEL}, "index=$index&media=1&chg=$FORM{chg}&BUILDS=$FORM{BUILDS}&del=$line->{id}",
      {
        MESSAGE => "$lang{DEL} [$line->{id}] $line->{comments}?", class => 'del' } );

    #Fixme mktpl
    print "<div class='row'>
    <div class='col-md-4'>
    ID: $line->{id} <br>
    $lang{COMMENTS}: $line->{comments} <br>
    $lang{FILE}: $line->{filename} <br>
    $del_btn
    </div>
    <div class='col-md-8 bg-success'>
      <img src='$SELF_URL?qindex=$index&media=1&chg=$FORM{chg}&BUILDS=$FORM{BUILDS}&show=$line->{id}'>
    </div>
    </div>\n";
  }

  return 1;
}

#**********************************************************
=head2 form_add_map($coordx, $attr)

=cut
#**********************************************************
sub form_add_map {
  my (undef, $attr) = @_;

  return '' if ((!$attr->{VALUES}->{ID} || !$attr->{DISTRICT_ID}) && !in_array('Maps2', \@MODULES));
  load_module('Maps2');

  my $map_index = get_function_index('maps2_main');
  my $icon = 'glyphicon glyphicon-globe';

  if ($attr->{DISTRICT_ID}) {
    require Maps;
    Maps->import();
    my $Maps = Maps->new($db, $admin, \%conf);

    my $district_info = $Maps->districts_list({
      DISTRICT_ID => $attr->{DISTRICT_ID},
      OBJECT_ID   => '_SHOW'
    });

    my $object_id = ($Maps->{TOTAL}) ? ($district_info->[0]{object_id} || q{}) : '';
    my $link = "index=$map_index&LAYER=4&OBJECT_ID=" . $object_id;
    $icon = 'glyphicon glyphicon-globe';
    return $html->button('', $link, { ICON => $icon });
  }

  my $objects = maps2_get_build_objects({
    LOCATION_ID => $attr->{VALUES}->{ID}
  });

  my $count = @{$objects};

  if (!$count) {
    my $link = "index=$map_index&LAYER=1&OBJECT_ID=$attr->{VALUES}->{ID}&ADD_POINT=1";
    $icon = 'glyphicon glyphicon-map-marker';
    return $html->button('', $link, { ICON => $icon });
  }

  my $object_id = $objects->[0]{LAYER_ID} && $objects->[0]{LAYER_ID} == 12 ? $objects->[0]{OBJECT_ID} : $attr->{VALUES}->{ID};
  my $link = "index=$map_index&LAYER=$objects->[0]{LAYER_ID}&OBJECT_ID=$object_id";

  return $html->button('', $link, { ICON => $icon, ex_params => 'target=new' });
}
#**********************************************************
=head2 form_address_sel() - Multi address form

=cut
#**********************************************************
sub form_address_sel {

  print "Content-Type: text/html\n\n";

  my $js_list   = "<option></option>";

  my $list_to_options_string = sub {
   my ($array_ref, $value_key, $name_key) = @_;
    $value_key //= 'id';
    $name_key //= 'name';

    my $res = '';
    foreach my $line (@$array_ref){
      my $value = $line->{$name_key};
      $value =~ s/\'/&rsquo;/g;
      $res .= "<option value='$line->{$value_key}'>$value</option>";
    }

    $res;
  };

  # Show builds
  if ($FORM{STREET} || $FORM{STREET_ID}) {

    my $builds_list = $Address->build_list({
      STREET_ID => $FORM{STREET} || $FORM{STREET_ID},
      BLOCK     => '_SHOW',
      COORDX    => '_SHOW',
      PAGE_ROWS => 10000,
      COLS_NAME => 1
    });

    if ($Address->{TOTAL} > 0) {
      foreach my $line (@$builds_list) {
        $line->{number} =~ s/\'/&rsquo;/g;
        my $value = $line->{number};

        if ($line->{block}){
          $value .= "-$line->{block}";
        }

        if($FORM{SHOW_UNREG} && $line->{coordx} == 0) {
          $value .= ' (+)';
        }

        $js_list .= "<option value='$line->{id}'>$value</option>";
      }

    }
    print $js_list;
  }
  # Show streets
  elsif ($FORM{DISTRICT_ID}) {
    my $streets_list = $Address->street_list({
      DISTRICT_ID => $FORM{DISTRICT_ID},
      STREET_NAME => '_SHOW',
      TYPE        => '_SHOW',
      PAGE_ROWS   => 10000,
      SORT        => 2,
      COLS_NAME   => 1
    });

    if ($conf{STREET_TYPE}) {
      my @street_type_list = split (';', $conf{STREET_TYPE});

      $streets_list = [ map {
        { %$_,
          street_name => join (' ', ($street_type_list[($_->{type} || 0)]) ? $street_type_list[$_->{type}] : q{}, ($_->{street_name} || q{}))
        };
      } @{$streets_list} ];
    }

    print $js_list . $list_to_options_string->($streets_list, 'id', 'street_name');
  }
  # Show users
  elsif ($FORM{LOCATION_ID}) {
    my $list = $users->list({
      LOCATION_ID  => $FORM{LOCATION_ID},
      ADDRESS_FLAT => '!',
      PAGE_ROWS    => 1000,
      COLS_NAME    => 1
    });

    my $json_load_error = load_pmodule("JSON", { RETURN => 1 });
    if ($json_load_error) {
      print $json_load_error;
      return 0;
    }

    my $json = JSON->new->utf8(0);
    print $json->encode({
      map {
          $_->{address_flat} =>
            {
              uid       => $_->{uid},
              user_name => $_->{login}
            }
      } @{$list}
    });
  }
  # Show districts
  else {
    my $districts_list = $Address->district_list({
      %LIST_PARAMS,
      PAGE_ROWS => 1000,
      COLS_NAME => 1,
      SORT      => 'city',
    });

    print $js_list . $list_to_options_string->($districts_list);
  }

  exit;
}

#**********************************************************
=head2 sel_countries($attr) - Country Select;

  Arguments:
    $attr
      NAME      - Select object name (Default: COUNTRY)
      COUNTRY   - Selected value
  Returns:
    \%countries_hash, $sel_form

=cut
#**********************************************************
sub sel_countries {
  my ($attr) = @_;

  my %countries_hash = ();

  my $countries = $html->tpl_show(templates('countries'), undef, { OUTPUT2RETURN => 1 });
  my @countries_arr = split(/[\r\n]/, $countries);

  foreach my $c (@countries_arr) {
    my ($id, $name) = split(/:/, $c);
    if ($id && $id =~ /^\d+$/){
      $countries_hash{ int($id) } = $name;
    }
  }

  my $sel_form = $html->form_select($attr->{NAME} || 'COUNTRY',
    {
      SELECTED => $attr->{COUNTRY} || $FORM{COUNTRY} || 0,
      SEL_HASH => { '' => '', %countries_hash },
      NO_ID    => 1
    }
  );

  return \%countries_hash, $sel_form;
}

#**********************************************************
=head2 sel_districts($attr)

  Arguments:
    $attr
      DISTRICT_ID

  Result:
    Select form

=cut
#**********************************************************
sub sel_districts {
  my ($attr) = @_;

  $attr ||= {};

  return $html->form_select(
    "DISTRICT_ID",
    {
      SELECTED    => $attr->{DISTRICT_ID} || $FORM{DISTRICT_ID},
      SEL_LIST    => $Address->district_list( { PAGE_ROWS => 1000, COLS_NAME => 1, } ),
      SEL_OPTIONS => { '' => '--' },
      NO_ID       => 1,
      %{ $attr }
    }
  );
}

#**********************************************************
=head2 sel_streets($attr)

  Arguments:
    $attr
      STREET_ID
      SEL_OPTIONS
      MAIN_MENU

  Results:
    Select form

=cut
#**********************************************************
sub sel_streets {
  my ($attr) = @_;

  $attr ||= {};

  my $list = $Address->street_list( { PAGE_ROWS => 10000, STREET_NAME => '_SHOW', COLS_NAME => 1 } );
  if ($conf{STREET_TYPE}) {
    my @street_type_list = split (';', $conf{STREET_TYPE});
    $list = [ map {
      { %$_,
        street_name => join (' ', $street_type_list[$_->{type}], $_->{street_name})
      };
    } @{$list} ];
  }

  return $html->form_select(
    "STREET_ID",
    {
      SELECTED       => $attr->{STREET_ID} || $FORM{BUILDS},
      SEL_LIST       => $list,
      SEL_VALUE      => 'street_name',
      NO_ID          => 1,
      SEL_OPTIONS    => $attr->{SEL_OPTIONS},
      MAIN_MENU      => get_function_index( 'form_streets' ),
      MAIN_MENU_ARGV => ( $attr->{STREET_ID} || $FORM{BUILDS} ) ? "chg=" . ( $attr->{STREET_ID} || $FORM{BUILDS} ) : '',
      %{ $attr }
    }
  );
}

#**********************************************************
=head2 full_address_name($location_id)

=cut
#**********************************************************
sub full_address_name {
  my ($location_id) = @_;
  return '' if !$location_id;

  my $info = $Address->address_info($location_id);
  my $street_type = '';
  if ($conf{STREET_TYPE} && $info->{STREET_TYPE}) {
    my @street_types = split (';', $conf{STREET_TYPE});
    $street_type = @street_types[$info->{STREET_TYPE}];
  }

  my @address_components = (
    $info->{CITY},
    $info->{ADDRESS_DISTRICT},
    $street_type .' '. ($info->{ADDRESS_STREET} || q{}),
    ($info->{ADDRESS_STREET2} ? "($info->{ADDRESS_STREET2})" : ''),
    $info->{ADDRESS_BUILD},
    ($info->{ADDRESS_BLOCK} ? "-$info->{ADDRESS_BLOCK}" : '')
  );

  return join(', ', grep { $_ && $_ ne '' } @address_components);
}

#**********************************************************
=head2 short_address_name($location_id)

=cut
#**********************************************************
sub short_address_name {
  my ($location_id) = @_;
  return '' if !$location_id;

  my $info = $Address->address_info($location_id);
  my $street_type = '';
  if ($conf{STREET_TYPE}) {
    $street_type = (split (';', $conf{STREET_TYPE}))[$info->{STREET_TYPE}];
  }

  my @address_components = (
    "$street_type $info->{ADDRESS_STREET}",
    ($info->{ADDRESS_STREET2} ? "($info->{ADDRESS_STREET2})" : ''),
    $info->{ADDRESS_BUILD},
    ($info->{ADDRESS_BLOCK} ? "-$info->{ADDRESS_BLOCK}" : '')
  );

  return join(', ', grep { $_ && $_ ne '' } @address_components);
}


#**********************************************************
=head2 form_address($attr) - shows form for adding nas addrress

  Arguments:
    $attr
      LOCATION_ID         =>
      FLAT_CHECK_FREE     => 1
      FLAT_CHECK_OCCUPIED => 1
      SHOW                => 1
      SHOW_BUTTONS     => 1 - Do not show Maps, Dom, Add District and Add Street buttons
      FLOOR               => value    - Shows Extra fields entrance and floor at the address box
        and add value into floor input
      ENTRANCE            => value    - Shows Extra fields entrance and floor at the address box
        and add value into entrance input

  Results:
    return $result

  Example:

    $Nas->{ADDRESS_FORM}   = form_address({
      LOCATION_ID => $Nas->{LOCATION_ID},
      FLOOR       => $Nas->{FLOOR},
      ENTRANCE    => $Nas->{ENTRANCE}
    });

=cut
#**********************************************************
sub form_address {
  my ($attr) = @_;
  my %params = ();

  
  if(! $attr->{SHOW}) {
    $params{PARAMS}='collapsed-box';
    $params{BUTTON_ICON}='plus';
  }
  else {
    $params{BUTTON_ICON}='minus';
  }

  if ( ! $conf{ADDRESS_REGISTER} ) {
    my $countries_hash;
    ($countries_hash, $params{COUNTRY_SEL}) = sel_countries({
        NAME    => 'COUNTRY_ID',
        COUNTRY => $attr->{COUNTRY_ID} });

    return $html->tpl_show(templates('form_address'), { %{ ($attr) ? $attr : {} }, %params }, { OUTPUT2RETURN => 1 });
  }

  if ($attr->{LOCATION_ID}) {
    $Address->address_info($attr->{LOCATION_ID});
    if (in_array('Maps', \@MODULES)) {
      load_module('Maps');
      $Address->{MAP_BTN} = _maps_btn_for_build($attr->{LOCATION_ID}, {MAP_BTN => 1});
    }
    if (in_array('Dom', \@MODULES)) {
      $Address->{DOM_BTN} = $html->button("", 'index=' . get_function_index('dom_info') . "&LOCATION_ID=$attr->{LOCATION_ID}",
        { class                                                                   => 'btn btn-success btn-sm',
          ex_params                                                               =>
          "data-tooltip-position='top' data-tooltip='$lang{BUILD_SCHEMA}'", ICON => 'fa fa-building-o ' });
    }
    $Address->{FLAT_CHECK_FREE} = 1;
  }

  if($attr->{REGISTRATION_HIDE_ADDRESS_BUTTON}){
    $Address->{HIDE_ADD_BUILD_BUTTON}   = "style='display:none;'" if (!$conf{REGISTRATION_ADD_PLANNED_BUILDS});
    $Address->{HIDE_ADD_ADDRESS_BUTTON} = "style='display:none;'";
  }

  if (defined($attr->{FLOOR}) || defined($attr->{ENTRANCE})) {
    $Address->{EXT_ADDRESS} = $html->tpl_show(templates('form_ext_address'), { ENTRANCE => $attr->{ENTRANCE}, FLOOR => $attr->{FLOOR} }, { OUTPUT2RETURN => 1 });
  }
    my $result = $html->tpl_show(
      templates('form_show_hide'),
      {
        CONTENT => form_address_select2({ %$Address, %$attr }),
        NAME    => $lang{ADDRESS},
        ID      => 'ADDRESS_FORM',
        %params
      },
      { OUTPUT2RETURN => 1 }
    );

  if ($attr->{IMPORT_ADDRESS}) {
    address_import()
  }

  return $result;
}

#**********************************************************
=head2 _street_type_select

=cut
#**********************************************************
sub _street_type_select {
  my ($selected) = @_;

  my @street_types = split(';', $conf{STREET_TYPE} || '');

  my $result = $html->form_select(
    "TYPE",
    {
      SELECTED       => $selected,
      SEL_ARRAY      => \@street_types,
      ARRAY_NUM_ID   => 1,
    }
  );

  return $result;
}

sub form_address_multi_location_select {
  my ($attr) = @_;

  my $build_id = q{BUILD_ID};


  my $builds = $Address->build_list({
    NUMBER      => '_SHOW',
    LOCATION_ID => '_SHOW',
    STREET_NAME => '_SHOW',
    COLS_NAME   => 1,
    PAGE_ROWS   => 999999
  });

  my @builds_name = map {
      ($_->{street_name} && $_->{number} && $_->{id}) ?
      {
        build    => $_->{street_name}." ".$_->{number},
        build_id => $_->{id}
      } : ()
    } @$builds;

  my $builds_form = $html->form_select(
    $build_id,
    {
      MULTIPLE    => 1,
      SEL_LIST    => \@builds_name,
      SEL_KEY     => 'build_id',
      SEL_VALUE   => 'build',
      NO_ID       => 1
    }
  );

  my $form = $html->tpl_show(templates('form_address_multi_location_select'), {
      BUILDS_SELECT => $builds_form
    },
    { OUTPUT2RETURN => 1 }
  );

  return $form;
}

#**********************************************************
=head2 form_address_select2($attr)

  Arguments:
    $attr -
    SHOW_BUTTONS => 1 - Show Maps, Dom buttons
    SHOW_ADD_BUTTONS => 1 - Show Add District and Add Street buttons
  Returns:

=cut
#**********************************************************
sub form_address_select2 {
  my ($attr) = @_;
  my $district_id = q{DISTRICT_ID};
  my $street_id = q{STREET_ID};
  my $build_id = q{BUILD_ID};
  my $form = q{};

  my $MULTI_BUILDS = $attr->{MULTI_BUILDS} || $FORM{MULTI_BUILDS} || 0;

  if ($attr->{REGISTRATION_MODAL}) {
    $district_id = q{REG_DISTRICT_ID};
    $street_id = q{REG_STREET_ID};
    $build_id = q{REG_BUILD_ID};
  }

  $attr->{DISTRICT_SELECT_ID} = $FORM{DISTRICT_SELECT_ID} if ($FORM{DISTRICT_SELECT_ID});
  $attr->{STREET_SELECT_ID} = $FORM{STREET_SELECT_ID} if ($FORM{STREET_SELECT_ID});
  $attr->{BUILD_SELECT_ID} = $FORM{BUILD_SELECT_ID} if ($FORM{BUILD_SELECT_ID});

  if ($attr->{LOCATION_ID} && $attr->{LOCATION_ID} != 0) {
    my $full_address = $Address->build_list({
      LOCATION_ID => $attr->{LOCATION_ID},
      DISTRICT_ID => '_SHOW',
      STREET_ID   => '_SHOW',
      COLS_NAME   => 1 });
    $attr->{DISTRICT_ID} = $full_address->[0]->{district_id};
    $attr->{STREET_ID} = $full_address->[0]->{street_id};
    $attr->{BUILD_ID} = $full_address->[0]->{id};
  }

  #  Districts
  my $districts = $Address->district_list({
    COLS_NAME => 1,
    PAGE_ROWS => 999999,
    SORT      => 'd.name'
  });
  my $d = $html->form_select(
    $district_id,
    {
      ID          => $attr->{DISTRICT_SELECT_ID},
      SELECTED    => $attr->{DISTRICT_ID} || 0,
      SEL_LIST    => $districts,
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { 0 => '--' },
      EX_PARAMS   => ($attr->{DISTRICT_REQ} || '') . ' ' . 'onChange="GetStreets' . ($attr->{DISTRICT_SELECT_ID}  || $district_id). '(this)"',
    }
  );
  my $st_emp = '';
  my $bd_emp = '';

  #Streets
  if ($FORM{STREET}) {
    my $streets = $Address->street_list({
      DISTRICT_ID => $FORM{DISTRICT_ID},
      STREET_NAME => '_SHOW',
      SORT        => 's.name',
      COLS_NAME   => 1,
      PAGE_ROWS   => 999999
    });

    my $s = $html->form_select(
      $street_id,
      {
        ID          => $attr->{STREET_SELECT_ID},
        SELECTED    => 0,
        SEL_LIST    => $streets,
        SEL_KEY     => 'id',
        SEL_VALUE   => 'street_name',
        NO_ID       => 1,
        SEL_OPTIONS => { 0 => '--' },
        EX_PARAMS   => ($attr->{STREET_REQ} || '') . ' '.  'onChange="GetBuilds' . ($attr->{STREET_SELECT_ID}  || $street_id). '(this)"',
      }
    );
    print $s;
    return 1;
  }
  else {
      my $d_name = $attr->{DISTRICT_ID} || '';
      my $streets = $Address->street_list({
        DISTRICT_ID => $d_name,
        STREET_NAME => '_SHOW',
        SORT        => 's.name',
        COLS_NAME   => 1,
        PAGE_ROWS   => 999999
      });

    $st_emp = $html->form_select(
      $street_id,
      {
        ID          => $attr->{STREET_SELECT_ID},
        SELECTED    => $attr->{STREET_ID} || 0,
        SEL_LIST    => $streets,
        SEL_KEY     => 'id',
        SEL_VALUE   => 'street_name',
        NO_ID       => 1,
        SEL_OPTIONS => { 0 => '--' },
        EX_PARAMS => 'onChange="GetBuilds' . ($attr->{STREET_SELECT_ID} || $street_id). '(this)"',
      }
    );
  }
  #Builds
  if ($FORM{BUILD}) {
    my $builds = $Address->build_list({
      STREET_ID => $FORM{STREET_ID},
      NUMBER    => '_SHOW',
      COLS_NAME => 1,
      SORT      => 'b.number+0',
      PAGE_ROWS => 999999
    });
    my $bu = $html->form_select(
      $build_id,
      {
        ID          => $attr->{BUILD_SELECT_ID},
        MULTIPLE    => $MULTI_BUILDS,
        SELECTED    => 0,
        NO_ID       => 1,
        SEL_LIST    => $builds,
        SEL_KEY     => 'id',
        SEL_VALUE   => 'number',
        SEL_OPTIONS => { 0 => '--' },
        EX_PARAMS   => ($attr->{BUILD_REQ} || '') . ' ' . 'onChange="GetLoc' . ($attr->{BUILD_SELECT_ID} || $build_id) . '(this)" '.($MULTI_BUILDS ? 'class="MULTI_BUILDS"' : ''),
      }
    );
    print $bu;
    return 1;
  }
  else {
    my $builds;
    if ($attr->{STREET_ID}) {
      $builds = $Address->build_list({
        STREET_ID   => $attr->{STREET_ID},
        NUMBER      => '_SHOW',
        LOCATION_ID => '_SHOW',
        COLS_NAME   => 1,
        SORT        => 'b.number+0',
        PAGE_ROWS   => 999999
      });
    }

    $bd_emp = $html->form_select(
       $build_id,
       {
         ID          => $attr->{BUILD_SELECT_ID},
         MULTIPLE    => ($attr->{MULTI_BUILDS}) ? 1 : 0,
         SELECTED    => $attr->{LOCATION_ID} || 0,
         SEL_LIST    => $builds,
         SEL_KEY     => 'id',
         SEL_VALUE   => 'number',
         NO_ID       => 1,
         SEL_OPTIONS => { 0 => '--' },
         EX_PARAMS => 'onChange="GetLoc' . ($attr->{BUILD_SELECT_ID} || $build_id) . '(this)" '.($MULTI_BUILDS ? 'class="MULTI_BUILDS"' : '')
       }
     );
  }

  my $district_button = $html->button("", 'get_index=form_districts&full=1&header=1', {
    class => 'btn btn-success btn-sm',
    ICON => "fa fa-street-view",
    ex_params => "data-tooltip-position='top' data-tooltip='$lang{ADD} $lang{DISTRICT}'",
  });
  my $street_button = $html->button("", 'get_index=form_streets&full=1&header=1', {
    class => 'btn btn-success btn-sm',
    ICON => "fa fa-road",
    ex_params => "data-tooltip-position='top' data-tooltip='$lang{ADD} $lang{STREET}'",
  });
  my $maps2_btn = '';
  $maps2_btn = $html->button('', 'get_index=maps2_main&QUICK=1&SMALL=1&header=2&MODAL=1&CREATE_MARKER=1', {
    LOAD_TO_MODAL => 1,
    class         => 'btn btn-sm btn-success',
    title         => $lang{SHOW},
    ICON          => 'glyphicon glyphicon-globe',
  }) if in_array('Maps2', \@MODULES);


  if ($attr->{REGISTRATION_MODAL}) {
    $form = $html->tpl_show(templates('registration_modal_address'), {
      ADD_BUILD_HIDE   => $attr->{HIDE_ADD_BUILD_BUTTON} ? "style='display:none;'" : '',
      ADDRESS_DISTRICT => $d,
      ADDRESS_STREET   => $st_emp,
      ADDRESS_BUILD    => $bd_emp,
      LOCATION_ID      => $attr->{LOCATION_ID} || '',
      EXT_SEL_STYLE    => $attr->{EXT_SEL_STYLE} ? $attr->{EXT_SEL_STYLE} : q{},
    },
      { OUTPUT2RETURN => 1 });
  }
  else {
    $form = $html->tpl_show(templates('form_address_search2'), {
      ADD_BUILD_HIDE      => $attr->{HIDE_ADD_BUILD_BUTTON} ? "style='display:none;'" : '',
      ADDRESS_DISTRICT    => $d,
      DISTRICT_ID         => $attr->{DISTRICT_SELECT_ID} || 'DISTRICT_ID',
      STREET_ID           => $attr->{STREET_SELECT_ID} || 'STREET_ID',
      BUILD_ID            => $attr->{BUILD_SELECT_ID} || 'BUILD_ID',
      QINDEX              => $FORM{REG_QINDEX} || '',
      ADDRESS_STREET      => $st_emp,
      ADDRESS_BUILD       => $bd_emp,
      ADDRESS_FLAT        => $attr->{ADDRESS_FLAT} || '',
      LOCATION_ID         => $attr->{LOCATION_ID} || '',
      HIDE_FLAT           => $attr->{HIDE_FLAT} ? 'display: none' : '',
      EXT_ADDRESS         => $attr->{EXT_ADDRESS} ? $attr->{EXT_ADDRESS} : q{},
      MAP_BTN             => $attr->{MAP_BTN} && $attr->{SHOW_BUTTONS} ? $attr->{MAP_BTN} : q{},
      DOM_BTN             => $attr->{DOM_BTN} && $attr->{SHOW_BUTTONS} ? $attr->{DOM_BTN} : q{},
      EXT_SEL_STYLE       => $attr->{EXT_SEL_STYLE} ? $attr->{EXT_SEL_STYLE} : q{},
      ADDRESS_ADD_BUTTONS => $attr->{SHOW_ADD_BUTTONS} ? "$district_button $street_button" : q{},
      MAPS2_BTN           => $maps2_btn && $attr->{SHOW_BUTTONS} ? $maps2_btn : q{},
      MAPS2_SHOW_OBJECTS  => $maps2_btn && $attr->{SHOW_BUTTONS} ? 1 : 0,
      BUILD_SELECTED      => $attr->{LOCATION_ID} || 0
    },
      { OUTPUT2RETURN => 1, ID => 'form_address_sel2' });
  }
  return $form;
}

#**********************************************************
=head2 address_import()

    This function is intended for
    importing addresses into the address log from
    .json/.csv extension files

    Arguments:
      -

    Return:
      -

=cut
#**********************************************************
sub address_import {

  if ($FORM{add}) {
    my $import_info = import_former( \%FORM );
    my $total = $#{ $import_info } + 1;

    my $address_list = $Address->street_list({
      STREET_NAME   => '_SHOW',
      COLS_NAME     => 1,
      PAGE_ROWS     => 1000
    });

    my $address_district = $Address->district_list({ COLS_NAME => 1 });

    my %districts_hash = map { $_->{name} => $_->{id} } @{$address_district};
    my %streets_hash = map { $_->{street_name} => $_->{id} } @{$address_list};

    if ($import_info->[0]->{BUILD}) {
      import_address_json($import_info, %districts_hash, %streets_hash);
    }
    else {
      import_address_csv($import_info, %districts_hash, %streets_hash);
    }

    $html->message( 'info', $lang{INFO},
      "$lang{ADDED}\n $lang{FILE}: $FORM{UPLOAD_FILE}{filename}\n Size: $FORM{UPLOAD_FILE}{Size}\n Count: $total" );

    return 1;
  }

  $html->tpl_show(templates('form_import'), {
    IMPORT_ADDRESS => $FORM{IMPORT_ADDRESS},
    CALLBACK_FUNC  => 'form_districts',
  });

  return 1;
}

#**********************************************************
=head2 import_address_csv()

  Arguments:
    import_info     - Data for importing addresses
    districts_hash  - District, key-name, value-id district
    street_hash     - Street, key-name, value-id street

  Return:
    -

=cut
#**********************************************************
sub import_address_csv {
  my ($import_info, %districts_hash, %street_hash) = @_;

  my @address = ();

  foreach my $import (@$import_info) {
    if ($import->{0} =~ /,/) {
      push @address, split(/,/, $import->{0}, 1);
    }
  }

  my @address_date = ();
  for (my $i = 1; $i <= $#address; ++$i) {
    my %address_import = ();
    my ($district, $street, $build) = split(/,/, $address[ $i ]);

    $address_import{DISTRICT} = $district;
    $address_import{STREET} = $street;
    $address_import{BUILD} = $build;

    push @address_date, \%address_import;
  }

  foreach my $address_tmp (@address_date) {
    add_address_import($address_tmp, %districts_hash, %street_hash);
  }
}

#**********************************************************
=head2 import_address_json()

  Arguments:
    import_info     - Data for importing addresses
    districts_hash  - District, key-name, value-id district
    street_hash     - Street, key-name, value-id street

  Return:
    -

=cut
#**********************************************************
sub import_address_json {
  my ($import_info, %districts_hash, %streets_hash) = @_;
  foreach my $address_import (@$import_info) {
    add_address_import($address_import, %districts_hash, %streets_hash);
  }
}

#**********************************************************
=head2 add_address_import()

  Arguments:
    address_tmp     - Address date add
    districts_hash  - District, key-name, value-id district
    street_hash     - Street, key-name, value-id street

  Return:
    -

=cut
#**********************************************************
sub add_address_import {
  my ($address_tmp, %districts_hash, %street_hash) = @_;

  if (!$districts_hash{ $address_tmp->{DISTRICT} }) {
    my $districts_id = add_import_districts($address_tmp->{DISTRICT});
    add_import_street($address_tmp, $districts_id);
    add_import_build($street_hash{ $address_tmp->{STREET} }, $address_tmp->{BUILD});
  }
  elsif (!$street_hash{ $address_tmp->{STREET} }) {
    add_import_street($address_tmp, $districts_hash{ $address_tmp->{DISTRICT} });
    add_import_build($street_hash{ $address_tmp->{STREET} }, $address_tmp->{BUILD});
  }
  else {
    add_import_build($street_hash{ $address_tmp->{STREET} }, $address_tmp->{BUILD});
  }
}

#**********************************************************
=head2 add_import_street()

  Arguments:
    street_name     -
    district_id     -

  Return:
    -

=cut
#**********************************************************
sub add_import_street {
  my ($street_name, $district_id) = @_;
  $Address->street_add({
    NAME        => Encode::decode('UTF-8', $street_name->{STREET}),
    DISTRICT_ID => $district_id
  });
}

#**********************************************************
=head2 add_import_street()

  Arguments:
    street_id       -
    district_id     -

  Return:
    -

=cut
#**********************************************************
sub add_import_build {
  my ($street_id, $number) = @_;
  
  $Address->build_add({
    STREET_ID         => $street_id,
    ADD_ADDRESS_BUILD => $number
  });
}

#**********************************************************
=head2 add_import_street()

  Arguments:
    name_district  -

  Return:
    INSERT_ID      - id district

=cut
#**********************************************************
sub add_import_districts {
  my ($name_district) = @_;
  
  $Address->district_add({ NAME => Encode::decode('UTF-8', $name_district) });

  return $Address->{INSERT_ID};
}

1;
