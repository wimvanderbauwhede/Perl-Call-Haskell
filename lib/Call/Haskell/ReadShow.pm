package Call::Haskell::ReadShow;
use warnings;
use strict;
use v5.16;
# Uses ShowToPerl to serialise the output of the Haskell function

#use Data::Dumper;
=test

my $vts = "((42,\"42\",True,MkTup 42 False (\"42\",3)),MkVarDecl {vd_vartype = MkVarType {at_numtype = F95Real, at_wordsz = (4,\"42\",5)}, vd_dimension = [MkRange {r_start = Const 1 \"1\", r_stop = Var \"ip\"},MkRange {r_start = Const 1, r_stop = Var \"jp\"},MkRange {r_start = Const 1 , r_stop = Var \"kp\"}], vd_intent = InOut, vd_varlist = [\"u\"], vd_argmode = ReadWrite, vd_is_arg = True, vd_has_const_ranges = False, vd_shape=[]})";
say $vts;

my $ref=readH($vts);

say Dumper($ref);

my $hs_type = 'Map [Char] ([Int],[Char])';
my $data = {
    'k1' => [ [1,2,3],'v1' ],
    'k3' => [ [4,5,6],'v2' ],
    'k4' => [ [7,8,9],'v3' ],
    'k5' => [ [11,12,13],'v4' ]
};

say showH($data, $hs_type);
=cut

# This routine needs the type signature from the Haskell function, and in principle it also needs the definitions of the constructors, like we can get from Data.Data
# So I now need to return from Haskell not only the signature but also every constructor for the complete composite type. Seems really difficult.
# Alternatively I can do a cheap serialise here and parse and transform the string in Haskell, say I write PerlToRead.hs.  
# So I would e.g. only know that a function takes a VarDecl and and Int and returns a String 

sub showH { (my $data, my $hs_type)=@_;
    my $t= substr( $hs_type,0,1);
    if($t eq '[') { # List or String
        if ($hs_type eq '[Char]') { # String
            return show_string($data); 
        } else {
            my $list_t= substr( $hs_type,1,-1);
            return show_list($data, $list_t);
        }
    } elsif ($t eq '(') { # Tuple
            my $tuple_t= substr( $hs_type,1,-1);
            return show_tuple($data, $tuple_t);
    } elsif ($t =~/[A-Z]/) { # Either prim, Map or Maybe
        if (substr($hs_type,0,3) eq 'Map') { # Map
#            say 'Map';
            (my $map, my $key_t, my $val_t)=split(/\s+/,$hs_type);
#            say "$key_t,$val_t";
            return show_hash($data,$key_t,$val_t);
        } elsif (substr($hs_type,0,5) eq 'Maybe') { # Maybe
            (my $mb, my $val_t)=split(/\s+/,$hs_type);
            return show_maybe($data, $val_t);
        } elsif($hs_type =~/^([A-Z]\w*)$/) { # Prim, which means Int, Integer, Float, Double, Integral, Fractional etc or Bool. 
            my $prim_t=$1;
            return show_prim($data,$prim_t);
        } else {
            die "Something wrong (2) with the type $hs_type!\n" 
        }
    } else {die "Something wrong (1) with the type $hs_type!\n" }
}

sub show_string { '\"'.$_[0].'\"' };

sub show_prim {
        (my $data, my $hs_type)=@_;
        if ($hs_type eq 'Bool') {
            return ($data ? 'True' : 'False')
        } else {
            return $data;
        }
}

sub show_maybe {
    (my $data, my $hs_type)=@_;
    if (defined $data) {
        return 'Just '.showH($data,$hs_type);
    } else {
        return 'Nothing';
    }
}

sub show_list {
    (my $data, my $hs_type)=@_;
    return '['.join(',', map { showH($_,$hs_type) } @{$data}).']';
}

sub show_tuple {
    (my $data, my $hs_type)=@_;
    my @hs_types=split(/,/,$hs_type);
    if (scalar @{$data} != scalar @hs_types) {die "Tuple type and values do not match!\n" };    
    return '('.join(',', map { showH($_,shift(@hs_types)) } @{$data}).')';
}

sub show_hash {
    (my $data,my $key_t,my $val_t)=@_;
    my @kv_list=();
    while ((my $k, my $v) = each(%{$data})) {
        push @kv_list,'('.showH($k,$key_t).','.showH($v,$val_t).')';
    }
    return 'fromList ['.join(',',@kv_list).']';
}


# Simply eval the string from ShowToPerl, using AUTOLOAD to clean up.
sub readH {
    (my $vts)=@_;
    my $ref=eval( $vts );
    return $ref;
}


sub AUTOLOAD {
    our $AUTOLOAD;
    if (not @_) {
        my $t=$AUTOLOAD;
        $t=~s/^.+:://;
        $t eq 'True' && do{$t=1};
        $t eq 'False' && do{$t=1};
        $t eq 'Nothing' && do{$t=undef};
        return $t;
    } else {
        if (scalar @_ == 1) {
            return $_[0];
        } else {
            return [@_];
        }
    }
}

1;
