package Call::Haskell
  ; # to be renamed Call::Haskell; also use a custom sub import, that's the whole point.
use warnings;
use strict;
use v5.16;

#use Data::Dumper;
use Call::Haskell::FFIGenerator qw( create_hs_ffi_generator );
use Cwd;
use Config;
require Inline;

our $VERSION = '0.01';
@Call::Haskell::ISA = qw(Exporter);
my $VV = 0;

=info
I propose an interface as follows:

  use Haskell q[ ModuleName1( f1, f2, ...) ];

And then you simply use

 f1(...); 

=cut

sub import {
 my ( $hs, @import_list ) = @_;

 my %config = (
  'functions' => '',
  'path'       => '.',
  'clean'     => 0,
  'verbose'   => 0,
  'perl_types' => '', 
 );
 if ( scalar @import_list == 1 ) {
  $config{'functions'} = $import_list[0];
 }
 else {
  my %import_config = @import_list;
  map { $config{ lc($_) } = $import_config{$_} } keys(%import_config);
 }
 if (exists $config{'import'} ) {
  $config{'functions'}=$config{'import'};
 }
 my $func_import_str = $config{'functions'};

 $func_import_str =~ s/\s+//g;
 $func_import_str =~ s/\)$//;
 my @func_imports = split( /\),/, $func_import_str );
 if ( scalar @func_imports > 1 ) {
  die
"Sorry, at the moment you can only call functions from a single Haskell module\n";
 }
 my $fq_func = shift @func_imports;
 ( my $module, my $funclst ) = split( /\(/, $fq_func );
 my @mfuncs = split( /,/, $funclst );

 #    my %funcs=();
 #    for my $fq_func (@func_imports) {
 #        say "<$fq_func>";
 #        (my $module, my $funclst)=split(/\(/,$fq_func);
 #        my @mfuncs = split(/,/,$funclst);
 #        for my $func (@mfuncs) {
 #        push @{$funcs{$module}},$func;
 #        }
 #    }
 build( $module, \@mfuncs, $config{'path'}, $config{'clean'},
  $config{'verbose'} , $config{'perl_types'} );
  my $wd = cwd();
#  say "Before EXPORT code";
 for my $fn (@mfuncs) {
  if (-e "$wd/_Call_Haskell/CallHaskellWrappers/$fn.pm") {
#   push @Call::Haskell::EXPORT, "${fn}_ser";
  #Call::Haskell->export_to_level( 1, 'Call::Haskell', @Call::Haskell::EXPORT );
  require "$wd/_Call_Haskell/CallHaskellWrappers/$fn.pm";
  eval("CallHaskellWrappers::$fn->import()");
  }
  push @Call::Haskell::EXPORT, $fn;
 }
#say "After EXPORT code, now exporting to level 1";
 Call::Haskell->export_to_level( 1, 'Call::Haskell', @Call::Haskell::EXPORT );
# say "LEAVING Call::Haskell::Import";
}

