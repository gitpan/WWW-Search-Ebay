
# $Id: itemnumber.t,v 1.7 2005/12/28 02:28:06 Daddy Exp $

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
&tm_run_test('normal', '6239654007', 1, 1, $iDebug, $iDump);

__END__

