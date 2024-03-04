package Callcenter::Menu;
use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array);
use parent 'Exporter';
use utf8;

our $VERSION = 1.00;

our @EXPORT = qw(
  menu
);
#   _get
#   _say_menu
#   _do_menu
# );

our @EXPORT_OK = qw(
  menu
);
#   _get
#   _say_menu
#   _do_menu
# );

my $debug = 0;

#**********************************************************
=head2 menu($main_menu) - Show menu

  Arguments:
    $main_menu

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub menu {
  my ($main_menu, $attr)=@_;

  `echo "-------------menu---------- $debug --------" >> /tmp/ivr`;
  my $try  = 0;
  my $code = 0;
  my $sub_menu = $main_menu;
  my $main_code = 0;

  my $_say_menu = $attr->{say_menu} || \&_say_menu;
  my $_get = $attr->{get} || \&_get;

  my %key = ();
  while ($try < 5) {
    my @keys = ();
    _log("Try: $try CODE: $code");

    if ($key{$code}) {
      $code = $key{$code};
      _log("Find: $code");
    }

    if (! $main_code) {
      $main_code = $code;
      $sub_menu = $main_menu->{$code};
    }
    else {
      if ($main_menu->{$code}) {
        $sub_menu = $main_menu->{$code};
        $main_code = $code;
      }
      else {
        $sub_menu = $main_menu->{$main_code}{$code};
      }
    }
    # if(ref $sub_menu eq 'HASH' && $sub_menu->{$code}) {
    #   $sub_menu = $main_menu->{$code};
    # }

    if(ref $sub_menu eq 'HASH') {
      %key = ();
      foreach my $item (keys %$sub_menu ) {
        my ($key, undef)=split(/:/, $sub_menu->{$item}, 2);
        $key{$key}=$item;
      }

      @keys = sort { $a <=> $b } keys %key;
    }

    if(ref $sub_menu eq 'HASH') {
      #_say_menu($sub_menu, \%key, $attr);
      $_say_menu->($sub_menu, \%key, $attr);
      $code = 0;
      #$try = 0;
    }
    else {
      _log("MAIN: $main_code CODE: $code");
      $code = 0;

      if (! $sub_menu) {
        _log("WRONG_CODE: $code");
        `echo "WRONG_CODE: $code-------- $debug --------" >> /tmp/ivr`;
        next;
      }

      $try = 0;
      _do_menu($sub_menu, $attr);
    }

    if(! $code) {
      _log("Keys:" . join(", ", @keys) ." (* - main menu)\n");
      $code = $_get->($sub_menu, $attr);

      if ($code) {
        if ($code eq '*') {
          #$sub_menu = $main_menu;
          $try = 0;
          $code = 0;
          $main_code = 0;
        }
        elsif (!in_array($code, \@keys)) {
          if ($debug > 0) {
            _log("WRONG_CODE: $code / $main_code AVAILEBLE: " . join(", ", @keys));
          }
          #$code = $main_code;
          $code = 0;
          #next;
        }
      }
    }

    _log("CODE: '$code' Try: $try\n");

    $try++;
  }

  return 1;
}

#**********************************************************
=head2 _get() - Show menu

  Arguments:

  Return:
    $code

=cut
#**********************************************************
sub _get {

  _log("\nEnter code:");

  `echo "GET -----------------------" >> /tmp/ivr`;

  my $code = <>;
  chomp($code);

  return $code;
}

#**********************************************************
=head2 _say_menu($sub_menu, $key) - Show menu

  Arguments:
    $sub_menu
    $key

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub _say_menu {
  my ($sub_menu, $key) = @_;

  my @keys = sort { $a <=> $b } keys %$key;

  foreach my $number (@keys) {
    my $item = $key->{$number};
    _log("$number) $item -> $sub_menu->{$item}");
  }

  return 1;
}

#**********************************************************
=head2 _do_menu($sub_menu) - Do menu functions

  Arguments:
    $sub_menu

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub _do_menu {
  my ($sub_menu) = @_;

  _log(" Item: $sub_menu do function");

  return 1;
}

sub test {
  my ($main_menu, $attr)=@_;
  my $_say_menu = $attr->{say_menu} || \&_say_menu;

  $_say_menu->(undef, undef, $attr);

  return 1;
}

sub _log {
  my ($text) = @_;

  if ($debug == 0) {
    #print $text."\n";
    `echo "$text" >> /tmp/ivr`;
  }

  return 1;
}

1;