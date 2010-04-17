#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Coro::DBI' );
}

diag( "Testing Coro::DBI $Coro::DBI::VERSION, Perl $], $^X" );
