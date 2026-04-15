=head1 NAME

  Templates functions

=cut


use strict;
use warnings FATAL => 'all';
use Abills::Base qw(clearquotes convert dsc2hash);

our (
  %lang,
  $base_dir,
  %LANG,      #config available lang
  #@MONTHES   ,
  #@WEEKDAYS  ,
  #@bool_vals ,
  #%permissions
  #  @state_colors,
  #  %COOKIES
);

our Abills::HTML $html;
our Admins $admin;

#**********************************************************
=head2 form_templates() - Create templates and manage template

=cut
#**********************************************************
sub form_templates {

  my $sys_templates = '../../Abills/modules';
  my $main_templates_dir = '../../Abills/main_tpls/';
  my %info = (TEMPLATE => '', ORIG_TEMPLATE => '');
  my $main_tpl_name = '';

  my $domain_path = '';
  if ($admin->{DOMAIN_ID}) {
    $domain_path = "$admin->{DOMAIN_ID}/";
    $conf{TPL_DIR} = "$conf{TPL_DIR}/$domain_path";
    if (!-d $conf{TPL_DIR}) {
      if (!mkdir($conf{TPL_DIR})) {
        $html->message('err', $lang{ERROR}, "$lang{ERR_CANT_CREATE_FILE} '$conf{TPL_DIR}' $lang{ERROR}: $!\n");
      }
    }
  }

  $info{ACTION_LNG} = $lang{SAVE};

  if ($FORM{create}) {
    my ($module, $file, $lang) = split(/:/x, $FORM{create}, 3);

    if ($file !~ /\.tpl$/x) {
      $file .= ".tpl";
    }

    $info{TEMPLATE} = file_op({
      FILENAME => $file,
      PATH     => ($module) ? "$sys_templates/$module/templates/" : "$main_templates_dir/"
    });

    my $filename = ($module) ? "$sys_templates/$module/templates/$file" : "$main_templates_dir/$file";
    if ($lang) {
      $file =~ s/\.tpl/_$lang/x;
      $file .= '.tpl';
    }

    $main_tpl_name = $file;
    $info{TPL_NAME} = "$module" . '_' . "$file";

    $info{TEMPLATE} =~ s/\\"/"/xg;
    show_tpl_info($filename, ($module) ? "$sys_templates/$module/templates/" : "$main_templates_dir/");
  }
  elsif ($FORM{SHOW}) {
    $html->{METATAGS} = templates('metatags');
    print $html->header();
    my ($module, $file, $lang) = split(/:/x, $FORM{SHOW}, 3);
    $file =~ s/.tpl//x;
    $file =~ s/\s+|\///xg;

    $html->{language} = $lang if ($lang && $lang ne '');

    if ($module) {
      my $realfilename = "/Abills/modules/$module/lng_$html->{language}.pl";
      my $lang_file = '';
      my $prefix = '../..';
      if (-f $realfilename) {
        $lang_file = $realfilename;
      }
      elsif (-f "$prefix/Abills/modules/$module/lng_english.pl") {
        $lang_file = "$prefix/Abills/modules/$module/lng_english.pl";
      }

      if ($lang_file ne '') {
        do $lang_file;
      }
    }

    if ($module) {
      $html->tpl_show(_include("$file", "$module"), { LNG_ACTION => $lang{ADD} },);
    }
    else {
      $html->tpl_show(templates("$file"), { LNG_ACTION => $lang{ADD} },);
    }

    return 0;
  }
  elsif ($FORM{change}) {
    my %FORM2 = ();
    my @pairs = split(/&/x, $FORM{__BUFFER} || q{});
    $info{ACTION_LNG} = $lang{CHANGE};

    foreach my $pair (@pairs) {
      my ($side, $value) = split(/=/x, $pair);
      $value =~ tr/+/ /;
      $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/xeg;

      if (defined($FORM2{$side})) {
        $FORM2{$side} .= ", $value";
      }
      else {
        $FORM2{$side} = $value;
      }
    }

    if ($FORM{FORMAT} && $FORM{FORMAT} eq 'unix') {
      $FORM2{template} =~ s/\r//xg;
    }

    $info{TEMPLATE} = $FORM2{template} || q{};
    $info{TPL_NAME} = $FORM{tpl_name};
    if ($info{TEMPLATE}) {
      $info{TEMPLATE} = convert($info{TEMPLATE}, { '2_tpl' => 1 });
      $info{TEMPLATE} =~ s/\"/\'/xg;
      $info{TEMPLATE} =~ s/\@/\\@/xg;
    }

    if ($info{TEMPLATE}) {
      file_op({ WRITE => 1,
        FILENAME      => $FORM{tpl_name},
        PATH          => $conf{TPL_DIR},
        CONTENT       => $info{TEMPLATE}
      });

      $main_tpl_name = $FORM{tpl_name};
      $main_tpl_name =~ s/^_//x;
      $info{TEMPLATE} =~ s/\\"/"/xg;
      $info{TEMPLATE} =~ s/\\\@/\@/xg;
      $admin->system_action_add("$lang{CHANGED} - " . ($FORM{tpl_name} || q{}), { TYPE => 60 });
    }
    else {
      $html->message('err', 'Empty', $lang{ERR_NODATA});
    }
  }
  elsif ($FORM{FILE_UPLOAD}) {
    if ($FORM{FILE_UPLOAD}{filename}) {
      upload_file($FORM{FILE_UPLOAD}, { EXTENTIONS => 'tpl,jpg,pdf,dsc,gif,jpeg,png,ico' });
      $admin->system_action_add("$lang{ADDED} $lang{FILE} - $FORM{FILE_UPLOAD}{filename}", { TYPE => 62 });
    }
  }
  elsif ($FORM{file_del} && $FORM{COMMENTS}) {
    $FORM{file_del} =~ s/\s|\///xg;
    if (unlink("$conf{TPL_DIR}/$FORM{file_del}") == 1) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED}: '$FORM{file_del}'");
      $admin->system_action_add("$lang{DELETED} - $FORM{file_del} - $FORM{COMMENTS}", { TYPE => 63 });
    }
    else {
      $html->message('err', $lang{DELETED}, "$lang{ERROR}");
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $FORM{del} =~ s/\s|\///xg;
    if (unlink("$conf{TPL_DIR}/$FORM{del}") == 1) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED}: '$FORM{del}'");
      $admin->system_action_add("$lang{DEL} - $FORM{del} - $FORM{COMMENTS}", { TYPE => 61 });
    }
    else {
      $html->message('err', $lang{DELETED}, "$lang{ERROR} '$conf{TPL_DIR}/$FORM{del}' $!");
    }
  }
  elsif ($FORM{tpl_name}) {
    $info{ACTION_LNG} = $lang{CHANGE};

    my ($module, $file) = split(/_/x, $FORM{tpl_name}, 2);
    $file = $FORM{orig_template} if ($FORM{orig_template});

    $info{TEMPLATE} = file_op({
      FILENAME => $FORM{tpl_name},
      PATH     => $conf{TPL_DIR},
    });

    $info{ORIG_TEMPLATE} = file_op({
      FILENAME => $file,
      PATH     => $module ? "$sys_templates/$module/templates/" : "$main_templates_dir/"
    });

    if ($info{TEMPLATE}) {
      show_tpl_info("$conf{TPL_DIR}/$FORM{tpl_name}", $conf{TPL_DIR});

      $info{TPL_NAME} = $FORM{tpl_name};

      $main_tpl_name = $FORM{tpl_name};
      $main_tpl_name =~ s/^_//x;

      $info{TEMPLATE} =~ s/\\"/"/xg;
    }
  }

  $info{TEMPLATE} = convert($info{TEMPLATE}, { from_tpl => 1 });
  $info{ORIG_TEMPLATE} = convert($info{ORIG_TEMPLATE}, { from_tpl => 1 });

  $FORM{create} = '' if (!$FORM{create});
  $FORM{tpl_name} = '' if (!$FORM{create});
  $info{TPL_NAME} = '' if (!$info{TPL_NAME});

  my $card = templates('form_template_card');
  $info{CARDS} = $html->tpl_show($card, { TITLE => $lang{PREVIOUS} }, { OUTPUT2RETURN => 1 });
  $info{CARDS} .= $html->tpl_show($card, { TITLE => $lang{YOUR} }, { OUTPUT2RETURN => 1 });
  if ($info{ORIG_TEMPLATE}) {
    $info{CARDS} .= $html->tpl_show($card, { TITLE => $lang{SYSTEM} }, { OUTPUT2RETURN => 1 });
  }

  my $tpl_ = $html->tpl_show(templates('form_template_editor'), \%info, { OUTPUT2RETURN => 1 });
  $tpl_ =~ s/__TEMPLATE__/$info{TEMPLATE}/xg;
  $tpl_ =~ s/__ORIG_TEMPLATE__/$info{ORIG_TEMPLATE}/xg;
  print $tpl_;
  if ($info{TPL_NAME} =~ /_admin_menu/xm) {
    admin_menu();
  }
  elsif ($info{TPL_NAME} =~ /_client_menu/xm) {
    client_menu();
  }

  form_templates_list({
    MAIN_TPL_NAME => $main_tpl_name
  });

  form_templates_files();

  return 1;
}

