=head1 NAME

  Filemanager

=cut

use strict;
use warnings FATAL => 'all';

our ($db,
  $admin,
  $html,
  %conf,
  %lang,
);

if (!$conf{TPL_DIR}) {
  $conf{TPL_DIR} = '/usr/abills/Abills/templates';
}

my $FROM_DIR = $conf{TPL_DIR} . "/attach";

#**********************************************************
=head2 file_tree() - adds content to a tree

=cut
#**********************************************************
sub file_tree {
  if ($FORM{TREE}) {
    $FORM{TREE} =~ s/\.{1,}\///xg;
    $FORM{TREE} =~ s/\;//gx;
  }

  if ($FORM{del}) {
    $FORM{del} =~ s/\.{1,}\///xg;
    $FORM{del} =~ s/\;//gx;
    my $file_name = $FROM_DIR . '/' . $FORM{del};

    if (!unlink $file_name) {
      $html->message('err', "Could not unlink $file_name: $!");
    }
  }

  my $content = ($FORM{TREE}) ? find_files($FROM_DIR . '/' . $FORM{TREE}) : find_files($FROM_DIR);

  return $content;
}

#**********************************************************
=head2 find_files($base_dir) - find files in the specified folder

  Arguments:
    $base_dir - The path to the folder

=cut
#**********************************************************
sub find_files {
  my ($base_dir) = @_;

  my $path = '';
  my $open_path = '';
  my $content = '';
  my $mtime = '';
  my @time = ();
  my $path_for_del = '';
  my $date_chg = '';
  my $type = $lang{FOLDER};

  if (!-d $base_dir) {
    $html->message('err', "Can't opendir $base_dir not exist");
    return 0;
  }

  if ($base_dir ne $FROM_DIR) {
    ($path) = $base_dir =~ m/(.*)\//x;
    if ($path eq $FROM_DIR) {
      $path = '';
    }
    else {
      $path =~ s/$FROM_DIR\///x;
    }
    $content .= $html->button(" $FORM{TREE}/.. ", "index=$index&TREE=$path",
      { class => "default col-md-6", ADD_ICON => "fa fa-folder-open" });
    $type = $lang{FILE};
  }

  my $table = $html->table({
    width         => '100%',
    caption       => $content,
    title_plain   => [ $type, $lang{CHANGED} ],
    border        => 1,
    ID            => 'ATTACHMENTS',
  });

  opendir(my $dh, $base_dir) or print $html->message('err', "Can't opendir $base_dir: $!");
  while (my $fname = readdir $dh) {

    next if (($fname eq '.') || ($fname eq '..'));

    $mtime = (stat "$base_dir/$fname")[9];
    @time = localtime($mtime);
    $date_chg = sprintf("%02d-%02d-%04d", $time[3], (1 + $time[4]), (1900 + $time[5]));

    if (-d "$base_dir/$fname") {
      $path = "$base_dir/$fname";
      $path =~ s/$FROM_DIR\///x;

      ($path_for_del) = $path =~ m/(.*)\//x;

      $table->addrow(
        $html->button("&nbsp;$fname", "index=$index&TREE=$path", { class => "row default col-md-8 text-left", ADD_ICON => "fa fa-folder" }),
        $html->element('div', $date_chg, { class => "col-md-5 text-left" })
      );
    }

    if (-f "$base_dir/$fname") {
      $path = "$base_dir/$fname";
      $path =~ s/$FROM_DIR\///x;
      $open_path = $path;
      $path =~ s/\/$fname//x;
      $path =~ s/$fname//x;
      my @count_ = $fname =~ m/_/xg;
      my $btn;
      if ($fname =~ m/\d*_\d*_.*/x) {
        my ($uid) = $path =~ m/.*\/(.*)/x;
        my ($msg_chg) = $fname =~ m/(\d*)_\d*_.*/x;
        my ($real_fname) = $fname =~ m/\d*_\d*_(.*)/x;

        $uid //= 0;

        $btn = $html->button(" $real_fname", "index=" . get_function_index('msgs_admin') . "&UID=$uid&chg=$msg_chg#last_msg",
          { class => "row default col-md-7 text-left", ADD_ICON => "fa fa-file" });
      }
      elsif (scalar @count_ < 2) {
        $btn = $html->button(" $fname", "index=$index&TREE=$path",
          { class => "row default col-md-7 text-left", ADD_ICON => "fa fa-file" });
      }
      else {
        my ($real_fname) = $fname =~ m/.*\_(.*)/x;
        $btn = $html->button(" $real_fname", "index=$index&TREE=$path",
          { class => "row default col-md-7 text-left", ADD_ICON => "fa fa-file" });
      }

      $table->addrow(
        $btn,
        $html->element('div', $date_chg, { class => "col-md-3 text-left" }),
        $html->button('', "index=$index&del=$open_path&TREE=$path", { class => "text-danger btn-sm col-md-1", ADD_ICON => "fa fa-trash" }),
      );
    }
  }
  closedir $dh;

  print $table->show();

  return;
}

1;