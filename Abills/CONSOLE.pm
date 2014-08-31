package Abills::CONSOLE;

#XML Functions

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
@_COLORS
%FORM
%LIST_PARAMS
%COOKIES
%functions
$index
$pages_qs
$domain
$web_path
$secure
$SORT
$DESC
$PG
$PAGE_ROWS
$SELF_URL
$SESSION_IP
@MONTHES
$COLS_SEPARATOR
);

use Exporter;
$VERSION = 2.01;
@ISA     = ('Exporter');

@EXPORT = qw(
&message
@_COLORS
%err_strs
%FORM
%LIST_PARAMS
%COOKIES
%functions
$index
$pages_qs
$domain
$web_path
$secure
$SORT
$DESC
$PG
$PAGE_ROWS
$SELF_URL
$SESSION_IP
$COLS_SEPARATOR
);

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

my $bg;
my $debug;
my %log_levels;
my $IMG_PATH;
my $row_number = 0;
my $CONF;

#**********************************************************
# Create Object
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  $IMG_PATH = (defined($attr->{IMG_PATH})) ? $attr->{IMG_PATH} : '../img/';
  $CONF = $attr->{CONF} if (defined($attr->{CONF}));

  my $self = {};
  bless($self, $class);

  if ($attr->{NO_PRINT}) {
    $self->{NO_PRINT} = 1;
  }

  %FORM      = form_parse();
  %COOKIES   = getCookies();
  $SORT      = $FORM{SORT} || 1;
  $DESC      = ($FORM{desc}) ? 'DESC' : '';
  $PG        = $FORM{pg} || 0;
  $PAGE_ROWS = $FORM{PAGE_ROWS} || 25;
  $self->{CHARSET} = (defined($attr->{CHARSET})) ? $attr->{CHARSET} : 'windows-1251';
  $domain          = $ENV{SERVER_NAME};
  $web_path        = '';
  $secure          = '';
  my $prot         = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  $SELF_URL        = (defined($ENV{HTTP_HOST})) ? "$prot://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}" : '';
  $SESSION_IP      = $ENV{REMOTE_ADDR} || '0.0.0.0';
  $COLS_SEPARATOR  = $attr->{COLS_SEPARATOR} || ';';
  @_COLORS = (
    '#FDE302',    # 0 TH
    '#FFFFFF',    # 1 TD.1
    '#eeeeee',    # 2 TD.2
    '#dddddd',    # 3 TH.sum, TD.sum
    '#E1E1E1',    # 4 border
    '#FFFFFF',    # 5
    '#FFFFFF',    # 6
    '#000088',    # 7 vlink
    '#0000A0',    # 8 Link
    '#000000',    # 9 Text
    '#FFFFFF',    #10 background
  );              #border

  %LIST_PARAMS = (
    SORT      => $SORT,
    DESC      => $DESC,
    PG        => $PG,
    PAGE_ROWS => $PAGE_ROWS
  );

  %functions = ();

  $pages_qs = '';
  $index = $FORM{index} || 0;

  if ($attr->{language}) {
    $self->{language} = $attr->{language};
  }
  elsif ($COOKIES{language}) {
    $self->{language} = $COOKIES{language};
  }
  else {
    $self->{language} = $CONF->{default_language} || 'english';
  }

  return $self;
}

#*******************************************************************
# Parse inputs from query
# form_parse()
#*******************************************************************
sub form_parse {
  my $self   = shift;
  my $buffer = '';
  my $value  = '';
  my %FORM   = ();

  return %FORM if (!defined($ENV{'REQUEST_METHOD'}));

  if ($ENV{'REQUEST_METHOD'} eq "GET") {
    $buffer = $ENV{'QUERY_STRING'};
  }
  elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
    read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
  }

  my @pairs = split(/&/, $buffer);
  $FORM{__BUFFER} = $buffer;

  foreach my $pair (@pairs) {
    my ($side, $value) = split(/=/, $pair);
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $value =~ s/<!--(.|\n)*-->//g;
    $value =~ s/<([^>]|\n)*>//g;
    if (defined($FORM{$side})) {
      $FORM{$side} .= ", $value";
    }
    else {
      $FORM{$side} = $value;
    }
  }

  return %FORM;
}

