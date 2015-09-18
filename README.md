# NAME

Call::Haskell - Call Haskell functions from Perl

# SYNOPSIS

    use Call::Haskell 'My::Haskell::Module( f1, f2, f3, f4 )'

or more explicitly:

    use Call::Haskell import => 'My::Haskell::Module( f1, f2, f3, f4 )' , path => '..', clean => 0, verbose => 0 ;

    my $res = f1(@args);

# DESCRIPTION

`Call::Haskell` provides a simple mechanism to call Haskell functions from Perl. The syntax for the import statement is similar to what you would write in Haskell. If the path is not specified, the local directory is assumed.

To use this module you need

    - perl 5.16 or later,
    - ghc 7.8 or more recent,
    - gcc 4.8 or more recent

You also need recent versions of

    - the Inline, Inline::C and Digest::MD5 Perl packages
    - the Parsec Haskell package

The Haskell function arguments and return values must have types that are lists, tuples or maps of primitive types (`Int`, `Bool`, `String`). Haskell's `Data.Map` becomes a Perl hash and vice versa. `Maybe` is also supported, `Nothing` is mapped to `undef` and vice versa.

If this is too restrictive, you can use the `Functional::Types` module which provides a Haskell-like type system for Perl. In this case, your corresponding Haskell types must be instances of the `Typeable` typeclass.

The module packs the arguments into a string and unpacks the return value from a string. This will be very slow for large data structures.

Currently, you can only use functions from a single Haskell module.

The module creates two subdirectories in your working directory: `_Call_Haskell` and `_Inline`. You can find all generated code in there.

# TESTING

The Haskell build process does currently not work with automated testing so the test in `t/basic.t` is a stub. You can test manually by commenting out the current plan, and uncommenting the lines below it:

    #plan skip_all => "Skipping all test, please uncomment the 'use Call:Haskell' and the test plan and run manually";
    plan tests => 4;
    use Call::Haskell import => 'ProcessStr( f1, f2, f3, f4 )', path => '.';

Then you can test it as follows:

    $ cd t
    $ perl -I../lib basic.t

# AUTHOR

Wim Vanderbauwhede <Wim.Vanderbauwhede@mail.be>

# COPYRIGHT

Copyright 2015- Wim Vanderbauwhede

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

- Inline, Inline::C and Digest::MD5 Perl packages
- The Parsec Haskell package <http://hackage.haskell.org/package/parsec>
- A presentation about `Call::Haskell` and `Functional::Types`: <http://www.slideshare.net/WimVanderbauwhede/perl-andhaskell>