#**********************************************************
=head2 form_templates_list($attr) Get teblate describe

  Arguments:
    $attr

  Results:
    \%tpls_describe

=cut
#**********************************************************
sub form_templates_list {
  my ($attr)=@_;

  my $sys_templates = '../../Abills/modules';
  my $main_templates_dir = '../../Abills/main_tpls/';
  my $main_tpl_name = $attr->{MAIN_TPL_NAME} || q{};

  my @header_arr = ("$lang{MAIN}:index=$index&MODULE=main");
  foreach my $module (sort @MODULES) {
    if (-d "$sys_templates/$module/templates") {
      push @header_arr, "$module:index=$index&MODULE=$module";
    }
  }

  my $module_title = ($FORM{MODULE} && $FORM{MODULE} ne 'main') ? $FORM{MODULE} : $lang{MAIN};
  my $template_path = ($FORM{MODULE} && $FORM{MODULE} ne 'main') ? "$sys_templates/$module_title/templates" : $main_templates_dir;

  print $html->table_header(\@header_arr, { TABS => 1, FORCED_CHECK_NAME => $module_title, class => 'mb-2' });

  #Make active lang list
  if ($conf{LANGS}) {
    $conf{LANGS} =~ s/\n//xg;
    my (@lang_arr) = split(';', $conf{LANGS});
    %LANG = ();
    foreach my $l (@lang_arr) {
      my ($lang, $lang_name) = split(':', $l);
      $lang =~ s/^\s+//x;
      $LANG{$lang} = $lang_name;
    }
  }

  my @caption = sort keys %LANG;
  $FORM{MODULE} //= 'main';

  my $table = $html->table({
    width       => '100%',
    caption     => $html->b($module_title) . ' ' . $template_path,
    title_plain => [ $lang{FILE}, "$lang{SIZE} (Byte)", $lang{DATE}, $lang{DESCRIBE}, $lang{MAIN}, @caption ],
    ID          => 'TEMPLATES_LIST',
    DATA_TABLE  => 1,
  });

  #Main templates
  if ($FORM{MODULE} && $FORM{MODULE} eq 'main') {
    if (-d $main_templates_dir) {
      my @contents = ();
       my $tpl_describe = get_tpl_describe("describe.tpls", $main_templates_dir);
       if (opendir my $fh, "$main_templates_dir") {
         @contents = grep {!/^\.\.?$/mx} readdir $fh;
         closedir $fh;
       }
       else {
         $html->message('err', "Can't open dir '$sys_templates/main_tpls' $!");
         return 0;
       }

       delete $table->{rowcolor};
       delete $table->{extra};
       my $module = "";
       foreach my $file (sort @contents) {
         if (-d "$main_templates_dir$file") {
           next;
         }
         elsif ($file !~ /\.tpl$/mx) {
           next;
         }

         my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks);
         my $tpl_file = "$conf{TPL_DIR}/$module" . "_$file";
         if (-f $tpl_file) {
           ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$conf{TPL_DIR}/$module" . "_$file");
           $mtime = POSIX::strftime("%Y-%m-%d", localtime($mtime));
         }
         else {
           ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$main_templates_dir" . $file);
           $mtime = POSIX::strftime("%Y-%m-%d", localtime($mtime));
         }

        # LANG
        my @rows = (
          $file, $size, $mtime, (($tpl_describe->{$file}) ? $tpl_describe->{$file} : ''),
          $html->button($lang{SHOW}, "#", { NEW_WINDOW => "$SELF_URL?qindex=$index&SHOW=$module:$file", class => 'show' })
            . ((-f "$conf{TPL_DIR}/_$file") ? $html->button($lang{CHANGE}, "index=$index&tpl_name=_$file&orig_template=$file.tpl", { class => 'change', }) : $html->button($lang{CREATE}, "index=$index&create=:$file", { class => 'add' }))
            . ((-f "$conf{TPL_DIR}/_$file") ? $html->button($lang{DEL}, "index=$index&del=_$file", { MESSAGE => "$lang{DEL} '$file'", class => 'del' }) : '')
        );

        $file =~ s/\.tpl//x;
        foreach my $lang (@caption) {
          my $f = '_' . $file . '_' . $lang . '.tpl';
          push @rows,
            ((-f "$conf{TPL_DIR}/$f")
              ? $html->button($lang{SHOW}, "index=$index#", { NEW_WINDOW => "$SELF_URL?qindex=$index&SHOW=$module:$file:$lang", class => 'show' })
              . $html->br() . $html->button($lang{CHANGE}, "index=$index&tpl_name=$f&orig_template=$file.tpl", { class => 'change' })
              : $html->button($lang{CREATE}, "index=$index&create=:$file.tpl:$lang", { class => 'add' }))
              . ((-f "$conf{TPL_DIR}/$f") ? $html->button($lang{DEL}, "index=$index&del=$f", { MESSAGE => "$lang{DEL} '$f'", class => 'del' }) : '');
        }

        $table->{rowcolor} = ($file . '.tpl' eq $main_tpl_name) ? 'active' : undef;
        $table->addrow(@rows);
       }
     }
  }
  else {
    # Modules templates
    if (-d "$sys_templates/$FORM{MODULE}/templates") {
      my $tpl_describe = get_tpl_describe("describe.tpls", "$sys_templates/$FORM{MODULE}/templates/");

      opendir my $fh, "$sys_templates/$FORM{MODULE}/templates" or die "Can't open dir '$sys_templates/$FORM{MODULE}/templates' $!\n";
      my @contents = grep {!/^\.\.?$/mx && /\.tpl$/mx} readdir $fh;
      closedir $fh;

      delete $table->{rowcolor};
      delete $table->{extra};

      foreach my $file (sort @contents) {
        next if (-d "$sys_templates/$FORM{MODULE}/templates/$file");

        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks);

        if (-f "$conf{TPL_DIR}/$FORM{MODULE}_$file") {
          ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$conf{TPL_DIR}/$FORM{MODULE}" . "_$file");
          $mtime = POSIX::strftime("%Y-%m-%d", localtime($mtime));
        }
        else {
          ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$sys_templates/$FORM{MODULE}/templates/" . $file);
          $mtime = POSIX::strftime("%Y-%m-%d", localtime($mtime));
        }

        # LANG
        my @rows = (
          $file, $size, $mtime, (($tpl_describe->{$file}) ? $tpl_describe->{$file} : ''),
          $html->button($lang{SHOW}, "index=$index#", { NEW_WINDOW => "$SELF_URL?qindex=$index&SHOW=$FORM{MODULE}:$file", class => 'show' })
            # add or change
            . ((-f "$conf{TPL_DIR}/$FORM{MODULE}_$file")
            ? $html->button($lang{CHANGE}, "index=$index&tpl_name=$FORM{MODULE}_$file&orig_template=$file", { class => 'change' })
            : $html->button($lang{CREATE}, "index=$index&create=$FORM{MODULE}:$file", { class => 'add' }))
            # del
            . ((-f "$conf{TPL_DIR}/$FORM{MODULE}_$file")
            ? $html->button($lang{DEL}, "index=$index&del=$FORM{MODULE}_$file", { MESSAGE => "$lang{DEL} $file", class => 'del' })
            : '')
        );

        $file =~ s/\.tpl//x;

        foreach my $lang (@caption) {
          my $template_name = '_' . $file . '_' . $lang . '.tpl';

          my $file_exists = -f "$conf{TPL_DIR}/$FORM{MODULE}$template_name";
          my $row = q{};

          if ($file_exists) {
            $row .= $html->button($lang{SHOW}, "index=$index#", { NEW_WINDOW => "$SELF_URL?qindex=$index&SHOW=$FORM{MODULE}:$file:$lang", class => 'show' })
              . $html->button($lang{CHANGE}, "index=$index&tpl_name=$FORM{MODULE}$template_name&orig_template=$file.tpl", { class => 'change' })
              . $html->button($lang{DEL}, "index=$index&del=$FORM{MODULE}" . "$template_name", { MESSAGE => "$lang{DEL} $file", class => 'del' });
          }
          else {
            $row = $html->button($lang{CREATE}, "index=$index&create=$FORM{MODULE}:$file" . '.tpl' . ":$lang", { class => 'add' });
          }

          push @rows, $row;
        }

        $table->addrow(@rows);
      }
    }
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_templates_files() Get teblate describe

  Arguments:
    $file
    $path
  Results:
    \%tpls_describe

