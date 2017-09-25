=head2 NAME

  Iptv Reports

=cut

use strict;
use warnings FATAL => 'all';

our(
  $Iptv,
  %lang,
  $html
);

#***********************************************************
=head2 iptv_report($type, $attr)

=cut
#***********************************************************
sub iptv_report{
  my ($attr) = @_;

  my $REPORT = "Module: Iptv\n";
  %LIST_PARAMS = %{ $attr->{LIST_PARAMS} } if (defined( $attr->{LIST_PARAMS} ));

  return $REPORT;
}

#**********************************************************
=head2 iptv_use_allmonthes();

=cut
#**********************************************************
sub iptv_use_allmonthes{
  $FORM{allmonthes} = 1;
  iptv_use();
  return 1;
}

#**********************************************************
=head2 iptv_use() - Iptv Reports

=cut
#**********************************************************
sub iptv_use{

  result_former(
    {
      INPUT_DATA      => $Iptv,
      FUNCTION        => 'services_reports',
      BASE_FIELDS     => 5,
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        id        => '#',
        service_id=> '#',
        name      => $lang{NAME},
        active    => $lang{ACTIV},
        total     => $lang{SUBSCRIBES},
        users     => $lang{USERS},
      },
      TABLE => {
        width   => '100%',
        caption => $lang{SERVICES},
        qs      => $pages_qs,
        pages   => $Iptv->{TOTAL},
        ID      => 'IPTV_SERVICES_REPORT',
        EXPORT  => 1
      },
      MAKE_ROWS => 1,
      TOTAL     => "TOTAL_USERS:USERS;TOTAL_ACTIVE_USERS:ACTIV;SUBSCRIBES:SUBSCRIBES"
    }
  );

  return 1;
}


#**********************************************************
=head2 iptv_reports_channels($attr) - Reports: channels use

=cut
#**********************************************************
sub iptv_reports_channels{
  #my ($attr) = @_;

  my $list = $Iptv->reports_channels_use2({ %LIST_PARAMS, COLS_NAME => 1, PAGE_ROWS => 9999 });

  if ( !defined $list || ref $list ne 'ARRAY' ){
    $html->message( 'warn', $lang{ERROR}, $lang{ERR_NOT_EXISTS} );
    return 1;
  };

  my $total_list = ();
  foreach my $line ( @$list) {
    $total_list->{$line->{num}}->{total} //= 0;
    $total_list->{$line->{num}}->{total_debetors} //= 0;
    $total_list->{$line->{num}}->{total_disabled} //= 0;
    $total_list->{$line->{num}}->{name} = $line->{name};
    $total_list->{$line->{num}}->{total}++;
    $total_list->{$line->{num}}->{total_debetors}++ if ($line->{deposit} && $line->{deposit} < 0);
    $total_list->{$line->{num}}->{total_disabled}++ if ($line->{disable});
  }

  my $table = $html->table({
      width      => '100%',
      caption    => "$lang{CHANNELS}",
      title      => [ $lang{NUM}, $lang{NAME}, '', $lang{USERS}, '', $lang{DEBETORS}, $lang{DISABLED}],
      ID         => 'IPTV_CHANNELS',
  });

  foreach my $key (sort keys %$total_list ){
    my $button = '';
    if ($total_list->{$key}->{total} > 10) {
      $button = $html->button($total_list->{$key}->{total}, "index=$index&list=$key", { class => 'label label-primary' });
    }
    elsif ($total_list->{$key}->{total} > 0) {
      $button = $html->button($total_list->{$key}->{total}, "index=$index&list=$key", { class => 'label label-success' });
    }
    else {
      $button = $html->button($total_list->{$key}->{total}, "index=$index", { class => 'label label-default' });
    }
    my $deb_button = $html->button($total_list->{$key}->{total_debetors}, "index=$index&list=$key&deb=1", { class => 'label label-default' });
    my $dis_button = $html->button($total_list->{$key}->{total_disabled}, "index=$index&list=$key&dis=1", { class => 'label label-default' });

    $table->addrow( $html->b( $key ), $total_list->{$key}->{name}, '', $button, '', $deb_button);
  }

  print $table->show();

  if ($FORM{list}) {
    my $user_table = $html->table({
      width      => '100%',
      caption    => "$lang{USERS}",
      title      => [ '', $lang{CHANNEL}, '', $lang{USER}, $lang{DEPOSIT}],
      ID         => 'CHANNEL_USERS',
      qs         => "&list=$FORM{list}",
    });

    foreach my $line ( @$list) {
      next if ($FORM{list} != $line->{num});
      next if ($FORM{deb} && $line->{deposit} >= 0);
      next if ($FORM{dis} && !$line->{disable});
      $line->{deposit} //= 0;
      $line->{user} //= '';
      $line->{uid} //= 0;
      my $user_btn = $html->button($line->{user}, "index=" . get_function_index('iptv_user') . "&UID=$line->{uid}", {});
      $user_table->addrow('', $line->{name}, '', $user_btn, sprintf("%.2f", $line->{deposit}) );
    }
    print $user_table->show();
  }

  
  return 1;
}

1;