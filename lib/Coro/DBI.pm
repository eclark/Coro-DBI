package Coro::DBI;

use warnings;
use strict;

our $VERSION = '0.00_01';

use AnyEvent::Util qw(run_cmd);
use Coro::Timer;
use DBI;
use Linux::Pdeathsig;
use Config;

our $childpid;
our $child_cv;
our $localport;

sub start {
    $localport = @_ == 2 ? pop : 5001;

    $child_cv = run_cmd [
        'dbiproxy', '--localport', $localport, '--mode',
        'single',   '--logfile',   'STDERR'
      ],
      '2>'         => '/dev/null',
      '>'          => '/dev/null',
      '<'          => '/dev/null',
      '$$'         => \$childpid,
      'on_prepare' => sub {
        set_pdeathsig(2);
      };

    Coro::Timer::sleep 1;
}

sub stop {
    unless ( $child_cv->ready ) {
        kill 2, $childpid;
    }
    $child_cv->recv;
}

sub proxy_dsn {
    return "DBI:Proxy:hostname=localhost;port=$localport;stderr=1";
}

$DBI::connect_via = 'Coro::DBI::connect';
sub connect {
    Coro::DBI->start unless (defined $Coro::DBI::child_cv);

    local $ENV{'DBI_AUTOPROXY'} = __PACKAGE__->proxy_dsn;
    shift->connect(@_);
}

## hook into DBD::Proxy internals to make it non-blocking
use DBD::Proxy;
{

    package DBD::Proxy::RPC::PlClient;

    use Coro::Handle;
    use AnyEvent::Socket;

    sub new {
        my $proto = shift;
        my %args  = (@_);

        my $peeraddr     = delete $args{peeraddr};
        my $peerport     = delete $args{peerport};
        my $socket_proto = delete $args{socket_proto};

        tcp_connect $peeraddr, $peerport, Coro::rouse_cb;
        my $socket =
          Coro::DBI::Coro::Handle->new_from_fh( (Coro::rouse_wait)[0] );
        $proto->Fatal("Cannot connect: $!") unless $socket;

        $args{'socket'} = $socket;

        $proto->SUPER::new(%args);
    }

}

## fix up the Coro::Handle interface so that RPC::PlClient will tolerate it
{

    package Coro::DBI::Coro::Handle;
    our @ISA = qw/Coro::Handle/;

    use Socket;

    sub peerhost {
        my $p = getpeername tied( ${ $_[0] } )->[0];
        return inet_ntoa( ( sockaddr_in($p) )[1] );
    }

    sub peerport {
        my $p = getpeername tied( ${ $_[0] } )->[0];
        return ( sockaddr_in($p) )[0];
    }

    sub flush { 1; }
}

=head1 NAME

Coro::DBI - asynchronous DBI access


=head1 SYNOPSIS

    use Coro::DBI;

    async {
        # some asynchronous thread
        my $i=0;
        while ($i++) {
            print "$i\n";
        }
    };

    my $dbh = DBI->connect("DBI:SQLite:dbname=test.db", "", "");

    my $sth = $dbh->prepare("select * from test where num=?");

    $sth->execute(10);

    while (my @row = $sth->fetchrow_array) {
        print "@row\n";
    }

    $sth->finish;

    $dbh->disconnect;

=head1 DESCRIPTION

This module changes the behavior of C<DBI::connect> to move connections into
a child process so they will not block other coros.  It should be used before
the first database connection is made.

=head1 CLASS METHODS 

None of these methods need to be called for normal operation.

=head2 start
    Coro::DBI->start($tcp_port);

Starts the C<dbi_proxy> child process.

=head2 stop
    Coro::DBI->stop;

Kills the C<dbi_proxy> child process with SIGINT.

=head2 proxy_dsn 
    $prefix = Coro::DBI->dsn_prefix

Returns the L<DBD::Proxy> part of the C<data_source> so it can be prepended 
to your data source when connecting. 

You do not need to use the proxy_dsn directly.

=head1 SEE ALSO

L<Coro>, L<DBI>, L<AnyEvent::DBI>, L<Coro::Mysql>

=head1 AUTHOR

Eric Clark, C<< <eclark at genome.wustl.edu> >>

=head1 BUGS

Currently uses a hard-coded default TCP port 5001.

Suffers from the same bugs and limitations as L<DBD::Proxy>.

dbi_proxy child process will not shutdown automatically unless you are on Linux i386 or x86_64

=cut

1;    # End of Coro::DBI
