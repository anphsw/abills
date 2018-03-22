package Synchron::Odoo;

=head1 NAME

  Odoo import functions

=head1 VERSION

  VERSION: 0.01
  REVISION: 20170317


=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(load_pmodule show_hash);
use Abills::Fetcher;

our $VERSION = 0.01;

#**********************************************************
=head2 new($attr)

   Arguments:
     $attr

   Examples:

   my $Odoo = Abills::Import::Odoo->new({
     LOGIN    => $username,
     PASSWORD => $password,
     URL      => $url,
     DBNAME   => $dbname,
     debug    => $debug,
     CONF     => \%conf
   });

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $attr  = shift;

  my $self = {
    SERVICE_CONSOLE => 'Odoo',
    SEND_MESSAGE    => 1,
    SERVICE_NAME    => 'Odoo',
    VERSION         => $VERSION
  };

  bless($self, $class);

  load_pmodule('Frontier::Client');

  $self->{LOGIN}    = $attr->{LOGIN};
  $self->{PASSWORD} = $attr->{PASSWORD};
  $self->{DBNAME}   = $attr->{DBNAME};
  $self->{URL}      = $attr->{URL};
  $self->{debug}    = $attr->{DEBUG} || 0;
  $self->{CONF}     = $attr->{CONF};

  $self->auth();

  return $self;
}

#**********************************************************
=head2 version($attr) - Test service

=cut
#**********************************************************
sub version {
  my $self = shift;

  my $server = Frontier::Client->new(
    url   => $self->{URL}. '/xmlrpc/2/common',
    debug => ($self->{debug} && $self->{debug} > 3) ? 1 : 0
  );
  my $res    = $server->call('version');

  $self->{VERSION} = $res;

  return $self;
}

#**********************************************************
=head2 user_list($attr)

  Arguments:
    $attr
      FIELDS
      EMAIL
      PAGE_ROWS

  Returns:


=cut
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  my $models = Frontier::Client->new(url => $self->{URL} . "/xmlrpc/2/object");
  my $fields = $self->fields_info();

#  - checkbox "Is a Company" +
#  - listbox компаний

  my @fields_show = ();
  if($attr->{FIELDS}) {
    @fields_show = split(/,\s?/, $attr->{FIELDS});
  }
  else {
    @fields_show = keys %$fields;
  }

  my @WHERE = (
#    ['is_company', '=', 1],
#    ['customer', '=', 1]
  );

  if($self->{CONF}->{SYNCHRON_ODOO_TYPE}) {
    @WHERE = ();
    my @expr = split(/;/, $self->{CONF}->{SYNCHRON_ODOO_TYPE});
    foreach my $line (@expr) {
      push @WHERE,  [ split(/,\s?/, $line) ];
    }
  }

  if($self->{debug}) {
    print "REQUEST WHERE: $self->{CONF}->{SYNCHRON_ODOO_TYPE}";
    print join(', ', @WHERE) ."\n";
  }

  my $ids = $models->call('execute_kw', $self->{DBNAME}, $self->{UID}, $self->{PASSWORD},
    'res.partner',
    'search_read',
    [
     \@WHERE
    ],
  {
    'fields' => \@fields_show
  });

  return $self->_filter_result($ids, { FIELDS => $fields });
}

#**********************************************************
=head2 invoice_list($attr)

  Arguments:
    $attr
      FIELDS
      EMAIL
      PAGE_ROWS

  Returns:

=cut
#**********************************************************
sub invoice_list {
  my $self = shift;
  #my ($attr) = @_;

  my $models = Frontier::Client->new(url => $self->{URL} . "/xmlrpc/2/object");

  my $list = $models->call('execute_kw',
    $self->{DBNAME}, $self->{UID}, $self->{PASSWORD},
    'account.invoice',
    'search_read',
    [],
    {'limit' => 5}
    );

  $list = $self->_filter_result($list);

  return $list || [];
}


#**********************************************************
=head2 auth($attr)

  Arguments:
    $attr
      EMAIL
      PAGE_ROWS

  Returns:


=cut
#**********************************************************
sub auth {
  my $self = shift;

  my $server = Frontier::Client->new(
    url   => "$self->{URL}/xmlrpc/2/common",
    debug => ($self->{debug} && $self->{debug} > 3) ? 1 : 0
  );

  my $uid = $server->call('authenticate', $self->{DBNAME}, $self->{LOGIN}, $self->{PASSWORD}, [ ]);
  $self->{UID}=$uid;

#  my $models = Frontier::Client->new(url => "$url/xmlrpc/2/object");
#  my $access = $models->call('execute_kw', $dbname, $uid, $password,
#    'res.partner',
#    'check_access_rights',
#    ['read'],
#    { 'raise_exception' => 1 } );

  return $self;
}

#**********************************************************
=head2 fields_list($attr)

  Arguments:
    $model - (res.partner)

  Returns:


