package Sqlcmd;
# SQL commander
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  return $self;
}




#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($type) = @_;

  my $list;
 
  if ($type eq 'showtables') {
    
    my $sth = $db->prepare( "SHOW TABLE STATUS FROM $CONF->{dbname}" );
    $sth->execute();
    my $pri_keys = $sth->{mysql_is_pri_key};
    my $names = $sth->{NAME};

    $self->{FIELD_NAMES}=$names;

    my @rows = ();
    my @row_array = ();


    while(my @row_array = $sth->fetchrow()) {
      my $i=0;

      my %Rows_hash = ();
      foreach my $line (@row_array) {
      	$Rows_hash{"$names->[$i]"}=$line;
      	$i++;
       }
      
      push @rows, \%Rows_hash;
    }
    $list = \@rows;
    return $list;
  }


  
  return $self;
}





#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO dv_main (uid, registration, tp_id, 
             logins, disable, ip, netmask, speed, filter_id, cid)
        VALUES ('$DATA{UID}', now(),
        '$DATA{TARIF_PLAN}', '$DATA{SIMULTANEONSLY}', '$DATA{DISABLE}', INET_ATON('$DATA{IP}'), 
        INET_ATON('$DATA{NETMASK}'), '$DATA{SPEED}', '$DATA{FILTER_ID}', LOWER('$DATA{CID}'));", 'do');
  
  return $self if ($self->{errno});
  
 
  $admin->action_add($DATA{UID}, "ADDED");
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = ();


	$self->changes($admin,  { CHANGE_PARAM => 'UID',
		               TABLE        => 'dv_main',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->info($attr->{UID}),
		               DATA         => $attr
		              } );

  return $self->{result};
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "DELETE from dv_main WHERE uid='$self->{UID}';", 'do');

  return $self->{result};
}




#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 my $search_fields = '';


 
 $self->query($db, "$attr->{QUERY};");

   print $self->{Q};
   my $a = $self->{Q}->{NAME};

 #print "$self->{TEST} / $a{NAME}";
 #while(my($k, $v)=each %$self->{Q}->{NAME}) {
 #  print "------$k, $v<br>"; 	
#}

 return $self if($self->{errno});
 my $list = $self->{list};

# if ($self->{TOTAL} >= $attr->{PAGE_ROWS}) {
#    $self->query($db, "$attr->{QUERY}");
#    my $a_ref = $self->{list}->[0];
#    ($self->{TOTAL}) = @$a_ref;
#   }

  return $list;
}


1