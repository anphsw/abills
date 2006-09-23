#!/usr/bin/perl -w
# File spider



use vars  qw(%RAD %conf $db $admin %AUTH $DATE $TIME $var_dir $debug);
use strict;



use FindBin '$Bin';
require $Bin . '/config.pl';
unshift(@INC, $Bin . '/../', $Bin . "/../Abills/$conf{dbtype}");
require Abills::Base;
Abills::Base->import();

require Abills::SQL;
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
$db  = $sql->{db};

require "Filearch.pm";
Filearch->import();

my $Filearch = Filearch->new($db, $admin, \%conf);
require "Abills/nas.pl";


use Socket;
use IO::Socket;
use IO::Select;


$debug=1;
require "Abills/modules/Filearch/Filesearcher.pm";
Filesearcher->import();


use Digest::MD4;
use constant BLOCKSIZE => 9728000;

$conf{FILEARCH_PATH}='/bfs/Share/Video/Movies';
$conf{FILEARCH_FORMATS}='.avi,*.mpg,*.vob';
$conf{FILEARCH_SKIPDIR}='/bfs/Share/Video/Movies/_unsorted';
my $recursive=0;
my $rec_level=0;

my %stats = (TOTAL => 0,
             ADDED => 0);

my @not_exist_files=();
my $FILEHASH;

my $params = parse_arguments(\@ARGV);



if ($#ARGV < 0) {
	print "spider.pl [options]
	checkfiles   - CHECK disk files
	getinfo      - get info from sharereaktor.ru (Only new)
	CHECK_ALL=1  - CHECK all files
	\n";
 }
elsif ($ARGV[0] eq 'checkfiles') {
  #Get records from DB
  $FILEHASH = file_hash();
  #Check files
  getfiles($conf{FILEARCH_PATH});
  print "TOTAL: $stats{TOTAL} ADDED: $stats{ADDED}\n";
}
elsif($ARGV[0] eq 'getinfo') {
	post_info();
	if ($#not_exist_files > -1) {
	 print "Not exist files:\n";
	 foreach my $line (@not_exist_files) {
		 print " $line\n";
	  }
  }
 print "TOTAL: $stats{TOTAL} ADDED: $stats{ADDED}\n";
}






#**********************************************************
#
#**********************************************************
sub getfiles {
  my $dir = shift;

  if ($dir =~ /\/bfs\/Share\/Video\/Movies\/_unsorted/) {
  	print "Skip dir '$conf{FILEARCH_SKIPDIR}'\n";
  	return 0;
   }
  opendir DIR, $dir or return;
    my @contents = map "$dir/$_",
    sort grep !/^\.\.?$/,
    readdir DIR;
  closedir DIR;



foreach my $file (@contents) {
  exit if ($recursive == $rec_level && $recursive != 0 );

  if (! -l $file && -d $file ) {
    #print "> $_ \n";
    $rec_level++;
    #print "Recurs Level: $rec_level\n";
    &getfiles($file);
    #recode($_);
   }
  elsif ($file) {
    $stats{TOTAL}++;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$file");

   	my $filename = $file;
   	$filename =~ s/$conf{FILEARCH_PATH}//;
  	$dir  = dirname($filename);
  	$filename =~ s/$dir\///;
  	$dir =~ s/^\///;
    
    if (defined($FILEHASH->{"$filename"}{"$dir"})) {
    	 print "Skip $dir / $filename\n" if ($debug > 1);
    	 next;
     }
    
    #my $date = strftime "%Y-%m-%d %H:%M:%S", localtime($mtime);
    $blocks = int($size / BLOCKSIZE);
    $blocks++ if ($size % BLOCKSIZE > 0);
    my @blocks_hashes = ();

    my $ctx = Digest::MD4->new;   
    open(FILE, "$file") || die "Can't open '$file' $!";
    binmode(FILE);
    my $data;    
    for (my $b=0; $b < $blocks; $b++) {

       my $len =  BLOCKSIZE;
       $len = $size % BLOCKSIZE if ($b == $blocks - 1); 
       
       my $ADDRESS = ($b * BLOCKSIZE);
       seek(FILE, $ADDRESS, 0) or die "seek:$!";
       read(FILE, $data, $len);
       $ctx->add($data);
       $blocks_hashes[$b]=$ctx->digest;
       print " hash block $b: ". bin2hex($blocks_hashes[$b]) ."\n" if ($debug > 1);
     }
    close(FILE);


    $ctx->add(@blocks_hashes);
    my $filehash = $ctx->hexdigest;
    #$filehash =~ tr/[a-z]/[A-Z]/;
  	
  	print "D: $dir F: $filename H: $filehash S: $size \n" if ($debug > 0);
  	


    $filename =~ s/'/\\'/g;
    $dir =~ s/'/\\'/g;
  	$Filearch->file_add({ FILENAME => "$filename",
  		                    PATH     => "$dir", 
                          NAME     => "",
                          CHECKSUM => "ed2k|$filehash",
                          SIZE     => $size,
                          AID      => 0,
                          COMMENTS => ''
                        });
  	
    if ($Filearch->{errno}) {
      print "[$Filearch->{errno}] \"$Filearch->{errstr}\"";
      exit 0;
     }

    $stats{ADDED}++;
   }

 }

  $rec_level--;
}




