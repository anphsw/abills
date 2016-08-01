=head1 NAME

  Address Manage functions

=cut


use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array);
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
        $v =~ s/^\"|\"$//g;
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
          $Address->street_add( { NAME => $info{STREET_NAME},
              DISTRICT_ID              => $FORM{ID} } );

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

  if ( $FORM{add} ){
    $Address->district_add( { %FORM } );

    if ( !$Address->{errno} ){
      if ( $FORM{FILE_UPLOAD} ){
        my $name = '';
        if ( $FORM{FILE_UPLOAD}{filename} =~ /\.(\S+)$/i ){
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
        if ( $FORM{FILE_UPLOAD}{filename} =~ /\.([a-z0-9]+)$/i ){
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

  my $list = $Address->district_list( { %LIST_PARAMS, COLS_NAME => 1 } );
  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{DISTRICTS},
      title      =>
      [ "#", "$lang{NAME}", "$lang{COUNTRY}", "$lang{CITY}", "$lang{ZIP}", "$lang{STREETS}", "$lang{MAP}", '-', '-' ],
      cols_align => [ 'right', 'left', 'left', 'left', 'left', 'right', 'right', 'center', 'center' ],
      ID         => 'DISTRICTS_LIST',
      FIELDS_IDS => $Address->{COL_NAMES_ARR},
      EXPORT     => 1,
      MENU       => "$lang{ADD}:index=$index&add_form=1:add",
    }
  );

  foreach my $line ( @{$list} ){
    my $map = '';

    if ( -f $conf{TPL_DIR} . '/maps/' . $line->{id} . '.gif' || -f $conf{TPL_DIR} . '/maps/' . $line->{id} . '.jpg' || -f $conf{TPL_DIR} . '/maps/' . $line->{id} . '.png' ){
      if ( in_array( 'Maps', \@MODULES ) ){
        $map = $html->button( $bool_vals[1], "DISTRICT_ID=$line->{id}&index=" . get_function_index( 'maps_main' ),
          { BUTTON => 1 } );
      }
      else{
        $map = $html->button( $bool_vals[1], '#',
          { NEW_WINDOW => "index.cgi?MODULE=Maps&qindex=-1", NEW_WINDOW_SIZE => "670:340", BUTTON => 1 } );
      }
    }
    else{
      $map = $bool_vals[0];
    }

    $table->addrow(
      $line->{id},
      $line->{name},
      $countries_hash->{ $line->{country} },
      $line->{city},
      $line->{zip},
      $html->button( $line->{street_count},
        "index=" . get_function_index( 'form_streets' ) . "&DISTRICT_ID=$line->{id}" ),
      $map,
      $html->button( $lang{CHANGE}, "index=$index&chg=$line->{id}", { class => 'change' } ),
      $html->button( $lang{DEL}, "index=$index&del=$line->{id}",
        { MESSAGE => "$lang{DEL} [$line->{id}] $line->{name}?", class => 'del' } )
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

  $Address->{DISTRICTS_SEL} = $html->form_select(
    "DISTRICT_ID",
    {
      SELECTED    => $Address->{DISTRICT_ID} || $FORM{DISTRICT_ID},
      SEL_LIST    => $Address->district_list( { PAGE_ROWS => 1000, COLS_NAME => 1, } ),
      SEL_OPTIONS => { '' => '--' },
      NO_ID       => 1
    }
  );

  if ( $FORM{add_form} ){
    $html->tpl_show( templates( 'form_street' ), $Address );
  }

  if ( $FORM{DISTRICT_ID} ){
    $LIST_PARAMS{DISTRICT_ID} = $FORM{DISTRICT_ID};
    $pages_qs .= "&DISTRICT_ID=$LIST_PARAMS{DISTRICT_ID}";
    $Address->district_info({ ID => $FORM{DISTRICT_ID} }) if(! $FORM{chg});
  }

  #$html->tpl_show(templates('form_street_search'), $Address);

  if ( !$FORM{sort} ){
    $LIST_PARAMS{SORT} = 2;
  }

  my ($table) = result_former( {
    INPUT_DATA      => $Address,
    FUNCTION        => 'street_list',
    #BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'ID,STREET_NAME,BUILD_COUNT,USERS_COUNT',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    FILTER_COLS     => {
      build_count => 'form_show_link:ID:ID,add=1',
      users_count => 'search_link:form_search:STREET_ID,type=11',
    },
    EXT_TITLES      => {
      street_name    => $lang{NAME},
      disctrict_name => $lang{DISTRICT},
      second_name    => $lang{SECOND_NAME},
      build_count    => $lang{BUILDS},
      users_count    => $lang{USERS}
    },
    TABLE           => {
      caption => $lang{STREETS}.': '. ($Address->{NAME} || q{}),
      qs      => $pages_qs,
      ID      => 'STREETS_LIST',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1&DISTRICT_ID=" . ($FORM{DISTRICT_ID} || '') . ":add",
      SHOW_COLS_HIDDEN => {
        DISTRICT_ID => $FORM{DISTRICT_ID}
      }
    },
    MAKE_ROWS       => 1,
  } );

  print $table->show();
  $table = $html->table(
    {
      cols_align => [ 'right', 'right' ],
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

  if ( !$FORM{qindex} && !$FORM{xml} ){
    my @header_arr = (
      "$lang{INFO}:index=$index&BUILDS=$FORM{BUILDS}" . (($FORM{chg}) ? '&chg=$FORM{chg}' : ''),
      "Media:index=$index&media=1&BUILDS=$FORM{BUILDS}" . (($FORM{chg}) ? '&chg=$FORM{chg}' : '')
    );

    print $html->table_header( \@header_arr, { TABS => 1 } );
  }

  if ( $FORM{media} ){
    form_location_media();
    return 1;
  }

  my $yandex_index = get_function_index( 'yandex_map_add' );
  my $google_index = get_function_index( 'google_map_add' );

  if ( $FORM{add} ){
    $Address->build_add( { %FORM } );

    if ( !$Address->{errno} ){
      if ( $yandex_index ){
        $Address->{YANDEX_BTN} = $html->button( "$lang{MAP} Yandex", "index=$yandex_index&ID=$Address->{INSERT_ID}",
          { BUTTON => 1 } );
      }
      if ( $google_index ){
        $Address->{GOOGLE_BTN} = $html->button( "$lang{MAP} Google", "index=$google_index&ID=$Address->{INSERT_ID}",
          { BUTTON => 1 } );
      }

      $html->message( 'info', $lang{ADDRESS_BUILD},
        "$lang{ADDED}\n " . ($Address->{GOOGLE_BTN} || '') . ($Address->{YANDEX_BTN} || '') );
    }
  }
  elsif ( $FORM{change} ){
    $Address->build_change( \%FORM );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{CHANGED}" );
    }
  }
  elsif ( $FORM{chg} ){
    $Address->build_info( { ID => $FORM{chg} } );

    if ( !$Address->{errno} ){
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
    if ( $yandex_index && $Address->{ID} ){
      $Address->{YANDEX_BTN} = $html->button( "$lang{MAP} Yandex", "index=$yandex_index&ID=$Address->{ID}",
        { BUTTON => 1 } );
    }

    if ( $google_index && $Address->{ID} ){
      $Address->{GOOGLE_BTN} = $html->button( "$lang{MAP} Google", "index=$google_index&ID=$Address->{INSERT_ID}",
        { BUTTON => 1 } );
    }

    $Address->{STREET_SEL} = $html->form_select(
      "STREET_ID",
      {
        SELECTED       => $Address->{STREET_ID} || $FORM{BUILDS},
        SEL_LIST       => $Address->street_list( { PAGE_ROWS => 10000, STREET_NAME => '_SHOW', COLS_NAME => 1 } ),
        SEL_VALUE      => 'street_name',
        NO_ID          => 1,
        MAIN_MENU      => get_function_index( 'form_streets' ),
        MAIN_MENU_AGRV => "chg=" . ( $Address->{STREET_ID} || $FORM{BUILDS} )
      }
    );

    $html->tpl_show( templates( 'form_build' ), $Address );
  }

  $pages_qs .= "&BUILDS=$FORM{BUILDS}" if ($FORM{BUILDS});
  $LIST_PARAMS{DISTRICT_ID} = $FORM{DISTRICT_ID} if ($FORM{DISTRICT_ID});
  $LIST_PARAMS{STREET_ID} = $FORM{BUILDS};
  result_former( {
      INPUT_DATA        => $Address,
        FUNCTION        => 'build_list',
        MAP             => 1,
        BASE_FIELDS     => 1,
        DEFAULT_FIELDS  =>
        'NUMBER,FLORS,ENTRANCES,FLATS,STREET_NAME,USERS_COUNT,USERS_CONNECTIONS,ADDED' . (in_array( 'Maps',
            \@MODULES ) ? ',COORDX' : ''),
        FUNCTION_FIELDS => 'change,del',
        EXT_TITLES      => {
        number            => "$lang{NUM}",
        flors             => "$lang{FLORS}",
        entrances         => "$lang{ENTRANCES}",
        flats             => "$lang{FLATS}",
        street_name       => "$lang{STREETS}",
        users_count       => "$lang{USERS}",
        users_connections => "$lang{DENSITY_OF_CONNECTIONS}",
        added             => "$lang{ADDED}",
        location_id       => 'LOCATION ID',
        coordx            => $lang{MAP} . ' X',
        coordy            => $lang{MAP} . ' Y'
      },
        SKIP_USER_TITLE => 1,
        FILTER_COLS     => {
        users_count => 'search_link:form_search:LOCATION_ID,type=11',
        coordx      => 'form_add_map:ID:ID,COORDX,add=1',
      },
        TABLE           => {
        width            => '100%',
        caption          => $lang{BUILDS},
        qs               => $pages_qs,
        #header     => $status_bar,
        ID               => 'BUILDS_LIST',
        EXPORT           => 1,
        SHOW_COLS_HIDDEN => { 'BUILDS' => $FORM{BUILDS} },
        MENU             => "$lang{ADD}:index=$index&add_form=1&BUILDS=$FORM{BUILDS}:add",
      },
        MAKE_ROWS       => 1,
        TOTAL           => 1
    } );

  return 1;
}

#**********************************************************
=head2 form_show_link()

=cut
#**********************************************************
sub form_show_link{
  my ($params, $attr) = @_;

  return $html->button( $params, "index=$index&BUILDS=$attr->{VALUES}->{ID}" );

  return $params;
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
sub form_add_map{
  my ($coordx, $attr) = @_;

  if ( $attr->{VALUES}->{POINTS} ){
    return $html->button( '',
      "get_index=maps_show_poins&show_routes=$attr->{VALUES}->{ID}&ID=$attr->{VALUES}->{ID}&header=1",
      { class => 'glyphicon glyphicon-globe', target => '_maps' } );
  }
  elsif ( $coordx == 0 ){
    if ( defined( $attr->{VALUES}->{POINTS} ) && $attr->{VALUES}->{POINTS} == 0 ){
      return $html->button( 'add',
        'index=' . get_function_index( 'maps_add_2' ) . "&ROUTE_ID=$attr->{VALUES}->{ID}&LOCATION_TYPE=ROUTE",
        { class => 'add', target => '_maps' } );
    }
    else{
      return $html->button( 'add',
        'index=' . get_function_index( 'maps_add_2' ) . "&LOCATION_ID=$attr->{VALUES}->{ID}&LOCATION_TYPE=BUILD",
        { class => 'add', target => '_maps' } );
    }
  }
  else{
    # google_maps_show
    return $html->button( '', "get_index=maps_show_poins&show_build=$attr->{VALUES}->{ID}&header=1",
      { class => 'glyphicon glyphicon-globe', target => '_maps' } );
  }

  return $coordx;
}

#**********************************************************
=head2 form_address_sel() - Multi address form

=cut
#**********************************************************
sub form_address_sel {

  print "Content-Type: text/html\n\n";

  #require Address;
  #Address->import();
  #my $Address = Address->new($db, $admin, \%conf);

  my $js_list   = '';

  if ($FORM{STREET}) {
    my $list = $Address->build_list({ STREET_ID => $FORM{STREET}, COORDX => '_SHOW', PAGE_ROWS => 10000, COLS_NAME => 1 });
    if ($Address->{TOTAL} > 0) {
      foreach my $line (@$list) {
        $line->{number} =~ s/\'/&rsquo;/g;
        my $value = $line->{number};
        if($FORM{SHOW_UNREG} && $line->{coordx} == 0) {
          $value .= ' (+)';
        }
        $js_list .= "<option value='$line->{id}'>$value</option>";
      }
    }
    my $size = ($Address->{TOTAL} > 10) ? 10 : $Address->{TOTAL};
    $size = 2 if ($size < 2);
    print "<option value=''></option>" . $js_list;
  }
  elsif ($FORM{DISTRICT_ID}) {
    my $list = $Address->street_list({
        DISTRICT_ID => $FORM{DISTRICT_ID},
        STREET_NAME => '_SHOW',
        PAGE_ROWS   => 10000,
        SORT        => 2,
        COLS_NAME   => 1 });
    if ($Address->{TOTAL} > 0) {
      foreach my $line (@$list) {
        $line->{street_name} =~ s/\'/\&rsquo;/g;
        $js_list .= "<option value='$line->{id}'>$line->{street_name}</option>";
      }
    }
    my $size = ($Address->{TOTAL} > 10) ? 10 : $Address->{TOTAL};
    $size = 2 if ($size < 2);
    print "<option value=''></option>" . $js_list;
  }
  elsif ($FORM{LOCATION_ID}) {
    my $list = $users->list({
      LOCATION_ID  => $FORM{LOCATION_ID},
      ADDRESS_FLAT => '!',
      PAGE_ROWS    => 1000,
      COLS_NAME    => 1
    });

    my $js_hash = '{';
    if ($list && scalar @$list > 0) {
      $js_hash .= join(', ', map {
          qq{"$_->{address_flat}" : { "uid" : "$_->{uid}", "user_name" : "$_->{login}" } }
        } @$list );
    }
    $js_hash .= '}';

    print $js_hash;
  }
  else {
    my $list = $Address->district_list({ %LIST_PARAMS, PAGE_ROWS => 1000, COLS_NAME => 1 });
    foreach my $line (@$list) {
      $js_list .= "<option  value='$line->{id}'>$line->{name}</option>";
    }

    my $size = ($Address->{TOTAL} > 10) ? 10 : $Address->{TOTAL};
    $size = 2 if ($size && $size < 2);
    print "<option value=''></option>" . $js_list;
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

1;
