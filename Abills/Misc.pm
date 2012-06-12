# Misc functions


#**********************************************************
# load_module($string, \%HASH_REF);
#**********************************************************
sub load_module {
	my ($module, $attr) = @_;

	my $lang_file = '';
  foreach my $prefix (@INC) {
    my $realfilename = "$prefix/Abills/modules/$module/lng_$attr->{language}.pl";
    if (-f $realfilename) {
      $lang_file =  $realfilename;
      last;
     }
    elsif (-f "$prefix/Abills/modules/$module/lng_english.pl") {
    	$lang_file = "$prefix/Abills/modules/$module/lng_english.pl";
     }
   }

  if ($lang_file ne '') {
    require $lang_file;
   }

 	require "Abills/modules/$module/webinterface";

	return 0;
}


#**********************************************************
# Calls function for all registration modules if function exist 
#
# HASH_REF = cross_modules_call(function_sufix, attr) 
#
# return HASH_REF
#   MODULE -> return
#**********************************************************
sub cross_modules_call {
  my ($function_sufix, $attr) = @_;

  my %full_return = ();
  my @skip_modules = ();
  
  if ($attr->{SKIP_MODULES}) {
  	$attr->{SKIP_MODULES}=~s/\s+//g;
  	@skip_modules=split(/,/, $attr->{SKIP_MODULES});
   }

  foreach my $mod (@MODULES) {
  	if (in_array($mod, \@skip_modules)) {
  		next;
  	 }
    
    if ($attr->{DEBUG}) {
    	print " $mod\n";
     }

    load_module("$mod", $html);
    my $function = lc($mod).$function_sufix;
    
    my $return;
    
    if (defined(&$function)) {
     	$return = $function->($attr);
     }
    $full_return{$mod}=$return;
   }

  return \%full_return;
}


#**********************************************************
# Get function index
#
# get_function_index($function_name, $attr)
#**********************************************************
sub get_function_index {
  my ($function_name, $attr) = @_;
  my $function_index = 0;

  foreach my $k (keys %functions) {
    my $v = $functions{$k};
    if ($v eq "$function_name") {
      $function_index = $k;
      if ($attr->{ARGS} && $attr->{ARGS} ne $menu_args{$k}) {
        next;
      }
      last;
    }
  }

  return $function_index;
}

1