
# $Id: itemnumber.t,v 1.8 2007/08/21 01:01:41 Daddy Exp $

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
&tm_run_test('normal', '250156179441', 1, 1, $iDebug, $iDump);

__END__