=cut
#**********************************************************
sub form_templates_files {

  my $table = $html->table({
    width       => '600',
    caption     => $lang{OTHER},
    title_plain => [ "FILE", "$lang{SIZE} (Byte)", $lang{DATE}, $lang{DESCRIBE}, "-" ],
    ID          => 'TEPLATES_FILES'
  });

  if (-d $conf{TPL_DIR}) {
    opendir my $fh, "$conf{TPL_DIR}" or die "Can't open dir '$conf{TPL_DIR}' $!\n";
    my @contents = grep {!/^\.\.?$/x && !/\.tpl$/x} readdir $fh;
    closedir $fh;

    my $describe = '';
    my $pdf_editor_index = get_function_index('form_templates_pdf_edit');

    foreach my $file (sort @contents) {
      next if (-d "$conf{TPL_DIR}/$file");

      my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks);

      ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$conf{TPL_DIR}/$file");
      $mtime = POSIX::strftime("%Y-%m-%d", localtime($mtime));

      my $file_actions = '';

      $file_actions .= $html->button($lang{DEL}, "index=$index&file_del=$file", {
        MESSAGE => "$lang{DEL} '$file'",
        class   => 'del'
      });

      if ($file =~ /\.pdf$/x) {
        my $file_without_extention = $file =~ s/\.pdf//xr;

        $file_actions .= $html->button(
          $lang{EDIT},
          "index=$pdf_editor_index&file=$file_without_extention",
          {
            ICON => 'fa fa-pencil-alt'
          }
        );
      }

      $table->addrow(
        $file,
        $size,
        $mtime,
        $describe,
        $file_actions
      );
    }
  }

  print $table->show();

  $html->tpl_show(templates('form_fileadd'), undef);

  return 1;
}


