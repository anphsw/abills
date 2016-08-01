#package Abills::Templates;

=head1 NAME

  Base ABIllS Templates Managments

=cut

#use strict;

my $domain_path = '';
our $Bin;
our %FORM;
our $admin;
our $html;
our %lang;

use FindBin '$Bin';
if ($admin->{DOMAIN_ID}) {
  $domain_path = "$admin->{DOMAIN_ID}/";
}

#**********************************************************
=head2 _include($tpl, $module, $attr) - templates

  Arguments
    $tpl
    $module
    $attr
      CHECK_ONLY
      SUFIX
      DEBUG

  Returns:
    Retun content

=cut
#**********************************************************
sub _include {
  my ($tpl, $module, $attr) = @_;

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
    $Bin . '/../Abills/templates/' . $module . '_' . $tpl . "_$html->{language}" . $sufix
  );

  foreach my $result_template (@search_paths) {
    if($attr->{DEBUG}) {
      print $realfilename . "\n";
    }

    if (-f $result_template) {
      if ($attr->{CHECK_ONLY}) {
        return 1;
      }
      else {
        return ($FORM{pdf}) ? $result_template : tpl_content($result_template) ;
      }
    }
  }

  if ($attr->{CHECK_ONLY}) {
    return 0;
  }

  if ($module) {
    $tpl = "modules/$module/templates/$tpl";
  }

  foreach my $prefix ('../', @INC) {
    my $realfilename = "$prefix/Abills/$tpl$sufix";

    if($attr->{DEBUG}) {
      print $realfilename . "\n";
    }

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

  return "No such module template [$tpl]\n";
}

#**********************************************************
=head2 tpl_content($filename, $attr)

=cut
#**********************************************************
sub tpl_content {
  my ($filename) = @_;
  my $tpl_content = '';

  # $s =~ s/\{(\w+)\}/$lang{$1}/sg;

  open(my $fh, '<', $filename) || die "Can't open file '$filename' $!";
    while (<$fh>) {
      if (/\$/) {
        my $res = $_;
        $res =~ s/\_\{(\w+)\}\_/$lang{$1}/sg;
        $res =~ s/\{secretkey\}//g;
        $res =~ s/\{dbpasswd\}//g;
        $tpl_content .= eval " \"$res\" ";
      }
      else {
        s/\_\{(\w+)\}\_/$lang{$1}/sg;
        $tpl_content .= $_;
      }
    }
  close($fh);

  return $tpl_content;
}

#**********************************************************
=head2 templates($tpl_name) - Show template

  Arguments:
    $tpl_name

  Return:
    tpl content

=cut
#**********************************************************
sub templates {
  my ($tpl_name) = @_;

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
  else {

    my @search_paths = (
      #Lang tpls
         $Bin . "/../../Abills/templates/$domain_path" . '_' . "$tpl_name" . "_$html->{language}.tpl",
         $Bin . "/../Abills/templates/$domain_path" . '_' . "$tpl_name" . "_$html->{language}.tpl",
         $Bin . "/../Abills/templates/_$tpl_name" . "_$html->{language}.tpl",
         $Bin . "/../../Abills/main_tpls/$tpl_name" . "_$html->{language}.tpl",
         $Bin . "/../Abills/main_tpls/$tpl_name" . "_$html->{language}.tpl",
      #Main tpl
         $Bin . "/../../Abills/templates/$domain_path" . '_' . "$tpl_name" . '.tpl',
         $Bin . "/../Abills/templates/$domain_path" . '_' . "$tpl_name" . ".tpl",
         $Bin . "/../Abills/templates/_$tpl_name" . ".tpl",
         $Bin . "/../../Abills/main_tpls/$tpl_name" . ".tpl",
      $Bin . "/../Abills/main_tpls/$tpl_name" . ".tpl",
      $conf{base_dir} . "/Abills/main_tpls/$tpl_name" . ".tpl",
      $conf{base_dir} . "/Abills/templates/$tpl_name" . ".tpl",
    );

    foreach my $tpl ( @search_paths ) {
      if (-f $tpl) {
        return tpl_content($tpl);
      }
    }
  }

  return "No such template [$tpl_name]";
}

1

