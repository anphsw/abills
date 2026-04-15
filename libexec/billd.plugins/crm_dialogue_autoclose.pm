=head1 NAME

  billd - Plugin for automatic closure of CRM dialogues

=head1 DESCRIPTION

  This plugin automatically closes CRM dialogues that have exceeded
  their autoclose timeout period based on open line configuration.

=cut

use strict;
use warnings;

our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db
);

use Abills::Base qw(date_diff);
use Crm::db::Crm;

my $Crm = Crm->new($db, $Admin, \%conf);

crm_dialogue_autoclose();

#**********************************************************
=head2 crm_dialogue_autoclose($argv) - Automatically close inactive CRM dialogues

  Arguments:
    $argv   - Extra attributes
       DATE   - Date used as the current date for inactivity calculation

  Returns:
   TRUE

  Example:

    crm_dialogue_autoclose();

=cut
#**********************************************************
sub crm_dialogue_autoclose {

  my $current_date = $argv->{DATE} || $DATE;

  _log('LOG_INFO', "Starting CRM dialogue autoclose process for date: $current_date");

  my $open_lines = $Crm->crm_open_lines_list({
    AUTOCLOSE => '!',
    SOURCE    => '_SHOW',
    COLS_NAME => 1
  });

  if (!$Crm->{TOTAL} || $Crm->{TOTAL} < 1) {
    _log('LOG_INFO', "No open lines with autoclose configuration found. Exiting.");
    return 1;
  }

  _log('LOG_INFO', "Found " . $Crm->{TOTAL} . " open line(s) with autoclose enabled");

  my $open_lines_autoclose_hash = {};
  foreach my $line (@$open_lines) {
    if (!$line->{autoclose}) {
      return 1;
    }

    $open_lines_autoclose_hash->{$line->{id}} = $line->{autoclose};
  }

  my $total_processed = 0;
  my $total_closed = 0;
  my $total_errors = 0;

  foreach my $open_line (@$open_lines) {
    _log('LOG_DEBUG', "Processing open line ID: $open_line->{id}, source: $open_line->{source}, autoclose: $open_line->{autoclose} days");

    my $dialogues = $Crm->crm_dialogues_list({
      SOURCE            => $open_line->{source},
      STATE             => '0',
      LAST_MESSAGE_DATE => '_SHOW',
      COLS_NAME         => 1
    });

    if (!$dialogues || scalar(@$dialogues) == 0) {
      _log('LOG_DEBUG', "No active dialogues found for source: $open_line->{source}");
      next;
    }

    _log('LOG_INFO', "Found " . scalar(@$dialogues) . " active dialogue(s) for source: $open_line->{source}");

    foreach my $dialogue (@$dialogues) {
      $total_processed++;

      my $days_since_last_message = date_diff($dialogue->{last_message_date}, $current_date);
      my $autoclose_threshold = $open_lines_autoclose_hash->{$open_line->{id}};

      _log('LOG_DEBUG', "Dialogue ID: $dialogue->{id}, last message: $dialogue->{last_message_date}, days since: $days_since_last_message, threshold: $autoclose_threshold");

      if ($days_since_last_message < $autoclose_threshold) {
        _log('LOG_DEBUG', "Dialogue ID: $dialogue->{id} not eligible for autoclose yet ($days_since_last_message < $autoclose_threshold days)");
        next;
      }

      _log('LOG_INFO', "Closing dialogue ID: $dialogue->{id} (inactive for $days_since_last_message days)");

      $Crm->crm_dialogues_change({
        ID    => $dialogue->{id},
        STATE => 2
      });

      if ($Crm->{errno}) {
        $total_errors++;
        _log('LOG_ERR', "Failed to close dialogue ID: $dialogue->{id}, error: $Crm->{errno}");
      }
      else {
        $total_closed++;
        _log('LOG_INFO', "Successfully closed dialogue ID: $dialogue->{id}");
      }
    }
  }

  _log('LOG_INFO', "Autoclose process completed:");
  _log('LOG_INFO', "  - Total dialogues processed: $total_processed");
  _log('LOG_INFO', "  - Successfully closed: $total_closed");
  _log('LOG_INFO', "  - Errors encountered: $total_errors");

  return 1;
}

1;