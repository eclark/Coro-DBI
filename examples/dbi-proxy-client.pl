use strict;
use warnings;

use File::Basename;
use Coro::DBI;

my $db = File::Basename::dirname(__FILE__) . "/test.s";
my $dbh = DBI->connect( "dbi:SQLite:$db", "", "", { RaiseError => 1 } );

my $sth = $dbh->prepare("SELECT * FROM foo");

$sth->execute;

while ( my @row = $sth->fetchrow_array ) {
    print join( "; ", @row ) . "\n";
}
$sth->finish;

$dbh->disconnect;

