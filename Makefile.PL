use inc::Module::Install;

name     'Coro-DBI';
author   'Eric Clark <zerohp@cpan.org>';
version_from 'lib/Coro/DBI.pm';
license  'perl';

build_requires 'Test::More';
requires 'AnyEvent' => 5.251;
requires 'Coro' => 5.21;
requires 'DBI' => 1.609;
requires 'RPC::PlServer' => '0.2017';
requires 'Linux::Pdeathsig' => '0.00_01';
auto_install;

WriteAll;