#**********************************************************
=head2 get_tpl_describe($file, $path) Get teblate describe

  Arguments:
    $file
    $path
  Results:
    \%tpls_describe

=cut
#**********************************************************
sub get_tpl_describe {
  my ($file, $path) = @_;
  my %tpls_describe = ();

  my $rows = file_op({ FILENAME => $file,
    PATH                        => $path,
    SKIP_CHECK                  => 1,
    ROWS                        => 1 });

  if ($rows ne q{}) {
    foreach my $line (@{$rows}) {
      if ($line =~ /^\#/x) {
        next;
      }
      my ($tpl, $lang, $describe) = split(/:/x, $line, 3);

      if ($lang eq $html->{language}) {
        $tpls_describe{$tpl} = $describe;
      }
    }
  }

  return \%tpls_describe;
}

#**********************************************************
=head2 show_tpl_info()

=cut
#**********************************************************
sub show_tpl_info {
  my ($filename, $path) = @_;

  $filename =~ s/\.tpl$//x;

  my $tpl_params = tpl_describe("$filename", $path);

  if (!%{$tpl_params}) {
    return 1;
  }

  my $table = $html->table({
    width       => '600',
    caption     => "$lang{INFO} - '$filename'",
    title_plain => [ $lang{NAME}, $lang{DESCRIBE}, $lang{PARAMS} ],
    ID          => 'TPL_INFO'
  });

  foreach my $key (sort keys %{$tpl_params}) {
    $table->addrow('%' . $key . '%', $tpl_params->{$key}->{DESCRIBE}, $tpl_params->{$key}->{PARAMS});
  }

  print $table->show();
  return 1;
}