sub dirname {
    my($x) = @_;
    if ( $x !~ s@[/\\][^/\\]+$@@ ) {
     	$x = '.';
    }
    $x;
}

#**********************************************************
#
#**********************************************************
sub file_hash {
  my $list = $Filearch->file_list({ PAGE_ROWS => 1000000 });
	my %FILEHASH = ();
	foreach my $line (@$list) {
	   $FILEHASH{"$line->[1]"}{"$line->[2]"}=$line->[4];
	 }
	
	
	return \%FILEHASH;
}

#**********************************************************
#
#**********************************************************
sub files_list {
	
	
	return 0;
}

#**********************************************************
# POST INFO FROM SHARE REAKTOR
#**********************************************************
sub post_info {
  
  my %langs = ('Русский дублированный'            => 0,
               'Русский профессиональный перевод' => 1,
               'Русский любительский перевод'     => 2,
               'Русский'                          => 3);

  
  my $genres_list = $Filearch->genres_list();
	my %SR_GENRES_HASH = ();
	foreach my $line (@$genres_list) {
    $SR_GENRES_HASH{$line->[2]}=$line->[4];
   }

  my $list = $Filearch->video_list({ PAGE_ROWS => 1000000 });
	foreach my $line (@$list) {
     next if ($line->[14] > 0 && ! defined($params->{CHECK_ALL} ));
     
     my($type, $search_string);
     if ($line->[11] =~ /ed2k/) {
    	 ($type, $search_string)=split(/\|/, $line->[11], 2);
      } 

     #Check exist files
     if (! -f "$conf{FILEARCH_PATH}/$line->[10]/$line->[9]") {
       push @not_exist_files, "$line->[10]/$line->[9]|$line->[11]";
      } 

     print "$line->[9]\n" if ($debug > 0);

     my $search_ret = sr_search($search_string);
     if (ref $search_ret eq 'HASH') {
     	  $Filearch->file_change({ ID => $line->[0], NAME => $search_ret->{NAME} });
     	  
     	   if (defined($search_ret->{GENRE})) {
           my @genre_arr = split(/, /, $search_ret->{GENRE});
           my @genre_ids = ();
           foreach my $line (@genre_arr) {
           	 if ($SR_GENRES_HASH{$line}) {
               push @genre_ids, $SR_GENRES_HASH{$line};
              }
   	         else {
               print  "Unknovn genre '$line'\n";
               exit;
   	          }
   	        }
           $search_ret->{GENRES} = join(', ', @genre_ids);
          }
        
        #get language
        if (defined($langs{$search_ret->{LANGUAGE}})) {
          $search_ret->{LANGUAGE}=$langs{$search_ret->{LANGUAGE}};
   	     }
        
        if (defined($search_ret->{ORIGIN_NAME})) {
        	 $search_ret->{ORIGIN_NAME}=~s/'/\\'/g;
          }
  	    
   	    if (defined($search_ret->{PRODUCER})) {
   	    	$search_ret->{PRODUCER}=~s/'/\\'/g;
   	     }

   	    if (defined($search_ret->{ACTORS})) {
   	    	$search_ret->{ACTORS}=~s/'/\\'/g;
   	     }

   	    $Filearch->video_change({ ID => $line->[0], %$search_ret});
   	    $stats{ADDED}++;
      }

    $stats{TOTAL}++;
	 }

}


