
# $Id: itemnumber.t,v 1.4 2005/05/19 01:39:00 Daddy Exp $

use Data::Dumper;
use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Ebay') };

use strict;

my $iDebug;
my $iDump = 0;

&tm_new_engine('Ebay');

$iDebug = 0;
$iDump = 0;
&tm_run_test('normal', '4996614183', 1, 1, $iDebug, $iDump);

__END__