#**********************************************************
=head2 tpl_describe($tpl_name, $path, $attr) -  Get template describe. Variables and other

  Arguments:
    $tpl_name
    $path
    $attr
  Results:
    $self

  tpl describe file format
  TPL_VARIABLE:TPL_VARIABLE_DESCRIBE:DESCRIBE_LANG:PARAMS

=cut
#**********************************************************
sub tpl_describe {
  my ($tpl_name, $path, $attr) = @_;
  my $filename = $tpl_name . '.dsc';
  my %TPL_DESCRIBE = ();

  my $rows = file_op({
    FILENAME   => $filename,
    SKIP_CHECK => 1,
    ROWS       => 1,
    PATH       => $path
  });

  return {} if (!$rows || $rows eq q{});

  foreach my $line (@$rows) {
    if ($line =~ /^\#/mx) {
      next;
    }
    elsif ($line =~ /^(\S+):(.+):(\S+):(\S{0,200})/xm) {
      my $name = $1;
      my $describe = $2;
      my $lang = $3;
      my $params = $4;
      next if ($attr->{LANG} && $attr->{LANG} ne $lang);
      $TPL_DESCRIBE{$name}{DESCRIBE} = $describe;
      $TPL_DESCRIBE{$name}{LANG} = $lang;
      $TPL_DESCRIBE{$name}{PARAMS} = $params;
    }
  }

  return \%TPL_DESCRIBE;
}

