#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XML::ZCOL' ) || print "Bail out!
";
}

diag( "Testing XML::ZCOL $XML::ZCOL::VERSION, Perl $], $^X" );