=cut
#**********************************************************
sub fields_list {
  my $self = shift;
  my ($model, $attr) = @_;

  my $models = Frontier::Client->new(url => $self->{URL} . "/xmlrpc/2/object");
  my $table = 'execute_kw';

  #$attr->{TABLE}='account.analytic.account';
  if($attr->{TABLE}) {
    $table = $attr->{TABLE};
  }

  my $list = $models->call($table, $self->{DBNAME}, $self->{UID}, $self->{PASSWORD},
    $model || q{},
    'fields_get',
    [''],
    { 'attributes' => [ 'string', 'help', 'type' ] }
  );

  return $list || [];
}


#**********************************************************
=head2 contracts_list($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub contracts_list {
  my $self = shift;
  my ($attr) = @_;

  my $models = Frontier::Client->new(url => $self->{URL} . "/xmlrpc/2/object");
  my @partner_id = ();
  if($attr->{PARTNER_ID}) {
    push @partner_id, [ ("partner_id", "=", $attr->{PARTNER_ID}) ];
  }

  my $list = $models->call('execute_kw',
    $self->{DBNAME}, $self->{UID}, $self->{PASSWORD},
    'account.analytic.account',
    'search_read',
    [ \@partner_id ],
    {
      'fields'=> ['id', 'partner_id', 'recurring_invoice_line_ids', 'ip_antenna', 'mac_antenna' ],
    }
  );

  my $list2 = $models->call('execute_kw',
    $self->{DBNAME}, $self->{UID}, $self->{PASSWORD},
    'account.analytic.invoice.line',
    'search_read',
    [], #[[[  'id', '=', $list->[0]->{recurring _invoice_line_ids} ]]],
    {
      'fields'=> ['id', 'product_id' ],
    }
  );

  my %contracts_ids = ();
  foreach my $line (@$list2) {
    $contracts_ids{$line->{id}}=join('', @{ $line->{product_id} });
  }

  for(my $i=0; $i<=$#{ $list }; $i++) {
    my $line = $list->[$i];
    my @contracts = ();
    foreach my $id ( @{ $line->{recurring_invoice_line_ids} } ) {
      push @contracts, $contracts_ids{$id};
    }

    $list->[$i]->{product_id}=\@contracts;
  }

  return $list || [];
}

#**********************************************************
=head2 fields_info()

  Arguments:
    $model - (res.partner)

  Returns:


=cut
#**********************************************************
sub fields_info {
  #my $self = shift;

  my %fields = (
    country_id    => 'COUNTRY_ID',
    name          => 'FIO',
    id            => 'LOGIN',
    #id            => 'EXT_ID',
    comment       => 'COMMENTS',
    credit        => 'CREDIT',
    phone_account => 'PHONE',
    debit         => 'DEPOSIT',
    zip           => 'ZIP',
    display_name  => 'FIO',
    create_date   => 'REGISTRATION',
    phone         => 'PHONE',
    email         => 'EMAIL',
    street        => 'ADDRESS',
    zip           => 'ZIP',
    # Info fields
    is_company	  => '_IS_COMPANY',
    website	      => '_WEBSITE', #char	Website	Website of Partner or Company
    category_id	  => '_CATEGORY_ID', #many2many	Tags
    fax           => '_FAX', #	char	Fax
    function	    => '_FUNCTION', #char	Job Position
    vat           => 'PASPORT_NUM',
    ip_pc         => 'IP',
    mac_antenna   => 'CID'

    #info fields
  );

  return \%fields;
}


#**********************************************************
=head2 fields_info()

  Arguments:
    $model - (res.partner)

  Returns:


=cut
#**********************************************************
sub reports_list {

  my @reports_list = (
    'invoice_list',
    'contracts_list'
  );

  return \@reports_list;
}


#**********************************************************
=head2 filter_result($list, $attr)

  Arguments:
    $list
    $attr
      FIELDS - Fields hash info

  Returns:


=cut
#**********************************************************
sub _filter_result {
  my $self = shift;
  my ($list, $attr) = @_;

  my $fields = $attr->{FIELDS};

  my @users_list = ();
  foreach my $line (@$list) {
    my %info_row = ();
    foreach my $key (keys %$line) {
      my $value = $line->{$key};
      my $type = ref $value;

      if ($type && $type =~ /Frontier::RPC2::Boolean/) {
        $value = '';
      }
      elsif ($type && $type eq 'ARRAY') {
        $value = join("<br>\n", @$value);
      }

      if ($fields && !$fields->{$key}) {
        print "Unsync field: $key\n" if ($self->{debug});
        next;
      }

      if($fields && $fields->{$key}) {
        if($fields->{$key} eq 'CREDIT') {
          $value = abs($value);
        }

        $info_row{$fields->{$key}} = $value; #. " (//$type)";
      }
      else {
        $info_row{$key} = $value;
      }
    }

    push @users_list, \%info_row;
  }

  return \@users_list;
}

1;