#**********************************************************
=head2 form_templates_pdf_edit() - build plugin organizer

=cut
#**********************************************************
sub form_templates_pdf_edit {
  my $file = $FORM{file};

  if (!$file) {
    $html->message('err', $lang{ERROR}, $lang{ERROR_FILE});
    return 0
  }

  my $json_docs_vars = "{}";
  if (in_array("Docs", \@MODULES)) {
    ::load_module("Docs", $html);
    my $docs_vars = eval {docs_take_variables()} || {};
    $json_docs_vars = json_former($docs_vars);
  }

  my $pdf_content = '';
  my $dsc_parsed_data = {};

  my $pdf_filename = "$conf{TPL_DIR}/" . $file . '.pdf';
  my $dsc_filename = "$conf{TPL_DIR}/" . $file . '.dsc';

  open(my $pdf_file, '<', $pdf_filename) if (-e $pdf_filename);
  open(my $dsc_file, '<', $dsc_filename) if (-e $dsc_filename);

  if ($pdf_file) {
    while (<$pdf_file>) {
      $pdf_content .= $_;
    }

    close($pdf_file);
  }
  else {
    $html->message('danger text-center', $lang{ERROR}, $lang{ERROR_FILE} . $file . '.pdf');
    return 0;
  }

  if ($dsc_file) {
    my $dsc_content = '';

    while (<$dsc_file>) {
      $dsc_content .= $_;
    }

    $dsc_parsed_data = dsc2hash($dsc_content);
    close($dsc_file);
  }
  else {
    $html->message('danger text-center', $lang{ERROR}, $lang{ERROR_FILE} . $file . '.dsc');
  }

  my $pdf_base64 = encode_base64($pdf_content);
  load_pmodule('JSON');
  my $json = JSON->new()->utf8(0);

  $html->tpl_show(templates('form_templates_pdf_edit'), {
    DOCS_VARS  => $json_docs_vars,
    FILE_NAME  => $file,
    PDF_BASE64 => $pdf_base64,
    DSC        => $json->encode($dsc_parsed_data),
    SAVE_INDEX => get_function_index('form_templates_pdf_save')
  });

  return 1;
}

