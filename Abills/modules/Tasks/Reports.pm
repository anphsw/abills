=head2 NAME

  Tasks Reports

=cut

use strict;
use warnings FATAL => 'all';

our(
  %lang,
  %conf,
  $admin,
  $db,
  $html,
  @MONTHES,
  $libpath
);

use Tasks::db::Tasks;
my $Tasks = Tasks->new($db, $admin, \%conf);

require Abills::Template;
my $Templates = Abills::Template->new($db, $admin, \%conf, { html => $html, lang => \%lang, libpath => $libpath });

#**********************************************************
=head2 tasks_start_page($attr)

=cut
#**********************************************************
sub tasks_start_page {

  my %START_PAGE_F = (
    tasks_current_tasks_report => $lang{CURRENT_TASKS}
  );

  return \%START_PAGE_F;
}

#**********************************************************
=head2 tasks_current_tasks_report($attr)

=cut
#**********************************************************
sub tasks_current_tasks_report {
  return $html->tpl_show($Templates->_include('tasks_current_tasks_report', 'Tasks'), {}, { OUTPUT2RETURN => 1 });
}

1;