#!/usr/bin/perl 
#
#

#use strict;

my $tmp_path        = '/tmp/';
my $pdf_result_path = '../cgi-bin/admin/pdf/';
my $debug           = 1;
my $docs_in_file    = 4000;

use vars qw(%RAD %conf @MODULES $db $html $DATE $TIME $GZIP $TAR
$MYSQLDUMP
%ADMIN_REPORT
$DEBUG
%FORM
$users
$Docs

@ones
@twos
@fifth
@one
@onest
@ten
@tens
@hundred
@money_unit_names

$_DEBT
$_TARIF_PLAN
$_INVOICE
@WEEKDAYS

@MONTHES
);

#use strict;
use FindBin '$Bin';
use Sys::Hostname;

require $Bin . '/../libexec/config.pl';
unshift(@INC, $Bin . '/../', $Bin . '/../Abills', $Bin . "/../Abills/$conf{dbtype}");

require "Abills/defs.conf";
require "Abills/templates.pl";

require Abills::Base;
Abills::Base->import();
require Abills::Misc;

use POSIX qw(strftime mktime);

my $begin_time = check_time();

require Abills::SQL;
Abills::SQL->import();
require Users;
Users->import();
require Admins;
Admins->import();
require Docs;
Docs->import();
require Tariffs;
Tariffs->import();
require Dv;
Dv->import();

require Abills::HTML;
Abills::HTML->import();
$html = Abills::HTML->new(
  {
    CONF    => \%conf,
    csv     => 1,
    NO_PRINT=> 0
  }
);

my $sql   = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $db    = $sql->{db};
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

require Finance;
Finance->import();
my $Fees    = Finance->fees($db, $admin, \%conf);
my $Users   = Users->new($db, $admin, \%conf);
$users      = $Users;
my $Tariffs = Tariffs->new($db, $admin, \%conf);
my $Docs    = Docs->new($db, $admin, \%conf);
my $Dv      = Dv->new($db, $admin, \%conf);

require "language/$conf{default_language}.pl";
$html->{language} = $conf{default_language};

load_module('Docs');

my $ARGV = parse_arguments(\@ARGV);
if (defined($ARGV->{help})) {
  help();
  exit;
}

$debug = $ARGV->{DEBUG} || $debug;

my ($Y, $m, $d) = split(/-/, $DATE, 3);
if ($ARGV->{RESULT_DIR}) {
  $pdf_result_path = $ARGV->{RESULT_DIR};
}
else {
  $pdf_result_path = $pdf_result_path . "/$Y-$m/";
}

my $sort = 1;

if($ARGV->{SORT}) {
  if ($ARGV->{SORT} eq 'ADDRESS') {
  	$sort = "streets.name, builds.number+1, pi.address_flat+1";
  }
  else {
    $sort = $ARGV->{SORT};
  }
   
}


$docs_in_file = $ARGV->{DOCS_IN_FILE} || $docs_in_file;
my $save_filename = $pdf_result_path . '/multidoc_.pdf';

my %LIST_PARAMS = ();

if ($ARGV->{LOGIN}) {
  $LIST_PARAMS{LOGIN} = $ARGV->{LOGIN};
}
elsif ($ARGV->{UID}) {
  $LIST_PARAMS{UID}    = $ARGV->{UID};
}

if ($ARGV->{POSTPAID_INVOICES}) {
  postpaid_invoices();
}
elsif ($ARGV->{PERIODIC_INVOICE}) {
  periodic_invoice();
}
elsif ($ARGV->{PREPAID_INVOICES}) {
  prepaid_invoices()         if (!$ARGV->{COMPANY_ID});
  prepaid_invoices_company() if (!$ARGV->{LOGIN});
}
else {
  help();
}

if ($begin_time > 0) {
  Time::HiRes->import(qw(gettimeofday));
  my $end_time = gettimeofday();
  my $gen_time = $end_time - $begin_time;
  printf(" GT: %2.5f\n", $gen_time);
}