#**********************************************************
=head2 form_templates_pdf_save() - build plugin organizer

=cut
#**********************************************************
sub form_templates_pdf_save {
  if (!defined($FORM{FILE_NAME})) {
    print json_former({ 'status' => 400, 'text' => 'UNDEFINED_FILE_NAME' });
    return 0;
  }

  my $dcs_file_name = $FORM{FILE_NAME} =~ s/pdf/dsc/rg;
  if (open(my $dsc_file, '+>', "$conf{TPL_DIR}/" . $dcs_file_name . '.dsc')) {
    print $dsc_file $FORM{DSC_CONTENT};
    close($dsc_file);
  }
  else {
    print "Can't open file $!";
  }

  my $tpl_file_name = $FORM{FILE_NAME} =~ s/pdf/tpl/rg;
  if (open(my $tpl_file, '+>', "$conf{TPL_DIR}/" . $tpl_file_name . '.tpl')) {
    close($tpl_file);
  }
  else {
    print "Can't open file $!";
  }

  # If this script breaks - printing html error by default, unfortunately
  # if ($@) {
  #   return 0;
  # }

  print json_former({ 'status' => 200, 'text' => 'SUCCESS' });
  return 0;
}

#**********************************************************
=head2 admin_menu($attr) - show admin menu functions list

  Arguments:
    attr      -

  Returns:

