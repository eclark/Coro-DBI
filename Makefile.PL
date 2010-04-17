use inc::Module::Install;

name     'Coro-DBI';
all_from 'lib/Coro/DBI.pm';
author   'Eric Clark <eclark@genome.wustl.edu>';
license  'perl';

build_requires 'Test::More';
requires 'AnyEvent' => 5.251;
requires 'Coro' => 5.21;
requires 'DBI' => 1.609;

auto_install;

WriteAll;

