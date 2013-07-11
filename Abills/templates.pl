# Base ABIllS Templates Managments

use FindBin '$Bin';

my $domain_path = '';
if ($admin->{DOMAIN_ID}) {
  $domain_path = "$admin->{DOMAIN_ID}/";
}

#**********************************************************
# templates
#**********************************************************
sub _include {
  my ($tpl, $module, $attr) = @_;
  my $result = '';

  my $sufix = ($attr->{pdf} || $FORM{pdf}) ? '.pdf' : '.tpl';
  $tpl .= '_' . $attr->{SUFIX} if ($attr->{SUFIX});

  start:
  $domain_path = '';
  if ($admin->{DOMAIN_ID}) {
    $domain_path = "$admin->{DOMAIN_ID}/";
  }
  elsif ($FORM{DOMAIN_ID}) {
    $domain_path = "$FORM{DOMAIN_ID}/";
  }

  $FORM{NAS_GID}='' if (!$FORM{NAS_GID});

  my @search_paths = (
    $Bin . '/../Abills/templates/' . $domain_path . '/' . $FORM{NAS_GID} . '/' . $module . '_' . $tpl . "_$html->{language}" . $sufix,
    $Bin . '/../Abills/templates/' . $domain_path . '/' . $FORM{NAS_GID} . '/' . $module . '_' . $tpl . $sufix,
    $Bin . '/../Abills/templates/' . $domain_path  . $module . '_' . $tpl . "_$html->{language}" . $sufix,
           '../Abills/templates/' . $domain_path . $module . '_' . $tpl . "_$html->{language}" . $sufix,
           '../../Abills/templates/' . $domain_path . $module . '_' . $tpl . "_$html->{language}" . $sufix,
           '../../Abills/templates/' . $domain_path . $module . '_' . $tpl . $sufix,
           '../Abills/templates/' . $domain_path . $module . '_' . $tpl . $sufix,
    $Bin . '/../Abills/templates/'. $domain_path . $module . '_' . $tpl . $sufix,
    $Bin . '/../Abills/templates/' . $module . '_' . $tpl . "_$html->{language}" . $sufix,

#    $Bin . '/../Abills/templates/' . $module . '_' . $tpl . $sufix,
#           '../Abills/templates/' . $module . '_' . $tpl . $sufix,
  );

  foreach my $result_template (@search_paths) {
    if (-f $result_template) {
      return ($FORM{pdf}) ? $result_template : tpl_content($result_template) ;
    }
  }

  if ($module) {
    $tpl = "modules/$module/templates/$tpl";
  }

  foreach my $prefix (@INC) {
    my $realfilename = "$prefix/Abills/$tpl$sufix";
    if (-f $realfilename) {
      return ($FORM{pdf}) ? $realfilename : tpl_content($realfilename);
    }
  }

  if ($attr->{SUFIX}) {
    $tpl =~ /\/([a-z0-9\_\.\-]+)$/i;
    $tpl = $1;
    $tpl =~ s/_$attr->{SUFIX}$//;
    delete $attr->{SUFIX};
    goto start;
  }

  return "No such template [$tpl]\n";
}

#**********************************************************
# templates
#**********************************************************
sub tpl_content {
  my ($filename, $attr) = @_;
  my $tpl_content = '';

  open(FILE, "$filename") || die "Can't open file '$filename' $!";
  while (<FILE>) {
    $tpl_content .= eval "\"$_\"";
  }
  close(FILE);

  return $tpl_content;
}

#**********************************************************
# templates
#**********************************************************
sub templates {
  my ($tpl_name, $attr) = @_;

  if ($admin->{DOMAIN_ID}) {
    $domain_path = "$admin->{DOMAIN_ID}/";
  }

  #Nas path
  if ($FORM{NAS_GID} && -f $Bin . "/../Abills/templates/$domain_path" . '/' . $FORM{NAS_GID} . '/' . "_$tpl_name" . "_$html->{language}.tpl") {
    return tpl_content($Bin . "/../Abills/templates/$domain_path" . '/' . $FORM{NAS_GID} . '/' . "_$tpl_name" . "_$html->{language}.tpl");
  }
  elsif ($FORM{NAS_GID} && -f $Bin . "/../Abills/templates/$domain_path" . '/' . $FORM{NAS_GID} . '/' . "_$tpl_name" . ".tpl") {
    return tpl_content($Bin . "/../Abills/templates/$domain_path" . '/' . $FORM{NAS_GID} . '/' . "_$tpl_name" . ".tpl");

  }

  #Lang tpls
  elsif (-f $Bin . "/../../Abills/templates/$domain_path" . '_' . "$tpl_name" . "_$html->{language}.tpl") {
    return tpl_content("$Bin/../../Abills/templates/$domain_path" . '_' . "$tpl_name" . "_$html->{language}.tpl");
  }
  elsif (-f "$Bin/../Abills/templates/$domain_path" . '_' . "$tpl_name" . "_$html->{language}.tpl") {
    return tpl_content("$Bin/../Abills/templates/$domain_path" . '_' . "$tpl_name" . "_$html->{language}.tpl");
  }
  elsif (-f "$Bin/../Abills/templates/_$tpl_name" . "_$html->{language}.tpl") {
    return tpl_content("$Bin/../Abills/templates/_$tpl_name" . "_$html->{language}.tpl");
  }
  elsif (-f "$Bin/../../Abills/main_tpls/$tpl_name" . "_$html->{language}.tpl") {
    return tpl_content("$Bin/../../Abills/main_tpls/$tpl_name" . "_$html->{language}.tpl");
  }
  elsif (-f "$Bin/../Abills/main_tpls/$tpl_name" . "_$html->{language}.tpl") {
    return tpl_content("$Bin/../Abills/main_tpls/$tpl_name" . "_$html->{language}.tpl");
  }

  #Main tpl
  elsif (-f $Bin . "/../../Abills/templates/$domain_path" . '_' . "$tpl_name" . '.tpl') {
    return tpl_content("$Bin/../../Abills/templates/$domain_path" . '_' . "$tpl_name" . '.tpl');
  }
  elsif (-f "$Bin/../Abills/templates/$domain_path" . '_' . "$tpl_name" . ".tpl") {
    return tpl_content("$Bin/../Abills/templates/$domain_path" . '_' . "$tpl_name" . ".tpl");

  }
  elsif (-f "$Bin/../Abills/templates/_$tpl_name" . ".tpl") {
    return tpl_content("$Bin/../Abills/templates/_$tpl_name" . ".tpl");

  }
  elsif (-f "$Bin/../../Abills/main_tpls/$tpl_name" . ".tpl") {
    return tpl_content("$Bin/../../Abills/main_tpls/$tpl_name" . ".tpl");

  }
  elsif (-f "$Bin/../Abills/main_tpls/$tpl_name" . ".tpl") {
    return tpl_content("$Bin/../Abills/main_tpls/$tpl_name" . ".tpl");
  }

  return "No such template [$tpl_name]";
}

1