#**********************************************************
#
#**********************************************************
sub periodic_invoice {
  my ($attr) = @_;

  $Docs->{debug} = 1 if ($debug > 6);
  if ($ARGV->{DATE}) {
    $DATE = $ARGV->{DATE} ;
  }

  #Get period intervals for users with activate 0000-00-00
  if (!$FORM{INCLUDE_CUR_BILLING_PERIOD}) {
    $FORM{FROM_DATE} = "$DATE";
  }

  my ($Y, $M, $D) = split(/-/, $DATE);
  my $start_period_unixtime;
  my ($TO_Y, $TO_M, $TO_D);
  if ($M + 1 > 12) {
    $M = 1;
    $Y++;
  }
  else {
    $M++;
  }

  $D = '01';
  my $NEXT_MONTH = sprintf("%4d-%02d-%02d", $Y, $M, $D);
  
  $TO_D = ($M != 2 ? (($M % 2) ^ ($M > 7)) + 30 : (!($Y % 400) || !($Y % 4) && ($Y % 25) ? 29 : 28));

  if (($conf{SYSTEM_CURRENCY} && $conf{DOCS_CURRENCY})
    && $conf{SYSTEM_CURRENCY} ne $conf{DOCS_CURRENCY}) {
    my $Finance = Finance->new($db, $admin);
    $Finance->exchange_info(0, { ISO => $FORM{DOCS_CURRENCY} || $conf{DOCS_CURRENCY} });
    $FORM{EXCHANGE_RATE} = $Finance->{ER_RATE};
    $FORM{DOCS_CURRENCY} = $Finance->{ISO};
  }

  my $TO_DATE = $DATE;
  if ( $DATE =~ /(\d{4}\-\d{2}\-\d{2})\/(\d{4}\-\d{2}\-\d{2})/ ) {
    $TO_DATE = $1;
  }

  my $docs_users = $Docs->user_list(
    {
      %LIST_PARAMS,
      PRE_INVOICE_DATE     => $DATE,
      PERIODIC_CREATE_DOCS => 1,
      REDUCTION            => '>=0',
      PAGE_ROWS            => 1000000,
      COLS_NAME            => 1,
      LOGIN_STATUS         => 0 
    }
  );

  foreach my $docs_user (@$docs_users) {
    my %user = (
      LOGIN             => $docs_user->{login},
      FIO               => $docs_user->{fio},
      DEPOSIT           => $docs_user->{deposit},
      CREDIT            => $docs_user->{credit},
      STATUS            => $docs_user->{status},
      INVOICE_DATE      => $docs_user->{invoice_date},
      NEXT_INVOICE_DATE => $docs_user->{next_invoice_date},
      INVOICE_PERIOD    => $docs_user->{invoicing_period},
      EMAIL             => $docs_user->{email},
      SEND_DOCS         => $docs_user->{send_docs},
      UID               => $docs_user->{uid},
      ACTIVATE          => $docs_user->{activate},
      DISCOUNT          => $docs_user->{reduction} || 0,
      DOCS_CURRENCY     => $conf{DOCS_CURRENCY},
      EXCHANGE_RATE     => $FORM{EXCHANGE_RATE}
    );

    $FORM{NEXT_PERIOD} = $user{INVOICE_PERIOD};
    
    if ($debug > 0) {
      print "$user{LOGIN} [$user{UID}] DEPOSIT: $user{DEPOSIT} INVOICE_DATE: $user{INVOICE_DATE} NEXT: $user{NEXT_INVOICE_DATE} SEND_DOCS: $user{SEND_DOCS} EMAIL: $user{EMAIL}\n";
    }

    my $total_sum         = 0;
    my $total_not_invoice = 0;
    my $amount_for_pay    = 0;
    my $num               = 0;
    my %ORDERS_HASH       = ();
    my @ids               = ();

    # Get invoces
    my %current_invoice = ();
    my $invoice_list = $Docs->invoices_list(
        {
          UID         => $user{UID},
#          PAYMENT_ID  => 0,
          ORDERS_LIST => 1,
          COLS_NAME   => 1,
          PAGE_ROWS   => 1000000
        }
    );
    
    if ($Docs->{ORDERS}) {
      foreach my $doc_id (keys %{ $Docs->{ORDERS} }) {
        foreach my $invoice ( @{ $Docs->{ORDERS}->{$doc_id} }) {
          $current_invoice{ $invoice->{orders} } = $invoice->{invoice_id};
        }
      }
    }

    # No invoicing service from last invoice
    my $new_invoices = $Docs->invoice_new(
      {
        FROM_DATE => '2011-01-01',
        TO_DATE   => $TO_DATE,
        PAGE_ROWS => 1000000,
        COLS_NAME => 1,
        UID       => $user{UID}
      }
    );

    foreach my $invoice (@$new_invoices) {
      next if ($invoice->{fees_id});
      next if ($current_invoice{$invoice->{dsc}});

      
      $num++;
      push @ids, $num;
      $ORDERS_HASH{ "ORDER_" . $num }   = "$invoice->{dsc}";
      $ORDERS_HASH{ "SUM_" . $num }     = "$invoice->{sum}";
      $ORDERS_HASH{ "FEES_ID_" . $num } = "$invoice->{id}";
      $total_not_invoice += $invoice->{sum};
    }

    if ($user{ACTIVATE} ne '0000-00-00') {
      $FORM{FROM_DATE} = $user{ACTIVATE};
      ($Y, $M, $D) = split(/-/, $FORM{FROM_DATE}, 3);
      $start_period_unixtime = (mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 30 * 86400);
      $user{INVOICE_PERIOD_START} = strftime '%Y-%m-%d', localtime(mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 31 * 86400);
      $user{INVOICE_PERIOD_STOP}  = strftime '%Y-%m-%d', localtime(mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 31 * 86400);
      ($Y, $M, $D) = split(/-/, $user{INVOICE_PERIOD_START}, 3);
    }
    else {
      $user{INVOICE_PERIOD_START} = $NEXT_MONTH;
    }

    #Next period payments
    if ($FORM{NEXT_PERIOD}) {
      if (! $docs_user->{login_status}) {
        my $cross_modules_return = cross_modules_call('_docs', { %user, SKIP_MODULES => 'Docs,Multidoms,BSR1000,Snmputils,Ipn' });
        my $next_period = $FORM{NEXT_PERIOD};
        if ($user{ACTIVATE} ne '0000-00-00') {
          ($Y, $M, $D) = split(/-/, strftime "%Y-%m-%d", localtime((mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + ((($start_period_unixtime > time) ? 0 : 1) + 30 * (($start_period_unixtime > time) ? 0 : 1)) * 86400)));
          $FORM{FROM_DATE} = "$Y-$M-$D";

          ($Y, $M, $D) = split(/-/, strftime "%Y-%m-%d", localtime((mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + ((($start_period_unixtime > time) ? 1 : (1 * $next_period - 1)) + 30 * (($start_period_unixtime > time) ? 1 : $next_period)) * 86400)));
          $FORM{TO_DATE} = "$Y-$M-$D";
        }
        else {
          $FORM{FROM_DATE} = $NEXT_MONTH;
        }

        my $period_from = $FORM{FROM_DATE};
        my $period_to   = $FORM{FROM_DATE};

        foreach my $module (sort keys %$cross_modules_return) {
          if (ref $cross_modules_return->{$module} eq 'ARRAY') {
            next if ($#{ $cross_modules_return->{$module} } == -1);

            foreach my $line (@{ $cross_modules_return->{$module} }) {
              my ($name, $describe, $sum) = split(/\|/, $line);
              next if ($sum < 0);
              $period_from = $FORM{FROM_DATE};

              for (my $i = ($FORM{NEXT_PERIOD} == -1) ? -2 : 0 ; $i < int($FORM{NEXT_PERIOD}) ; $i++) {
                my $result_sum = sprintf("%.2f", $sum);
                if ($user{DISCOUNT} && $module ne 'Abon') {
                  $result_sum = sprintf("%.2f", $sum * (100 - $user{DISCOUNT}) / 100);
                }

                my ($Y, $M, $D) = split(/-/, $period_from, 3);
                if ($user{ACTIVATE} ne '0000-00-00') {
                  ($Y, $M, $D) = split(/-/, strftime "%Y-%m-%d", localtime((mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0))));    #+ (31 * $i) * 86400) ));
                  $period_from = "$Y-$M-$D";

                  ($Y, $M, $D) = split(/-/, strftime "%Y-%m-%d", localtime((mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + (30) * 86400)));
                  $period_to = "$Y-$M-$D";
                }
                else {
                  $M += 1 if ($i > 0);
                  if ($M < 13) {
                    $M = sprintf("%02d", $M);
                  }
                  else {
                    $M = sprintf("%02d", $M - 12);
                    $Y++;
                  }
                  $period_from = "$Y-$M-01";

                  #$M+=1;
                  if ($M < 13) {
                    $M = sprintf("%02d", $M);
                  }
                  else {
                    $M = sprintf("%02d", $M - 13);
                    $Y++;
                  }

                  if ($user{ACTIVATE} eq '0000-00-00') {
                    $TO_D = ($M != 2 ? (($M % 2) ^ ($M > 7)) + 30 : (!($Y % 400) || !($Y % 4) && ($Y % 25) ? 29 : 28));
                  }
                  else {
                    $TO_D = $D;
                  }

                  $period_to = "$Y-$M-$TO_D";
                }

                my $order = "$name $describe($period_from-$period_to)";
                $user{INVOICE_PERIOD_STOP} = $period_to;
                if (!$current_invoice{"$order"}) {
                  $num++;
                  push @ids, $num;
                  $ORDERS_HASH{ 'ORDER_' . $num } = $order;
                  $ORDERS_HASH{ 'SUM_' . $num }   = $result_sum;
                  $total_sum += $result_sum;
                }
                $period_from = strftime "%Y-%m-%d", localtime((mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 1 * 86400));
              }
            }
          }
        }
      }
    }

    $amount_for_pay = ($total_sum < $user{DEPOSIT}) ? 0 : $total_sum - $user{DEPOSIT};
    $total_sum += $total_not_invoice;
    $ORDERS_HASH{IDS} = join(', ', @ids);

    if ($debug > 1) {
      print "$user{LOGIN}: Invoice period: $user{INVOICE_PERIOD_START} - $user{INVOICE_PERIOD_STOP}\n";
      for (my $i = 1 ; $i <= $num ; $i++) {
        print "$i|" . $ORDERS_HASH{ 'ORDER_' . $i } . "|" . $ORDERS_HASH{ 'SUM_' . $i } . "| " . ($ORDERS_HASH{ 'FEES_ID_' . $i } || '') . "\n";
      }
      print "Total: $num  SUM: $total_sum Amount to pay: $amount_for_pay\n";
    }

    $Docs->{FROM_DATE} = $html->date_fld2('FROM_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'invoice_add', WEEK_DAYS => \@WEEKDAYS });
    $Docs->{TO_DATE}   = $html->date_fld2('TO_DATE',   { MONTHES => \@MONTHES, FORM_NAME => 'invoice_add', WEEK_DAYS => \@WEEKDAYS });
    $FORM{NEXT_PERIOD} = 0 if ($FORM{NEXT_PERIOD} < 0);

    #Add to DB
    #if ($num > 0) {
      next if ($num == 0);
      if ($debug < 5) {
        $Docs->invoice_add({ %user, 
        	                   %ORDERS_HASH,
        	                   DATE    => $ARGV->{INVOICE_DATE} || undef,
        	                   DEPOSIT => ($ARGV->{INCLUDE_DEPOSIT}) ?  $user{DEPOSIT} : 0
        	                 });

        $Docs->user_change(
          {
            UID          => $user{UID},
            INVOICE_DATE => $user{NEXT_INVOICE_DATE},
            CHANGE_DATE  => 1,
          }
        );

        #Sendemail
        if ($num > 0 && $user{SEND_DOCS}) {
        	my @invoices = split(/,/, $self->{DOC_IDS});
        	foreach my $doc_id (@invoices) {
            $FORM{print}      = $doc_id;
            $LIST_PARAMS{UID} = $user{UID};
            docs_invoice(
              {
                GET_EMAIL_INFO => 1,
                SEND_EMAIL     => $user{SEND_DOCS} || 0,
                UID            => $user{UID},
                %user
              }
            );
          }
        }
      }
    #}
  }
}



#**********************************************************
#
#**********************************************************
sub send_invoices {
  my ($attr) = @_;

  foreach my $id (@{ $attr->{INVOICES_IDS} }) {
    $FORM{pdf}   = 1;
    $FORM{print} = $id;

    docs_invoice(
      {
        GET_EMAIL_INFO => 1,
        SEND_EMAIL     => 1,
        %$attr
      }
    );
    if ($debug > 3) {
      print "ID: $id Sended\n";
    }
  }
}



#**********************************************************
# Make invoice for users
#**********************************************************
sub prepaid_invoices {

  # Modules
  #Dv
  my @MODULES = ('Dv');

  require $MODULES[0] . '.pm';
  $MODULES[0]->import();
  my $Module_name      = $MODULES[0]->new($db, $admin, \%conf);
  $LIST_PARAMS{TP_ID}  = $ARGV->{TP_ID} if ($ARGV->{TP_ID});
  $LIST_PARAMS{GID}    = $ARGV->{GID}   if ($ARGV->{GID});
  $LIST_PARAMS{DEPOSIT}= $ARGV->{DEPOSIT}    if ($ARGV->{DEPOSIT});
  my $TP_LIST          = get_tps();
  %INFO_FIELDS_SEARCH  = ();
  $Module_name->{debug}=1 if ($debug > 6);

  my $list = $Module_name->list(
    {
      DISABLE        => 0,
      COMPANY_ID     => 0,
      CONTRACT_ID    => '_SHOW',
      FIO            => '_SHOW',
      ADDRESS_STREET => '_SHOW',
      ADDRESS_BUILD  => '_SHOW',
      ADDRESS_FLAT   => '_SHOW',
      TP_NAME        => '_SHOW',
      DEPOSIT        => '_SHOW',
      CONTRACT_DATE  => '>=0000-00-00',      
      PAGE_ROWS      => 1000000,
      %INFO_FIELDS_SEARCH,
      SORT           => $sort,
      SKIP_TOTAL     => 1,
      %LIST_PARAMS,
      COLS_NAME      => 1
    }
  );

  my @MULTI_ARR = ();
  my %EXTRA     = ();
  my $doc_num   = 0;

  foreach my $line (@$list) {
    my $uid   = $line->{uid};
    my $tp_id = $line->{tp_id};

    print "UID: $uid LOGIN: $line->{login} FIO: $line->{fio} TP: $tp_id / $Module_name->{SEARCH_FIELDS_COUNT}\n" if ($debug > 2);

    $Docs->user_info($uid);

    if ($ARGV->{INVOICE2ALL} || ! $Docs->{PERIODIC_CREATE_DOCS}) {
      print "Skip create docs INVOICE2ALL: $ARGV->{INVOICE2ALL} PERIODIC_CREATE_DOCS: $Docs->{PERIODIC_CREATE_DOCS}\n" if ($debug > 2);
      next;
    }

    %FORM = (
      UID        => $uid,
      create     => 1,
      SEND_EMAIL => $ARGV->{INVOICE2ALL} || $Docs->{SEND_DOCS},
      pdf        => 1,
      CUSTOMER   => '-',
      EMAIL      => $Docs->{EMAIL}
    );

    my @orders = ();

    #Add debetor invoice
    if ($line->{deposit} && $line->{deposit} < 0) {
      print "  DEPOSIT: $line->{deposit} SEND: $FORM{SEND_EMAIL}\n" if ($debug > 2);
      push @orders, { ORDER => "$_DEBT",
                      SUM   => abs($line->{deposit}) };
    }

    #add  tp invoice
    if ($TP_LIST->{$tp_id}) {
      my ($tp_name, $fees_sum) = split(/;/, $TP_LIST->{$tp_id});
      print "  TP_ID: $tp_id FEES: $fees_sum\n" if ($debug > 2);
      push @orders, { ORDER => "$_TARIF_PLAN",
                      SUM   => $fees_sum };

    }
    
    if ($#orders > -1 ) {
    	my @ids = ();
    	for(my $i=0; $i<=$#orders; $i++) {
        if ($ARGV->{SINGLE_ORDER}) {
          $FORM{ORDER} = "$_DEBT";
          $FORM{SUM}   += $orders[$i]->{SUM};
        }
        else {
          $FORM{'ORDER_' . ($i+1)} = $orders[$i]->{ORDER};  
          $FORM{'SUM_' . ($i+1)}   = $orders[$i]->{SUM};
          push @ids, ($i+1);
        }
      }

      $FORM{'IDS'}=join(', ', @ids) if ($#ids);

      docs_invoice({ QUITE => 1,
                     SEND_EMAIL     => $FORM{SEND_EMAIL} || 0,
                     UID            => $FORM{UID},
      	             GET_EMAIL_INFO => 1 
                	 });
      
      $doc_num+=$#orders+1;
    }
  }

  print "TOTAL USERS: $Module_name->{TOTAL} DOCS: $doc_num\n";
}

#**********************************************************
#
#**********************************************************
sub get_tps {
  my ($attr) = @_;

  #Get TPS
  my %TP_LIST = ();
  my $tp_list = $Tariffs->list({%LIST_PARAMS});
  foreach my $line (@$tp_list) {
    if ($line->[6] > 0) {
      $TP_LIST{ $line->[0] } = "$line->[2];$line->[6]",;
    }
    elsif ($line->[5] > 0) {
      $TP_LIST{ $line->[0] } = "$line->[2];" . ($line->[5] * 30);
    }
  }

  return \%TP_LIST;
}

#**********************************************************
#
#**********************************************************
sub prepaid_invoices_company {

  # Modules
  #Dv
  require Customers;
  Customers->import();
  my $customer = Customers->new($db, $admin, \%conf);
  my $Company = $customer->company();

  require $MODULES[0] . '.pm';
  $MODULES[0]->import();
  $LIST_PARAMS{TP_ID}      = $ARGV->{TP_ID}      if ($ARGV->{TP_ID});
  $LIST_PARAMS{COMPANY_ID} = $ARGV->{COMPANY_ID} if ($ARGV->{COMPANY_ID});
  $LIST_PARAMS{DEPOSIT}    = $ARGV->{DEPOSIT}    if ($ARGV->{DEPOSIT});

  my $TP_LIST      = get_tps();
  my @invoices_ids = ();

  my $list = $Company->list(
    {
      DISABLE    => 0,
      PAGE_ROWS  => 1000000,
      SORT       => $sort,
      SKIP_TOTAL => 1,
      %LIST_PARAMS,
      COLS_NAME  => 1
    }
  );
  my @MULTI_ARR = ();
  my $doc_num   = 0;
  my %EXTRA     = ();

  foreach my $line (@$list) {
    my $name       = $line->{name};
    my $deposit    = $line->{deposit};
    my $company_id = $line->{id};

    print "COMPANY: $name CID: $company_id DEPOSIT: $deposit\n" if ($debug > 2);

    #get main user
    my $admin_login      = 0;
    my $admin_user       = 0;
    my $admin_user_email = '';
    my $admin_list       = $Company->admins_list({ 
    	                               COMPANY_ID => $company_id,
    	                               GET_ADMINS => 1 });

    if ($Company->{TOTAL} < 1) {
      print "Company don't have admin user\n";
      next;
    }
    else {
    	$admin_login      = $admin_list->[0]->[0];
      $admin_user       = $admin_list->[0]->[4];
      $admin_user_email = $admin_list->[0]->[3];
    }

    #Check month periodic
    $Docs->user_info($admin_user);
    if (!$Docs->{PERIODIC_CREATE_DOCS}) {
      print "Skip create docs\n" if ($debug > 2);
      next;
    }

    %FORM = (
      UID        => $admin_user,
      create     => 1,
      SEND_EMAIL => $Docs->{SEND_DOCS} || undef,
      pdf        => 1,
      CUSTOMER   => '-',
      EMAIL      => $Docs->{EMAIL}
    );

#    # make debt invoice
#    if ($deposit < 0) {
#      $FORM{SUM}   = abs($deposit);
#      $FORM{ORDER} = "$_DEBT";
#      docs_invoice({ QUITE => 1 });
#    }
#
#    #Get company users
#    my $list = $Dv->list(
#      {
#        DISABLE    => 0,
#        COMPANY_ID => $company_id,
#        PAGE_ROWS  => 1000000,
#
#        #		                        %INFO_FIELDS_SEARCH,
#        SORT       => $sort,
#        SKIP_TOTAL => 1,
#        %LIST_PARAMS,
#        COLS_NAME  => 1
#      }
#    );
#    my $tp_sum  = 0;
#    my $doc_num = 0;
#    foreach my $line (@$list) {
#      my $uid   = $line->{uid};
#      my $tp_id = $line->{tp_name} || 0;
#      my $fio   = $line->{fio} || '';
#
#      print "UID: $uid LOGIN: $line->{id} FIO: $fio TP: $tp_id\n" if ($debug > 2);
#
#      #Add debetor accouns
#      if ($TP_LIST->{$tp_id}) {
#        my ($tp_name, $fees_sum) = split(/;/, $TP_LIST->{$tp_id});
#        $tp_sum += $fees_sum;
#        print "  DEPOSIT: $line->[2]\n" if ($debug > 2);
#        $doc_num++;
#      }
#    }
#
#
#    # make tps invoice
#    if ($tp_sum > 0) {
#      print "TP SUM: $tp_sum\n";
#      $FORM{SUM}   = $tp_sum;
#      $FORM{ORDER} = "$_TARIF_PLAN";
#      docs_invoice({ QUITE => 1 });
#    }



    my $total_sum = 0;
    my @ids       = ();
    if ($debug > 6) {
      $Fees->{debug}=1;
    }
  
    my $date = ($ARGV->{DATE}) ? "$ARGV->{DATE}"  : ">=$DATE" ;
  
    my $fees_list = $Fees->list({ DATE       => $date,
  	                              COMPANY_ID => $company_id,
  	                              COLS_NAME  => 1 
  	                            });

    foreach my $line (@$fees_list) {
      $num++;
      push @ids, $num;
      $ORDERS_HASH{ 'ORDER_' . $num }   = $line->{dsc};
      $ORDERS_HASH{ 'SUM_' . $num }     = $line->{sum};
      $ORDERS_HASH{ "FEES_ID_" . $num } = $line->{id};
      $total_sum                       += $line->{sum};
    }

    $ORDERS_HASH{IDS} = join(', ', @ids);

    if ($debug > 1) {
      print "$user{LOGIN}: Invoice period: $user{INVOICE_PERIOD_START} - $user{INVOICE_PERIOD_STOP}\n";
      for (my $i = 1 ; $i <= $num ; $i++) {
        print "$i|" . $ORDERS_HASH{ 'ORDER_' . $i } . "|" . $ORDERS_HASH{ 'SUM_' . $i } . "| " . ($ORDERS_HASH{ 'FEES_ID_' . $i } || '') . "\n";
      }
      print "Total: $num  SUM: $total_sum Amount to pay: $amount_for_pay\n";
    }

    #Add to DB
    next if ($num == 0);
    if ($debug < 5) {
      $Docs->invoice_add({ %FORM, %ORDERS_HASH });

      $LIST_PARAMS{UID} = $user{UID};
      $FORM{create}     = undef;
       
      my @doc_ids=split(/,/, $Docs->{DOC_IDS}); 
      #Sendemail
      foreach $doc_id (@doc_ids) {
        $FORM{print}      = $doc_id;
        docs_invoice(
            {
              GET_EMAIL_INFO => 1,
              SEND_EMAIL     => $Docs->{SEND_DOCS} || 0,
              UID            => $user{UID},
              COMPANY_ID     => $company_id,
              DEBUG          => $debug,
              %user
            }
          );
        $doc_num++;
      }
    }
  }

  print "TOTAL USERS: $Company->{TOTAL} DOCS: $doc_num\n";
}

#**********************************************************
#
#**********************************************************
sub postpaid_invoices {
  $save_filename = $pdf_result_path . '/multidoc_postpaid_invoices.pdf';
  $Fees->{debug} = 1 if ($debug > 6);

  if (!-d $pdf_result_path) {
    print "Directory no exists '$pdf_result_path'\n" if ($debug > 0);
    if(! mkdir($pdf_result_path)) {
  	  print "Error: $!\n";
  	  exit;
    }
    else {
      " Created.\n" if ($debug > 0);
    }
  }

  $LIST_PARAMS{DEPOSIT}= $ARGV->{DEPOSIT}    if ($ARGV->{DEPOSIT});

  #Fees get month fees - abon. payments
  my $fees_list = $Fees->reports(
    {
      INTERVAL => "$Y-$m-01/$DATE",
      METHODS  => 1,
      TYPE     => 'USERS',
      COLS_NAME=> 1
    }
  );

  # UID / SUM
  my %FEES_LIST_HASH = ();
  foreach my $line (@$fees_list) {
    $FEES_LIST_HASH{ $line->{uid} } = $line->{sum};
  }

  #Users info
  my %INFO_FIELDS = (
    '_c_address' => 'ADDRESS_STREET',
    '_c_build'   => 'ADDRESS_BUILD',
    '_c_flat'    => 'ADDRESS_FLAT'
  );

  my %INFO_FIELDS_SEARCH = ();

  foreach my $key (keys %INFO_FIELDS) {
    $INFO_FIELDS_SEARCH{$key} = '_SHOW';
  }

  $Users->{debug} = 1 if ($debug > 6);
  my $list = $Users->list(
    {
      FIO            => '_SHOW',
      LOGIN_STATUS   => '_SHOW',
      DEPOSIT        => '_SHOW',
      DISABLE        => 0,
      CONTRACT_ID    => '_SHOW',
      CONTRACT_DATE  => '_SHOW',
      ADDRESS_STREET => '_SHOW',
      ADDRESS_BUILD  => '_SHOW',
      ADDRESS_FLAT   => '_SHOW',
      #ADDRESS_FULL   => '_SHOW',
      PAGE_ROWS      => 1000000,
      %INFO_FIELDS_SEARCH,
      %LIST_PARAMS,
      SORT           => $sort,
      COLS_NAME      => 1
    }
  );

  if ($Users->{EXTRA_FIELDS}) {
    foreach my $line (@{ $Users->{EXTRA_FIELDS} }) {
      if ($line->[0] =~ /ifu(\S+)/) {
        my $field_id = $1;
        my ($position, $type, $name) = split(/:/, $line->[1]);
      }
    }
  }

  my @MULTI_ARR = ();
  my $doc_num   = 0;

  my $ext_bill = ($conf{EXT_BILL_ACCOUNT}) ? 1 : 0;
  my %EXTRA = ();
  foreach my $line (@$list) {

    my $full_address = '';

    if ($ARGV->{ADDRESS2}) {
      $full_address = $line->{address_stret2} || '';
      $full_address .= ' ' . $line->{address_build2} || '';
      $full_address .= '/' . $line->{asddress_flat2} || '';
    }
    else {
      $full_address = $line->{address_stret} || '';
      $full_address .= ' ' . $line->{address_build} || '';
      $full_address .= '/' . $line->{asddress_flat} || '';
    }

    my $month_fee = ($FEES_LIST_HASH{ $line->{uid} }) ? $FEES_LIST_HASH{ $line->{uid} } : '0.00';

    push @MULTI_ARR, {
      LOGIN               => $line->{login},
      FIO                 => $line->{fio},
      DEPOSIT             => sprintf("%.2f", $line->{deposit} + $month_fee),
      CREDIT              => $line->{credit},
      SUM                 => sprintf("%.2f", abs($line->{deposit})),
      DISABLE             => 0,
      ORDER_TOTAL_SUM_VAT => ($conf{DOCS_VAT_INCLUDE}) ? sprintf("%.2f", abs($line->{deposit} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}))) : 0.00,
      NUMBER              => $line->{bill_id} . "-$m",
      ACTIVATE            => '>=$DATE',
      EXPIRE_DATE         => ($conf{DOCS_ACCOUNT_EXPIRE_PERIOD})  ? strftime '%Y-%m-%d', localtime(mktime(0, 0, 0, $d, ($m - 1), ($Y - 1900), 0, 0, 0) + $conf{DOCS_ACCOUNT_EXPIRE_PERIOD} * 86400) : '0000-00-00',
      MONTH_FEE           => $month_fee,
      TOTAL_SUM           => sprintf("%.2f", abs($line->{deposit})),
      CONTRACT_ID         => $line->{contract_id},
      CONTRACT_DATE       => $line->{contract_date},
      DATE                => $DATE,
      FULL_ADDRESS        => $full_address,
      ADDRESS_STREET      => $line->{address_street},
      ADDRESS_BUILD       => $line->{address_build},
      ADDRESS_FLAT        => $line->{address_flat},
      SUM_LIT             => int2ml(
        sprintf("%.2f", abs($line->{deposit})),
        {
          ONES             => \@ones,
          TWOS             => \@twos,
          FIFTH            => \@fifth,
          ONE              => \@one,
          ONEST            => \@onest,
          TEN              => \@ten,
          TENS             => \@tens,
          HUNDRED          => \@hundred,
          MONEY_UNIT_NAMES => $conf{MONEY_UNIT_NAMES} || \@money_unit_names
        }
      ),

      DOC_NUMBER => sprintf("%.6d", $doc_num),
    };

    print "UID: $line->{uid} LOGIN: $line->{login} FIO: $line->{fio} SUM: $line->{deposit}\n" if ($debug > 2);

    $doc_num++;
  }

  print "TOTAL: " . $Users->{TOTAL};

  if ($debug < 5) {
  	$FORM{pdf}=1;
    multi_tpls(_include('docs_multi_invoice', 'Docs'), \@MULTI_ARR);
  }

}

