package Abills::Templates;

=head1 NAME

  Base ABIllS Templates Managments

=cut

use strict;
use parent 'Exporter';

our (
  $libpath,
  $admin,
  $html,
  %conf,
);

our @EXPORT = qw(
  template_init
  _include
  templates
);

my $domain_path = '';
my $_form;
my $lang;

#**********************************************************
=head2 template_init($attr) - templates

  Arguments
    $attr
      LIBPATH
      ADMIN
      HTML
      FORM
      LANG
      CONF

  Returns:
    Return TRUE

=cut
#**********************************************************
sub template_init {
  my ($attr)=@_;

  (
    $libpath,
    $admin,
    $html,
    $lang,
    $_form
  ) =
    (@{$attr}{ qw/LIBPATH ADMIN HTML LANG FORM/ });

  %conf = %{ $attr->{CONF} // {} };

  return 1;
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
      CHECK_WITH_VALUE - return content or 0

  Returns:
    Return content

=cut
#**********************************************************
sub _include {
  my ($tpl, $module, $attr) = @_;

  my $sufix = ($attr->{pdf} || $_form->{pdf}) ? '.pdf' : '.tpl';
  $tpl .= '_' . $attr->{SUFIX} if ($attr->{SUFIX});

  start:
  $domain_path = '';
  if ($admin->{DOMAIN_ID}) {
    $domain_path = "$admin->{DOMAIN_ID}/";
  }
  elsif ($_form->{DOMAIN_ID}) {
    $domain_path = "$_form->{DOMAIN_ID}/";
  }

  $_form->{NAS_GID}='' if (!$_form->{NAS_GID});
  my $language = $html->{language} || q{};

  my @search_paths = (
    $libpath . 'Abills/templates/' . $domain_path . $module . '_' . $tpl . "_$language" . $sufix,
    $libpath . 'Abills/templates/' . $domain_path . $module . '_' . $tpl . $sufix,
  );

  if ($_form->{NAS_GID}) {
    unshift(@search_paths,
      $libpath . 'Abills/templates/' . $domain_path . '/' . $_form->{NAS_GID} . '/' . $module . '_' . $tpl . "_$language" . $sufix,
      $libpath . 'Abills/templates/' . $domain_path . '/' . $_form->{NAS_GID} . '/' . $module . '_' . $tpl . $sufix,
    )
  }

  foreach my $result_template (@search_paths) {
    if($attr->{DEBUG}) {
      print $result_template . "\n";
    }

    if (-f $result_template) {
      if ($attr->{CHECK_ONLY}) {
        return 1;
      }
      else {
        return ($_form->{pdf}) ? $result_template : tpl_content($result_template) ;
      }
    }
  }

  if ($attr->{CHECK_ONLY}) {
    return 0;
  }

  if ($module) {
    $tpl = "modules/$module/templates/$tpl";
  }

  foreach my $prefix ($libpath, @INC) {
    my $realfilename = "$prefix/Abills/$tpl$sufix";

    if($attr->{DEBUG}) {
      print $realfilename . "\n";
    }

    if (-f $realfilename) {
      return ($_form->{pdf}) ? $realfilename : tpl_content($realfilename);
    }
  }

  if ($attr->{SUFIX}) {
    ($tpl) = $tpl =~ /\/([a-z0-9\_\.\-]+)$/xi;
    $tpl =~ s/_$attr->{SUFIX}$//x;
    delete $attr->{SUFIX};
    goto start;
  }

  if ($attr->{CHECK_WITH_VALUE}) {
    return 0;
  }

  return "No such module template [$tpl]\n";
}

#**********************************************************
=head2 tpl_content($filename, $attr)

  Arguments:
    $filename,
    $attr

  Resultsd:
    $tenplate

=cut
#**********************************************************
sub tpl_content {
  my ($filename) = @_;
  my $tpl_content = '';

  if(! $lang) {
    $lang = {};
  }

  open(my $fh, '<', $filename) || die "Can't open tpl file '$filename' $!";
    while (<$fh>) {
      my $res = $_;
      if (my($marker)=/\$FORM\{(\S+)\}/xm) {
        $res =~ s/\$FORM\{$marker\}/$_form->{$marker}/sgx;
        $tpl_content .= $res;
      }
      elsif (my($marker2)=/\$conf\{(\S+)\}/xm) {
        $res =~ s/\$conf\{$marker2\}/$conf{$marker2}/sgx;
        $tpl_content .= $res;
      }
      elsif (/\$/xm) {
        if($res) {
          $res =~ s/\_\{(\w+)\}\_/$lang->{$1}/xsg;
          $res =~ s/\{secretkey\}//xg;
          $res =~ s/\{dbpasswd\}//xg;

          if($res !~ /\`/xm) {
            # if($^T != 0) {
            #   if ($res =~ /^([\s+&:#-\@\w.]+)$/xm) {
            #     $res = $1;
            #   }
            #   else {
            #     print "$filename Bad: $res\n";
            #   }
            # }
            $res = eval " \"$res\" ";
          }
          $tpl_content .= $res || q{};
        }
      }
      else {
        s/\_\{(\w+)\}\_/$lang->{$1}/sgx;
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

  if(! $conf{base_dir}) {
    $conf{base_dir} = '/usr/abills/';
  }

  $domain_path = '';
  my $language = $html->{language} || q{};
  if ($admin->{DOMAIN_ID}) {
    $domain_path = "$admin->{DOMAIN_ID}/";
  }

  my @search_paths = (
    #Lang tpls
    $libpath . "Abills/templates/$domain_path" . "_$tpl_name" . "_$language.tpl",
    $libpath . "Abills/templates/$domain_path" . "_$tpl_name" . ".tpl",

    #Main tpl
    $libpath . "Abills/main_tpls/$tpl_name" . ".tpl",
    $conf{base_dir} . "/Abills/templates/_$tpl_name" . ".tpl",
    $conf{base_dir} . "/Abills/main_tpls/$tpl_name" . ".tpl"
  );

  if ($_form->{NAS_GID}) {
    unshift(@search_paths,
      $libpath . "Abills/templates/$domain_path/$_form->{NAS_GID}/_$tpl_name" . "_$language.tpl",
      $libpath . "Abills/templates/$domain_path/$_form->{NAS_GID}/_$tpl_name.tpl",
    );
  }

  foreach my $tpl ( @search_paths ) {
    if (-f $tpl) {
      return tpl_content($tpl);
    }
  }

  return "No such template [$tpl_name]";
}

1;
