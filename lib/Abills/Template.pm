package Abills::Template;

use strict;
use warnings FATAL => 'all';

my Abills::HTML $html;
my $lang;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  my $admin = shift;
  my $conf = shift;
  my $attr = shift;

  $html = $attr->{html} if $attr->{html};
  $lang = $attr->{lang} && ref $attr->{lang} eq 'HASH' ? $attr->{lang} : {};

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $conf;
  $self->{libpath} = $attr->{libpath} ? $attr->{libpath} : '';

  return $self;
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
  my $self = shift;
  my ($tpl, $module, $attr) = @_;

  my $sufix = $attr->{pdf} ? '.pdf' : '.tpl';
  $tpl .= '_' . $attr->{SUFIX} if ($attr->{SUFIX});

  start:
  my $domain_path = $self->{admin} && $self->{admin}{DOMAIN_ID} ? "$self->{admin}{DOMAIN_ID}/" :
    $attr->{DOMAIN_ID} ? "$attr->{DOMAIN_ID}/" : '';
  $attr->{NAS_GID} ||= '';

  my $language = $html->{language} || q{};

  my @search_paths = (
    $self->{libpath} . 'Abills/templates/' . $domain_path . $module . '_' . $tpl . "_$language" . $sufix,
    $self->{libpath} . 'Abills/templates/' . $domain_path . $module . '_' . $tpl . $sufix,
  );

  if ($attr->{NAS_GID}) {
    unshift(@search_paths,
      $self->{libpath} . 'Abills/templates/' . $domain_path . '/' . $attr->{NAS_GID} . '/' . $module . '_' . $tpl . "_$language" . $sufix,
      $self->{libpath} . 'Abills/templates/' . $domain_path . '/' . $attr->{NAS_GID} . '/' . $module . '_' . $tpl . $sufix,
    )
  }

  foreach my $result_template (@search_paths) {
    if ($attr->{DEBUG}) {
      print $result_template . "\n";
    }

    if (-f $result_template) {
      if ($attr->{CHECK_ONLY}) {
        return 1;
      }
      else {
        return ($attr->{pdf}) ? $result_template : $self->tpl_content($result_template) ;
      }
    }
  }

  if ($attr->{CHECK_ONLY}) {
    return 0;
  }

  if ($module) {
    $tpl = "modules/$module/templates/$tpl";
  }

  foreach my $prefix ($self->{libpath}, @INC) {
    my $real_filename = "$prefix/Abills/$tpl$sufix";

    if($attr->{DEBUG}) {
      print $real_filename . "\n";
    }

    if (-f $real_filename) {
      return ($attr->{pdf}) ? $real_filename : $self->tpl_content($real_filename);
    }
  }

  if ($attr->{SUFIX}) {
    $tpl =~ /\/([a-z0-9\_\.\-]+)$/i;
    $tpl = $1;
    $tpl =~ s/_$attr->{SUFIX}$//;
    delete $attr->{SUFIX};
    goto start;
  }

  if ($attr->{CHECK_WITH_VALUE}) {
    return 0;
  }
  return "No such module template [$tpl]\n";
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
  my $self = shift;
  my $tpl_name = shift;
  my ($attr) = @_;

  if(! $self->{conf}{base_dir}) {
    $self->{conf}{base_dir} = '/usr/abills/';
  }

  my $domain_path = '';
  my $language = $html->{language} || q{};
  if ($self->{admin}{DOMAIN_ID}) {
    $domain_path = "$self->{admin}{DOMAIN_ID}/";
  }

  my @search_paths = (
    #Lang tpls
    $self->{libpath} . "Abills/templates/$domain_path" . "_$tpl_name" . "_$language.tpl",
    $self->{libpath} . "Abills/templates/$domain_path" . "_$tpl_name" . ".tpl",

    #Main tpl
    $self->{libpath} . "Abills/main_tpls/$tpl_name" . ".tpl",
    $self->{conf}{base_dir} . "/Abills/main_tpls/$tpl_name" . ".tpl",
    $self->{conf}{base_dir} . "/Abills/templates/$tpl_name" . ".tpl",
  );

  if ($attr->{NAS_GID}) {
    unshift(@search_paths,
      $self->{libpath} . "Abills/templates/$domain_path/$attr->{NAS_GID}/_$tpl_name" . "_$language.tpl",
      $self->{libpath} . "Abills/templates/$domain_path/$attr->{NAS_GID}/_$tpl_name.tpl",
    );
  }

  foreach my $tpl (@search_paths) {
    if (-f $tpl) {
      return $self->tpl_content($tpl);
    }
  }

  return "No such template [$tpl_name]";
}

#**********************************************************
=head2 tpl_content($filename)

=cut
#**********************************************************
sub tpl_content {
  my $self = shift;
  my $filename = shift;

  my $tpl_content = '';
  return $tpl_content if !$filename;

  open(my $fh, '<', $filename) || die "Can't open tpl file '$filename' $!";
  while (<$fh>) {
    if (/\$/) {
      my $res = $_;
      if($res) {
        $res =~ s/\_\{(\w+)\}\_/$lang->{$1} || ''/esg;
        $res =~ s/\{secretkey\}//g;
        $res =~ s/\{dbpasswd\}//g;
        $res = eval " \"$res\" " if($res !~ /\`/);
        $tpl_content .= $res || q{};
      }
    }
    else {
      s/\_\{(\w+)\}\_/$lang->{$1} || ''/esg;
      $tpl_content .= $_;
    }
  }
  close($fh);

  return $tpl_content;
}

1;