#**********************************************************
#
#**********************************************************
sub multi_tpls {
  my ($tpl, $MULTI_ARR, $attr) = @_;

  PDF::API2->import();
  require Abills::PDF;
  my $pdf = Abills::PDF->new(
      {
        IMG_PATH => $IMG_PATH,
        NO_PRINT => defined($attr->{'NO_PRINT'}) ? $attr->{'NO_PRINT'} : 1,
        CONF     => \%conf,
        CHARSET  => $conf{default_charset}
      }
    );
  $html = $pdf;
  
  my $single_tpl = $html->tpl_show(
    $tpl, undef,
    {
      MULTI_DOCS   => $MULTI_ARR,
      MULTI_DOCS_PAGE_RECS => $ARGV->{PAGE_DOCS} || undef,
      SAVE_AS      => $save_filename,
      DOCS_IN_FILE => $docs_in_file,
      debug        => $debug
    }
  );
}

#**********************************************************
# get_fees_types
#
# return $Array_ref
#**********************************************************
sub get_fees_types {
  my ($attr) = @_;

  my %FEES_METHODS = ();
  my $list         = $Fees->fees_type_list({ PAGE_ROWS => 10000 });
  foreach my $line (@$list) {
    if ($FORM{METHOD} && $FORM{METHOD} == $line->[0]) {
      $FORM{SUM}      = $line->[3] if ($line->[3] > 0);
      $FORM{DESCRIBE} = $line->[2] if ($line->[2]);
    }

    $FEES_METHODS{ $line->[0] } = (($line->[1] =~ /\$/) ? eval($line->[1]) : $line->[1]) . (($line->[3] > 0) ? (($attr->{SHORT}) ? ":$line->[3]" : " ($_SERVICE $_PRICE: $line->[3])") : '');
  }

  return \%FEES_METHODS;
}

