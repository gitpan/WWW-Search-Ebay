
# $Id: itemnumber.t,v 1.10 2008/08/03 17:50:56 Martin Exp $

use Data::Dumper;
use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Ebay') };

use strict;

my $iDebug;
my $iDump;

&tm_new_engine('Ebay');

$iDebug = 0;
$iDump = 0;
&tm_run_test('normal', '220264320842', 1, 1, $iDebug, $iDump);

__END__