sub build {
 ( my $hs_module, my $function_names, my $hs_module_dir, my $CLEAN, $VV, my $perl_types ) =
   @_;                     #'ProcessString';
 my $wd = cwd();
 if ($CLEAN) {
  system('rm -Rf _Inline');
 }
 ( my $inline_c_code, my $generated ) =
   create_hs_ffi_generator( $hs_module, $function_names, $hs_module_dir, $CLEAN,
  $VV, $perl_types );

 if ( $generated == 1 ) { $CLEAN = 1 }
 print "INLINE C CODE:\n" . $inline_c_code if $VV;

 if ( not -d './tmp' ) {
  mkdir 'tmp';
 }

 my $perl_link_options_str = $Config::Config{lddlflags};
 my $perl_ld_str           = $Config::Config{ld};
 if ( $perl_link_options_str =~ /-fstack-protector/ ) {
  $perl_link_options_str =~ s/-fstack-protector//;
 }
 print "PERL LD = $perl_ld_str\nPERL LDDLFLAGS = $perl_link_options_str\n"
   if $VV;

 # The code below could go into a module
 #say join(':',@INC),';',"\n",Dumper(%INC);#,';',
 my $Call_Haskell_path=$INC{"Call/Haskell.pm"};
 my $hs_FFIGenerator_dir=$Call_Haskell_path;
 $hs_FFIGenerator_dir=~s/Call.Haskell.pm$//;
 if ($hs_FFIGenerator_dir=~/^\./) {die "\nThe path to the Call::Haskell module _must_ be absolute, please redefine your PERL5LIB\n\n"; }
 say  "FFIGenerator path:",$hs_FFIGenerator_dir if $VV;
 my $hs_ffi_module = $hs_module . 'FFIWrapper';

# This requires test_hs_c_str.c to exist and be compiled. I should generate that!
 my $test_src           = 'test_src';
 my $test_out           = 'testl';
 my $c_wrapper          = $hs_module . 'CWrapper';
 my $hs_lib             = $hs_module . 'HsC';
 my $link_options_cache = '.lddlflags.cache';

 # Clean up
 if ($CLEAN) {
  system("rm *.o *.hi lib$hs_lib.a $test_src.c $test_out $link_options_cache");
  system("rm -Rf ./tmp/*");
 }

 #  Now, first compile the Haskell file:
 if ( not -e "$hs_ffi_module.o" ) {
  say "ghc -c -O --make -i$wd/$hs_module_dir -i$hs_FFIGenerator_dir $hs_ffi_module";
  system("ghc -c -O --make -i$wd/$hs_module_dir -i$hs_FFIGenerator_dir $hs_ffi_module");
 }
 if ( not -e "ProcessStrCWrapper.o" ) {
  say "ghc --make -i$wd/$hs_module_dir -i$hs_FFIGenerator_dir -optc-O -no-hs-main -c $c_wrapper.c $hs_ffi_module $hs_module FFIGenerator.ShowToPerl";
  system(
"ghc --make -i$wd/$hs_module_dir -i$hs_FFIGenerator_dir -optc-O -no-hs-main -c $c_wrapper.c $hs_ffi_module $hs_module FFIGenerator.ShowToPerl"
  );
 }
 if ( not -e "lib$hs_lib.a" ) {
  say
"ar rcs lib$hs_lib.a  $c_wrapper.o $hs_ffi_module.o $wd/$hs_module_dir/$hs_module.o $hs_FFIGenerator_dir/FFIGenerator/ShowToPerl.o";
  system(
"ar rcs lib$hs_lib.a  $c_wrapper.o $hs_ffi_module.o $wd/$hs_module_dir/$hs_module.o $hs_FFIGenerator_dir/FFIGenerator/ShowToPerl.o"
  );
 }
 if ( $CLEAN or not -e "$test_src.c" ) {
  my $test_src_code = "#include \"${c_wrapper}.h\"
        int main(int argc, char* argv[]) {
            hs_${hs_module}_init();
            hs_${hs_module}_end();
            return 1;
        }
    ";
  open my $TST, '>', "$test_src.c";
  print $TST $test_src_code;
  close $TST;
  system("gcc -c $test_src.c");
 }
 my $link_options = '';
 my $ld           = '';

 # if there is no cached link options file
 if ( not -e $link_options_cache ) {
  print
"ghc -v -keep-tmp-files -tmpdir=./tmp  -no-hs-main $test_src.o -L. -l$hs_lib -package parsec -o $test_out 2>&1\n"
    if $VV;
  my @ghc_link_output =
`ghc -v -keep-tmp-files -tmpdir=./tmp  -no-hs-main $test_src.o -L. -l$hs_lib -package parsec -o $test_out 2>&1`;
  my $ghc_link_options_str = $ghc_link_output[-1];
  $ghc_link_options_str =~ s/^\s*\'//;
  $ghc_link_options_str =~ s/\'\s*$//;
  print "HASKELL LD CMD: $ghc_link_options_str\n" if $VV;
  my @ghc_link_options = ();
  if ( $ghc_link_options_str =~ /\'\s+\'/ ) {

   @ghc_link_options = split( /\'\s+\'/, $ghc_link_options_str );
  }
  else {
   @ghc_link_options = split( /\s+/, $ghc_link_options_str );
  }
  $ld = shift @ghc_link_options;

  for my $opt (@ghc_link_options) {
   $opt eq '-m64'                 && do { $opt = ''; next };
   $opt eq '-fno-stack-protector' && do { $opt = ''; next };
   $opt eq '-o'                   && do { $opt = ''; next };
   $opt eq $test_out              && do { $opt = ''; next };
   $opt eq '-L.' && do { $opt = '-L../../../../_Call_Haskell'; next };
   $opt eq "$test_src.o"
     && do { $opt = '../../../../_Call_Haskell/' . $opt; next };
   $opt =~ /^tmp.ghc/
     && do { $opt = '../../../../_Call_Haskell/' . $opt; next };
  }
  $ghc_link_options_str = join( ' ', @ghc_link_options );
  $link_options = "$perl_link_options_str $ghc_link_options_str";

  # Here we should write these to a file cache
  open my $LO, '>', $link_options_cache;
  print $LO "$ld :: $link_options";
  close $LO;
 }
 else {
  say "USING CACHED LINK OPTIONS" if $VV;
  open my $LO, '<', $link_options_cache;
  my $ld_link_options = <$LO>;
  close $LO;
  ( $ld, $link_options ) = split( /\s::\s/, $ld_link_options );
 }
 print "=" x 80, "\n" if $VV;
 print "LDDLFLAGS = $link_options\n" if $VV;
 print "=" x 80, "\n" if $VV;
 chdir $wd;
 Inline->import(
  C         => Config => LD => $ld,
  LDDLFLAGS => $link_options,
  'INC'     => "-I$wd/_Call_Haskell"
 );
 Inline->import( C => $inline_c_code );
 say "CALL hs_begin" if $VV;
 hs_begin(1);
# say "LEAVING build()" if $VV;
}

END {
 say "CALL hs_end" if $VV;
 hs_end(0);
}

1;