#**********************************************************
#
#**********************************************************
sub help {

  print << "[END]";
Multi documents creator	
  PERIODIC_INVOICE - Create periodic invoice for clients
     INCLUDE_DEPOSIT - Include deposit to invoice
     INVOICE_DATE    - Invoice create date XXXX-XX-XX (Default: curdate)
  POSTPAID_INVOICES- Created for previe month debetors
  PREPAID_INVOICES - Create credit invoice and next month payments invoice
     INVOICE2ALL=1 - Create and send invoice to all users
     SINGLE_ORDER  - All order by 1 position  
     
Extra filter parameters
  LOGIN            - User login
  TP_ID            - Tariff Plan
  UID              - UID
  GID              - User Gid
  DEPOSIT          - filter user deposit
  COMPANY_ID       - Company id. if defined company id generated only companies invoicess. U can use wilde card *
  
  RESULT_DIR=      - Output dir (default: abills/cgi-bin/admin/pdf)
  DOCS_IN_FILE=    - docs in single file (default: $docs_in_file)
  ADDRESS2         - User second address (fields: _c_address, _c_build, _c_flat)
  DATE=YYYY-MM-DD  - Document create date of period "YYYY-MM-DD/YYYY-MM-DD"
  SORT=            - Sort by column number. Special symbol ADDRESS sort by address
  DEBUG=[1..5]     - Debug mode
[END]
}



1
