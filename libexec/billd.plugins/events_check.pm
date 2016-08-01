# FIXME when folder will be renamed according to perl standarts
package events_check;

use strict;
use warnings FATAL => 'all';

use vars qw(
  %conf
  $DATE
);

BEGIN{
  # Assuming we are in /usr/abills/libexec/billd.plugins/
  my $libpath = "../../";
  unshift ( @INC, $libpath );
}

use Abills::Base qw (_bp in_array days_in_month);

require "libexec/config.pl";

my $backup_dir = $conf{BACKUP_DIR} || "/usr/abills/backup/";
$backup_dir =~ s/\/\//\//g;
main();

#**********************************************************
=head2 main() - entry point

=cut
#**********************************************************
sub main{
  check_backups();

  return 1;
}


sub check_backups{
  my $backup_files = get_files_in_folder( $backup_dir, 'gz' );

  #  _bp ( "Found backups: ", $backup_files, { TO_CONSOLE => 1 } );

  # Check if yesterday backup exists
  my $yesterday_date = date_dec( 1, $DATE );

  unless ( in_array( "$backup_dir/stats-$yesterday_date.sql.gz", $backup_files ) ){
    generate_new_event( "Tips", "Yesterday backup does not exists!" );
  };

  foreach my $backup_file_name ( @{$backup_files} ){
    unless ( check_backup( $backup_file_name ) ){
      generate_new_event( 'Tips', 'Backup check fails for ' . $backup_file_name );
    };
  }

  return 1;
}

#**********************************************************
=head2 check_backup($filename) - checks backup is correct

  Arguments:
    $filename - path to backup to check

  Returns:
    boolean

=cut
#**********************************************************
sub check_backup{
  my ($filename) = @_;

  my (undef, undef, undef, undef, undef, undef, undef,, $size, undef, undef, undef, undef, undef) = stat($filename);

  return 0 if (!$size || $size == 0);

  return 1;
}

#**********************************************************
=head2 generate_new_event($name, $message)

  Arguments:
    $name - name for event
    $comments - text of message to show

  Returns:

=cut
#**********************************************************
sub generate_new_event{
  my ($name, $comments) = @_;

  #  print "EVENT: $name, $comments \n";

  my $add_result = `/usr/abills/misc/events.pl ADD=events MODULE="$name" COMMENTS="$comments" STATE_ID=1 OUTPUT=JSON`;

  if ( $add_result !~ /"status":0/m ){
    print "Error adding";
    print $add_result
  }

  return 1;
}

#**********************************************************
=head2 read_folder($folder_name [, $extension ]) - read filenames in folder

  Arguments:
    $folder_name - path to folder
    $extension - if defined,  filter by extension

  Returns:
    array_ref with filepathes

=cut
#**********************************************************
sub get_files_in_folder{
  my ($folder_name, $extension) = @_;

  my @filenames = ();
  opendir ( my $dir_inside, "$folder_name/" ) or next;

  while (my $file = readdir( $dir_inside )) {
    next if ($file =~ /^\.*$/); # filtering "current folder" and "up a folder"

    if ( defined $extension ){
      next if ( $file !~ /\.$extension$/ );
    }

    push ( @filenames, "$folder_name/$file" );

  }
  closedir( $dir_inside );

  return \@filenames;
}

#**********************************************************
=head2 date_dec($num_of_days, $date_string) - decrement date

  Arguments:
    $num_of_days - days to decrement
    $date_string - date in "YYYY-MM-DD" format

  Returns:
    string in "YYYY-MM-DD" format

=cut
#**********************************************************
sub date_dec{
  my ($num_of_days, $date_string) = @_;

  return 0 if ($num_of_days < 0);
  my ($year, $month, $day) = split( "-", $date_string );

  while($num_of_days--){
    $day--;
    if ( $day == 0 ){
      $month--;
      if ( $month == 0 ){
        $year--;
        $month = 12;
      }
      $day = days_in_month( {DATE => "$year-$month-01"} );
    }
  }
  return "$year" . "-" . leftpad( $month, 2 ) . "-" . leftpad( $day, 2 );
}

#**********************************************************
=head2 leftpad($string, $length, $attr)

  Arguments:
    $string - string to change
    $length - desired_length
    $attr   - extra args
      PLACEHOLDER - symbol for leftpad (default 0);

  Returns:
    $string leftpadded by symbols to desired length

=cut
#**********************************************************
sub leftpad{
  my ( $string, $length, $attr) = @_;

  my $placeholder = $attr->{PLACEHOLDER} || 0;
  my $len = length( $string ) - $length;

  return ($placeholder x $len) . $string;
}





1;