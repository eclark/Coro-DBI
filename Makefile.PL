use inc::Module::Install;

name     'Coro-DBI';
all_from 'lib/Coro/DBI.pm';
author   'Eric Clark <eclark@genome.wustl.edu>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