#*******************************************************************
# form_input
#*******************************************************************
sub form_input {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  my $type  = (defined($attr->{TYPE}))  ? $attr->{TYPE}             : 'text';
  my $state = (defined($attr->{STATE})) ? ' checked="1"'            : '';
  my $size  = (defined($attr->{SIZE}))  ? " SIZE=\"$attr->{SIZE}\"" : '';
  return $value;
  
  $self->{FORM_INPUT} = "<input type=\"$type\" name=\"$name\" value=\"$value\"$state$size/>";

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
# HTML Input form
#**********************************************************
sub form_main {
  my $self   = shift;
  my ($attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
    return '';
  }

  $self->{FORM} = "";

  if ($FORM{csv}) {
    return $attr->{CONTENT};
  }

  if (defined($attr->{HIDDEN})) {
    my $H = $attr->{HIDDEN};
    while (my ($k, $v) = each(%$H)) {
      $self->{FORM} .= "<input name=\"$k\" value=\"$v\"/>\n";
    }
  }

  if ($attr->{CONTENT}) {
    $self->{FORM} .= $attr->{CONTENT};
  }

  if (defined($attr->{SUBMIT})) {
    my $H = $attr->{SUBMIT};
    while (my ($k, $v) = each(%$H)) {
      $self->{FORM} .= "<input type=\"submit\" name=\"$k\" value=\"$v\"/>\n";
    }
  }

  $self->{FORM} .= "";

  if (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $self->{FORM};
    $self->{FORM} = '';
  }

  return $self->{FORM};
}

#**********************************************************
#
#**********************************************************
sub form_select {
  my $self = shift;
  my ($name, $attr) = @_;

  my $ex_params = (defined($attr->{EX_PARAMS})) ? $attr->{EX_PARAMS} : '';

  $self->{SELECT} = "<select name=\"$name\" $ex_params>\n";

  if (defined($attr->{SEL_OPTIONS})) {
    my $H = $attr->{SEL_OPTIONS};
    while (my ($k, $v) = each %$H) {
      $self->{SELECT} .= "<option value='$k'";
      $self->{SELECT} .= ' selected="1"' if (defined($attr->{SELECTED}) && $k eq $attr->{SELECTED});
      $self->{SELECT} .= ">$v</option>\n";
    }
  }

  if (defined($attr->{SEL_ARRAY})) {
    my $H = $attr->{SEL_ARRAY};
    my $i = 0;
    foreach my $v (@$H) {
      my $id = (defined($attr->{ARRAY_NUM_ID})) ? $i : $v;
      $self->{SELECT} .= "<option value='$id'";
      $self->{SELECT} .= ' selected="1"' if (defined($attr->{SELECTED}) && (($i eq $attr->{SELECTED}) || ($v eq $attr->{SELECTED})));
      $self->{SELECT} .= ">$v</option>\n";
      $i++;
    }
  }
  elsif (defined($attr->{SEL_MULTI_ARRAY})) {
    my $key   = $attr->{MULTI_ARRAY_KEY};
    my $value = $attr->{MULTI_ARRAY_VALUE};
    my $H     = $attr->{SEL_MULTI_ARRAY};

    foreach my $v (@$H) {
      $self->{SELECT} .= "<option value='$v->[$key]'";
      $self->{SELECT} .= ' selected="1"' if (defined($attr->{SELECTED}) && $v->[$key] eq $attr->{SELECTED});
      $self->{SELECT} .= '>';
      $self->{SELECT} .= "$v->[$key]:" if (!$attr->{NO_ID});
      $self->{SELECT} .= "$v->[$value]</option>\n";
    }
  }
  elsif (defined($attr->{SEL_HASH})) {
    my @H = ();

    if ($attr->{SORT_KEY}) {
      @H = sort keys %{ $attr->{SEL_HASH} };
    }
    else {
      @H = keys %{ $attr->{SEL_HASH} };
    }

    foreach my $k (@H) {
      $self->{SELECT} .= "<option value='$k'";
      $self->{SELECT} .= " selected='1'" if (defined($attr->{SELECTED}) && $k eq $attr->{SELECTED});

      if ($attr->{EXT_PARAMS}) {
        while (my ($ext_k, $ext_v) = each %{ $attr->{EXT_PARAMS} }) {
          $self->{SELECT} .= " $ext_k='";
          $self->{SELECT} .= $attr->{EXT_PARAMS}->{$ext_k}->{$k} if ($attr->{EXT_PARAMS}->{$ext_k}->{$k});
          $self->{SELECT} .= "'";
        }
      }

      $self->{SELECT} .= '>';
      $self->{SELECT} .= "$k:" if (!$attr->{NO_ID});
      $self->{SELECT} .= "$attr->{SEL_HASH}{$k}</option>\n";
    }
  }

  $self->{SELECT} .= "</select>\n";

  return $self->{SELECT};
}

#*******************************************************************
#Set cookies
# setCookie($name, $value, $expiration, $path, $domain, $secure);
#*******************************************************************
sub setCookie {
  # end a set-cookie header with the word secure and the cookie will only
  # be sent through secure connections
  my $self = shift;
  my ($name, $value, $expiration, $path, $domain, $secure) = @_;

  print "Set-Cookie: ";
  print $name, "=$value; expires=\"", $expiration, "\"; path=$path; domain=", $domain, "; ", $secure, "\n";
}

#********************************************************************
# get cookie values and return hash of it
#
# getCookies()
#********************************************************************
sub getCookies {
  my $self = shift;

  # cookies are seperated by a semicolon and a space, this will split
  # them and return a hash of cookies
  my (%cookies);

  if (defined($ENV{'HTTP_COOKIE'})) {
    my (@rawCookies) = split(/; /, $ENV{'HTTP_COOKIE'});
    foreach (@rawCookies) {
      my ($key, $val) = split(/=/, $_);
      $cookies{$key} = $val;
    }
  }

  return %cookies;
}

#**********************************************************
# Functions list
#**********************************************************
sub menu2 {
  my $self = shift;
  my ($menu_items, $menu_args, $permissions, $attr) = @_;
  $self->menu($menu_items, $menu_args, $permissions, $attr);
}

sub menu {
  my $self = shift;
  my ($menu_items, $menu_args, $permissions, $attr) = @_;

  return 0 if ($FORM{index} > 0);

  my $menu_navigator = '';
  my $menu_text      = '';
  $menu_text = "<SID>$self->{SID}</SID>\n" if ($self->{SID});

  return $menu_navigator, $menu_text if ($FORM{NO_MENU});

  my $EX_ARGS = (defined($attr->{EX_ARGS})) ? $attr->{EX_ARGS} : '';
  my $fl = $attr->{FUNCTION_LIST};

  my %new_hash = ();
  while ((my ($findex, $hash) = each(%$menu_items))) {
    while (my ($parent, $val) = each %$hash) {
      $new_hash{$parent}{$findex} = $val;
    }
  }

  my $h          = $new_hash{0};
  my @last_array = ();

  my @menu_sorted = sort { $b cmp $a } keys %$h;

  for (my $parent = 0 ; $parent < $#menu_sorted + 1 ; $parent++) {
    my $val = $h->{ $menu_sorted[$parent] };

    my $level  = 0;
    my $prefix = '';
    my $ID     = $menu_sorted[$parent];

    next if ((!defined($attr->{ALL_PERMISSIONS})) && (!$permissions->{ $parent - 1 }) && $parent == 0);
    $menu_text .= "<MENU NAME=\"$fl->{$ID}\" ID=\"$ID\" EX_ARGS=\"" . $self->link_former($EX_ARGS) . "\" DESCRIBE=\"$val\" TYPE=\"MAIN\"/>\n ";
    if (defined($new_hash{$ID})) {
      $level++;
      $prefix .= "   ";
      label:
      my $mi = $new_hash{$ID};

      while (my ($k, $val) = each %$mi) {
        $menu_text .= "$prefix<MENU NAME=\"$fl->{$k}\" ID=\"$k\" EX_ARGS=\"" . $self->link_former("$EX_ARGS") . "\" DESCRIBE=\"$val\" TYPE=\"SUB\" PARENT=\"$ID\"/>\n ";

        if (defined($new_hash{$k})) {
          $mi = $new_hash{$k};
          $level++;
          $prefix .= "    ";
          push @last_array, $ID;
          $ID = $k;
        }
        delete($new_hash{$ID}{$k});
      }

      if ($#last_array > -1) {
        $ID = pop @last_array;
        $level--;

        $prefix = substr($prefix, 0, $level * 1 * 3);
        goto label;
      }
      delete($new_hash{0}{$parent});
    }
  }

  return ($menu_navigator, $menu_text);
}

#*******************************************************************
# heder off main page
# make_charts()
#*******************************************************************
sub make_charts () {

}

#*******************************************************************
# heder off main page
# header()
#*******************************************************************
sub header {
  my $self       = shift;
  my ($attr)     = @_;

  if ($FORM{DEBUG}) {
    print "Content-Type: text/plain\n\n";
  }

  if ($FORM{csv}) {
  	my $filename     =  ($self->{ID}) ? $self->{ID}.'.csv' : ($FORM{EXPORT_CONTENT}) ?  $FORM{EXPORT_CONTENT}.'.csv' : int(rand(10000000)).'.csv';
    $self->{header}  = "Content-Type: text/csv; filename=$filename\n";    
    $self->{header} .= "Cache-Control: no-cache\n";
    $self->{header} .= "Content-disposition: attachment;filename=\"$filename\"\n\n";
  }
  else {
    $self->{header} = "Content-Type: text/plain\n\n";
  }

  return $self->{header};
}

#********************************************************************
#
# css()
#********************************************************************
sub css {
  my $css = "";
  return $css;
}

#**********************************************************
# table
#**********************************************************
sub table {
  my $proto  = shift;
  my $class  = ref($proto) || $proto;
  my $parent = ref($proto) && $proto;
  my $self;
  $self = {};

  bless($self);

  $self->{prototype} = $proto;
  $self->{NO_PRINT}  = $proto->{NO_PRINT};

  my ($attr) = @_;
  $self->{rows} = '';

  if (defined($attr->{rowcolor})) {
    $self->{rowcolor} = $attr->{rowcolor};
  }

  if (defined($attr->{rows})) {
    my $rows = $attr->{rows};
    foreach my $line (@$rows) {
      $self->addrow(@$line);
    }
  }  
  
  $self->{ID} = $attr->{ID};  

  if ($attr->{title}) {
    $self->{title} = $attr->{title};
    $self->{table} .= $self->table_title($SORT, $DESC, $PG, $attr->{title}, $attr->{qs});
  }
  elsif ($attr->{title_plain}) {
    $self->{table} .= $self->table_title_plain($attr->{title_plain});
  }

  if ($attr->{pages} && !$FORM{EXPORT_CONTENT}) {
    my $op;
    if ($FORM{index}) {
      $op = "index=$FORM{index}";
    }

    my %ATTR = ();
    if (defined($attr->{recs_on_page})) {
      $ATTR{recs_on_page} = $attr->{recs_on_page};
    }
    $self->{pages} = $self->pages($attr->{pages}, "$op$attr->{qs}", {%ATTR});
  }

  return $self;
}

#*******************************************************************
# addrows()
#*******************************************************************
sub addrow {
  my $self = shift;
  my (@row) = @_;

  my $extra = (defined($self->{extra})) ? " $self->{extra}" : '';
  $row_number++;
  my $col_num=0;

  foreach my $val (@row) {
    if($self->{title}->[$col_num] &&  $self->{title}->[$col_num] eq '-') {
      next;
    }

    $self->{rows} .= $self->link_former($val, { SKIP_SPACE => 1 }) . "$COLS_SEPARATOR";
    $col_num++;
  }

  $self->{rows} .= "\r\n";
  return $self->{rows};
}

#*******************************************************************
# addrows()
#*******************************************************************
sub addtd {
  my $self  = shift;
  my (@row) = @_;
  my $extra = (defined($self->{extra})) ? $self->{extra} : '';

  foreach my $val (@row) {
    $self->{rows} .= "$val$COLS_SEPARATOR";
  }
  $self->{rows} .= "\n";
  return $self->{rows};
}

#*******************************************************************
# Extendet add rows
# th()
#*******************************************************************
sub th {
  my $self = shift;
  my ($value, $attr) = @_;

  return $self->td($value, { TH => 1 });
}

#*******************************************************************
# Extendet add rows
# td()
#
#*******************************************************************
sub td {
  my $self = shift;
  my ($value, $attr) = @_;
  my $extra = '';

  while (my ($k, $v) = each %$attr) {
    #$extra.=" $k=\"$v\"";
  }

  my $td = '';
  if ($attr->{TH}) {
    $td .= $value if (defined($value));
  }
  else {
    $td .= $value if (defined($value));
  }

  #$td .= $COLS_SEPARATOR;
  return $td;
}

#*******************************************************************
# title_plain($caption)
# $caption - ref to caption array
#*******************************************************************
sub table_title_plain {
  my $self = shift;
  my ($caption) = @_;

  $self->{table_title} = '';

  my $i = 0;
  foreach my $line (@$caption) {
    $self->{table_title} .= " $line $COLS_SEPARATOR;";
    $i++;
  }

  $self->{table_title}="\n";

  return $self->{table_title};
}

#*******************************************************************
# Show table column  titles with wort derectives
# Arguments
# table_title($sort, $desc, $pg, $caption, $qs);
# $sort - sort column
# $desc - DESC / ASC
# $pg - page id
# $caption - array off caption
#*******************************************************************
sub table_title {
  my $self = shift;
  my ($sort, $desc, $pg, $caption, $qs) = @_;

  $self->table_title_plain($caption);

  return $self->{table_title};
}

#**********************************************************
#
# img($img, $name, $attr)
#**********************************************************
sub img {
  my $self = shift;
  my ($img, $name, $attr) = @_;
  
  return "";

  my $img_path = ($img =~ s/^://) ? "$IMG_PATH/" : '';
  return "<img alt='$name' src='$img_path$img' border='0'>";
}

#**********************************************************
# show
#**********************************************************
sub show {
  my $self = shift;
  my ($attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return '';
  }

  $self->{show} = $self->{table};
  $self->{show} .= $self->{rows};

  if (defined($self->{pages})) {
    $self->{show} = $self->{show} . $self->{pages};
  }

  if (defined($self->{NO_PRINT}) && !defined($attr->{OUTPUT2RETURN})) {
    $self->{prototype}->{OUTPUT} .= $self->{show};
    $self->{show} = '';
  }

  return $self->{show};
}

#**********************************************************
#
#**********************************************************
sub link_former {
  my ($self) = shift;
  my ($params, $attr) = @_;

  $params =~ s/ /%20/g if (!$attr->{SKIP_SPACE});
  $params =~ s/&/&amp;/g;
  $params =~ s/>/&gt;/g;
  $params =~ s/</&lt;/g;
  $params =~ s/\"/&quot;/g;

  return $params;
}

#**********************************************************
#
# button($name, $params, $attr)
#**********************************************************
sub button {
  my $self = shift;
  my ($name, $params, $attr) = @_;
  
  return $name;
  
  my $ex_params = (defined($attr->{ex_params})) ? $attr->{ex_params} : '';
  my $ex_attr = '';

  $params = ($attr->{GLOBAL_URL}) ? $attr->{GLOBAL_URL} : "$params";

  $params = $attr->{JAVASCRIPT} if (defined($attr->{JAVASCRIPT}));
  $params = $self->link_former($params);

  $ex_attr = " TITLE='$attr->{TITLE}'" if (defined($attr->{TITLE}));

  my $button = "<BUTTON VALUE=\"$params\" $ex_attr>$name</BUTTON>";

  return $button;
}

#*******************************************************************
# Show message box
# message($self, $type, $caption, $message)
# $type - info, err
#*******************************************************************
sub message {
  my $self = shift;
  my ($type, $caption, $message) = @_;
  my $output = "$type: [CAPTION] $message\n";

  if (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $output;
    return $output;
  }
  else {
    print $output;
  }
}

#*******************************************************************
# Make pages and count total records
# pages($count, $argument)
#*******************************************************************
sub pages {
  my $self = shift;
  my ($count, $argument, $attr) = @_;

  if (defined($attr->{recs_on_page})) {
    $PAGE_ROWS = $attr->{recs_on_page};
  }

  my $begin = 0;

  return '' if ($count < $PAGE_ROWS);

  $self->{pages} = '';
  $begin = ($PG - $PAGE_ROWS * 3 < 0) ? 0 : $PG - $PAGE_ROWS * 3;

  for (my $i = $begin ; ($i <= $count && $i < $PG + $PAGE_ROWS * 10) ; $i += $PAGE_ROWS) {
    $self->{pages} .= ($i == $PG) ? "[$i] " : $i. '';
  }

  return $self->{pages} . "\n";
}

#*******************************************************************
# Make data field
# date_fld($base_name)
#*******************************************************************
sub date_fld {
  my $self = shift;
  my ($base_name, $attr) = @_;

  my $MONTHES = $attr->{MONTHES};

  my ($sec, $min, $hour, $mday, $mon, $curyear, $wday, $yday, $isdst) = localtime(time);

  my $day   = $FORM{ $base_name . 'D' } || 1;
  my $month = $FORM{ $base_name . 'M' } || $mon;
  my $year  = $FORM{ $base_name . 'Y' } || $curyear + 1900;

  my $result = "$year-$month-$day";

  return $result;
}

#*******************************************************************
# Make data field
# date_fld($base_name)
#*******************************************************************
sub date_fld2 {
  my $self = shift;
  my ($base_name, $attr) = @_;

  my $MONTHES = $attr->{MONTHES};

  my ($sec, $min, $hour, $mday, $mon, $curyear, $wday, $yday, $isdst) = localtime(time);

  my $day   = $FORM{ $base_name . 'D' } || 1;
  my $month = $FORM{ $base_name . 'M' } || $mon;
  my $year  = $FORM{ $base_name . 'Y' } || $curyear + 1900;
  my $result = "$year-$month-$day";

  if ($FORM{$base_name}) {
    my $date = $FORM{$base_name};
    $self->{$base_name} = $date;
  }
  elsif (!$attr->{NO_DEFAULT_DATE}) {
    my ($sec, $min, $hour, $mday, $mon, $curyear, $wday, $yday, $isdst) = localtime(time + (($attr->{NEXT_DAY}) ? 86400 : 0));

    my $month = $mon + 1;
    my $year  = $curyear + 1900;
    my $day   = $mday;

    if ($base_name =~ /to/i) {
      $day = ($month != 2 ? (($month % 2) ^ ($month > 7)) + 30 : (!($year % 400) || !($year % 4) && ($year % 25) ? 29 : 28));
    }
    elsif ($base_name =~ /from/i && !$attr->{NEXT_DAY}) {
      $day = 1;
    }
    my $date = sprintf("%d-%.2d-%.2d", $year, $month, $day);
    $self->{$base_name} = $date;
  }

  return $result;
}

#**********************************************************
# log_print()
#**********************************************************
sub log_print {
  my $self = shift;
  my ($level, $text) = @_;

  if ($debug < $log_levels{$level}) {
    return 0;
  }

print << "[END]";
$text
[END]
}

#**********************************************************
# show tamplate
# tpl_show
#
# template
# variables_ref
# atrr [EX_VARIABLES]
#**********************************************************
sub tpl_show {
  my $self = shift;
  my ($tpl, $variables_ref, $attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
    return '';
  }

  if (!$attr->{SOURCE}) {
    while ($tpl =~ /\%(\w+)(\=?)([A-Za-z0-9\_\.\/\\\]\[:\-]{0,50})\%/g) {
      my $var       = $1;
      my $delimiter = $2;
      my $default   = $3;

      #    if ($var =~ /$\{exec:.+\}$/) {
      #      my $exec = $1;
      #      if ($exec !~ /$\/usr/abills\/\misc\/ /);
      #      my $exec_content = system("$1");
      #      $tpl =~ s/\%$var\%/$exec_content/g;
      #     }
      #    els

      if ($attr->{SKIP_VARS} && $attr->{SKIP_VARS} =~ /$var/) {
      }
      elsif ($default && $default =~ /expr:(.*)/) {
        my @expr_arr = split(/\//, $1, 2);
        $variables_ref->{$var} =~ s/$expr_arr[0]/$expr_arr[1]/g;
        $default               =~ s/\//\\\//g;
        $default               =~ s/\[/\\\[/g;
        $default               =~ s/\]/\\\]/g;
        $tpl                   =~ s/\%$var$delimiter$default%/$variables_ref->{$var}/g;
      }
      elsif (defined($variables_ref->{$var})) {
        if ($variables_ref->{$var} !~ /\=\'|\' | \'/ && !$attr->{SKIP_QUOTE}) {
          $variables_ref->{$var} =~ s/\'/&rsquo;/g;
        }
        $tpl =~ s/\%$var$delimiter$default%/$variables_ref->{$var}/g;
      }
      else {
        $tpl =~ s/\%$var$delimiter$default\%/$default/g;
      }
    }
  }

  if ($attr->{OUTPUT2RETURN}) {
    return $tpl;
  }
  elsif ($attr->{MAIN}) {
    $self->{OUTPUT} .= "$tpl";
    return $tpl;
  }
  elsif ($attr->{notprint} || $self->{NO_PRINT}) {
    $self->{OUTPUT} .= $tpl;

    return $tpl;
  }
  else {
    print "$tpl";
  }
}

#**********************************************************
# test function
#  %FORM     - Form
#  %COOKIES  - Cookies
#  %ENV      - Enviropment
#
#**********************************************************
sub test {
  my $output = '';

  while (my ($k, $v) = each %FORM) {
    $output .= "$k | $v\n" if ($k ne '__BUFFER');
  }

  $output .= "\n";
  while (my ($k, $v) = each %COOKIES) {
    $output .= "$k | $v\n";
  }
}

#**********************************************************
# b();
#**********************************************************
sub b {
  my ($self) = shift;
  my ($text) = @_;

  return $text;
}

#**********************************************************
# b();
#**********************************************************
sub p {
  my ($self) = shift;
  my ($text) = @_;

  return $text;
}

#**********************************************************
# letters_list();
#**********************************************************
sub letters_list {
  my ($self, $attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
    return "";    #"<a> $FORM{EXPORT_CONTENT} </a>";
  }

  my $pages_qs = $attr->{pages_qs} if (defined($attr->{pages_qs}));

  my $output = '<LETTERS>' . $self->button('All ', "index=$index");
  for (my $i = 97 ; $i < 123 ; $i++) {
    my $l = chr($i);
    if ($FORM{letter} && $FORM{letter} eq $l) {
      $output .= "<b>$l </b>";
    }
    else {
      $output .= $self->button("$l", "index=$index&letter=$l$pages_qs") . "\n";
    }
  }
  $output .= '</LETTERS>';

  if (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $output;
    return '';
  }
  else {
    print $output;
  }

}

#*******************************************************************
# Mark text
#*******************************************************************
sub color_mark {
  my $self = shift;
  my ($message, $color, $attr) = @_;

  return $message if ($attr->{SKIP_XML});

  my $output = "!! $message !!";
  return $output;
}

#**********************************************************
# Break line
#
#**********************************************************
sub br () {
  my $self = shift;
  my ($attr) = @_;

  return "\n";
}


#*******************************************************************
# element
#*******************************************************************
sub element {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  my $params = '';
  if (ref $attr eq 'HASH') {
    while(my($k, $v)=each %$attr) {
      $params .= "$k='$v' ";
    }  
  }

  $self->{FORM_INPUT} = "<$name $params>$value</$name>";

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

1