=cut
#**********************************************************
sub admin_menu {

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{FUNCTION},
    title_plain => [ 'ID', $lang{NAME}, $lang{FUNCTION} ],
    ID          => 'FUNCTIONS_LIST'
  });

  my @keys = ();
  foreach my $key (keys %functions) {
    push @keys, $key if ($key =~ /^\d+$/xm);
  }
  @keys = sort {$a <=> $b} @keys;

  foreach my $ID (@keys) {
    $table->addrow($ID, $menu_names{$ID}, $functions{$ID});
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 client_menu($attr) - show client menu functions

  Arguments:
    attr      -

  Returns:

=cut
#**********************************************************
sub client_menu {

  admin_menu();

  return 1;
}

#**********************************************************
=head2  form_dictionary() - Dictionary mangment

=cut
#**********************************************************
sub form_dictionary {
  my $sub_dict = $FORM{SUB_DICT} || '';

  if ($sub_dict =~ /\D\.\D/xm) {
    ($sub_dict, undef) = split(/\./x, $sub_dict, 2);
  }

  if ($FORM{add_form}) {
    print $html->form_main({
      CONTENT => "$lang{DICTIONARY}: " . $html->form_input('SUB_DICT', ""),
      HIDDEN  => {
        index => $index,
      },
      SUBMIT  => { add => "$lang{ADD}" },
      class   => 'form-inline'
    });
  }
  elsif ($FORM{add} && $FORM{SUB_DICT}) {
    $sub_dict = $FORM{SUB_DICT};

    file_op({
      WRITE    => 1,
      FILENAME => $sub_dict . ".pl",
      PATH     => $libpath . '/language/',
      CREATE   => 1
    })
  }
  elsif ($FORM{change}) {
    my $out = '';
    my $i = 0;
    while (my ($k, $v) = each %FORM) {
      if ($sub_dict && $k =~ /$sub_dict/xm && $k ne '__BUFFER') {
        my (undef, $key) = split(/_/x, $k, 2);
        next if (!$key || !$v);
        $key =~ s/\%40/\@/xm;
        if ($key =~ /\@/xm) {
          next if !$v; # Will break syntax if empty
          $v =~ s/\\'/'/xg;
          $v =~ s/\\"/"/xg;
          $v =~ s/\;$//xg;
          $out .= "our  $key=$v;\n";
        }
        else {
          $key =~ s/%7B/\{/xg;
          $key =~ s/%7D/\}/xg;
          $key =~ s/\%24/\$/x;
          $v =~ s/'/\'/xg;
          $out .= "$key='$v';\n";
        }
        $i++;
      }
    }

    file_op({
      WRITE    => 1,
      FILENAME => $sub_dict . ".pl",
      PATH     => $libpath . '/language/',
      CONTENT  => $out
    });
  }

  my $table = $html->table({
    width       => '600',
    title_plain => [ $lang{NAME}, "-" ],
    caption     => $lang{DICTIONARY},
    ID          => 'DICTIONARY_LIST',
    MENU        => "$lang{ADD}:index=$index&add_form=1:add",
  });

  #show dictionaries
  opendir my $fh, $libpath . "/language/" or die "Can't open dir '" . $libpath . "/language/' $!\n";
  my @contents = grep {!/^\.\.?$/mx} readdir $fh;
  closedir $fh;

  if ($#contents > 0) {
    foreach my $file (@contents) {
      $file =~ s/\.pl//x;
      my $lang_file = $libpath . "/language/" . $file . '.pl';
      if (-f $lang_file) {
        if ($sub_dict && $sub_dict . ".pl" eq $file) {
          $table->{rowcolor} = 'active';
        }
        else {
          undef($table->{rowcolor});
        }
        $table->addrow($file, $html->button($lang{CHANGE}, "index=$index&SUB_DICT=$file", { class => 'change' }));
      }
    }
  }

  print $table->show();

  #Open main dictionary
  my %main_dictionary = ();

  my $rows = file_op({
    FILENAME => 'english.pl',
    PATH     => $libpath . '/language/',
    ROWS     => 1
  });

  my $i = 0;
  foreach my $line (@$rows) {
    my ($name, $value) = split(/=/x, $line, 2);
    $name =~ s/\s//xig;
    $name =~ s/^our//x;
    if ($name =~ /^\@/xm) {
      $main_dictionary{"$name"} = $value;
    }
    elsif ($line !~ /^\#|^\n/xm) {
      $main_dictionary{"$name"} = clearquotes($value, { EXTRA => "|\'|;" });
    }
  }

  my %sub_dictionary = ();

  if ($sub_dict) {
    $rows = file_op({
      FILENAME   => $sub_dict . '.pl',
      PATH       => $libpath . '/language/',
      SKIP_CHECK => 1,
      ROWS       => 1
    });

    if ($rows) {
      foreach my $line (@{$rows}) {
        $line =~ s/\s+=\s+/=/x if ($line =~ /\s+=\s+/xmg);
        my ($name, $value) = split(/=/x, $line, 2);
        $name =~ s/\s//sig;
        $name =~ s/^our//x;
        if ($name =~ /^\@/xm) {
          $sub_dictionary{"$name"} = $value;
        }
        elsif ($line !~ /^\#|^\n/xm) {
          $sub_dictionary{"$name"} = clearquotes($value, { EXTRA => "|\'|;" });
        }
      }
    }
  }

  $table = $html->table({
    width       => '600',
    caption     => $lang{DICTIONARY},
    title_plain => [ "$lang{NAME}", "$lang{VALUE}", "-" ],
    ID          => 'FORM_DICTIONARY'
  });

  foreach my $k (sort keys %main_dictionary) {
    my $v = $main_dictionary{$k};
    my $v2 = '';

    if ($k eq '1' || $k eq '1;') {
      next;
    }

    if (defined($sub_dictionary{"$k"})) {
      $v2 = $sub_dictionary{"$k"};
      delete $table->{rowcolor};
    }
    else {
      $v2 = '';
      $table->{rowcolor} = 'danger';
    }

    $table->addrow($html->form_input('NAME',
      $k, { SIZE => 30 }),
      $html->form_input($k, $v, { SIZE => 45 }),
      ($sub_dict) ? $html->form_input($sub_dict . "_" . $k, $v2, { SIZE => 100 }) : ''
    );
    $i++;
  }

  $table->{rowcolor} = 'active';
  $table->addrow("$lang{TOTAL}", $i, '');

  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
    HIDDEN  => {
      index    => $index,
      SUB_DICT => ($sub_dict || '')
    },
    SUBMIT  => { change => $lang{CHANGE} }
  });

  return 1;
}

1;