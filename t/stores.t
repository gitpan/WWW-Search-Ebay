
# $Id: stores.t,v 1.7 2005/03/12 20:06:45 Daddy Exp $

use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('Date::Manip') };
&Date_Init('TZ=-0500');
BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Ebay::Stores') };

my $iDebug = 0;
my $iDump = 0;

&tm_new_engine('Ebay::Stores');
# goto DEBUG_NOW;
# goto CONTENTS;

diag("Sending 0-page query...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);

# DEBUG_NOW:
;
MULTI_RESULT:
diag("Sending multi-page query...");
$iDebug = 0;
$iDump = 0;
# This query returns hundreds of pages of results:
&tm_run_test('normal', 'LEGO', 101, undef, $iDebug);

DEBUG_NOW:
;
CONTENTS:
diag("Sending 1-page query to check contents...");
$iDebug = 0;
$iDump = 0;
&tm_run_test('normal', 'shmi', 1, 99, $iDebug, $iDump);
# Now get the results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://cgi\d*\.ebay\.com},
       'result URL is really from ebay.com');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  cmp_ok(&ParseDate($oResult->change_date) || '', 'ne', '',
         'change_date is really a date');
  like($oResult->description, qr{([0-9]+|no)\s+bids?},
       'result bidcount is ok');
  like($oResult->bid_count, qr{\A\d+\Z}, 'bid_count is a number');
  } # foreach

__END__

