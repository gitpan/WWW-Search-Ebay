
# $Id: motors.t,v 1.14 2008/09/28 03:16:09 Martin Exp $

use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Ebay::Motors') };

my $iDebug;
my $iDump = 0;

tm_new_engine('Ebay::Motors');
# goto DEBUG_NOW;
# goto CONTENTS;

if (0)
  {
  diag("Sending 0-page motors query...");
  $iDebug = 1;
  # This test returns no results (but we should not get an HTTP error):
  tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
  } # if
pass;
MULTI_RESULT:
pass;
diag("Sending multi-page motors query...");
$iDebug = 0;
$iDump = 0;
# This query should return hundreds of pages of results:
tm_run_test('normal', 'Chevrolet', 111, undef, $iDebug, $iDump);
cmp_ok(1, '<', $WWW::Search::Test::oSearch->{requests_made}, 'got multiple pages');
# goto SKIP_CONTENTS;

DEBUG_NOW:
pass;
CONTENTS:
pass;
diag("Sending 1-page motors query to check contents...");
$iDebug = 0;
$iDump = 0;
$WWW::Search::Test::sSaveOnError = q{motors-1-failed.html};
tm_run_test('normal', 'Bugatti', 1, 49, $iDebug, $iDump);
# Now get the results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://cgi\d*\.ebay\.com},
       'result URL is really from ebaymotors');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  cmp_ok($oResult->change_date, 'ne', '',
         'result date is not empty');
  like($oResult->description, qr{([0-9]+|no)\s+bids?},
       'result bidcount is ok');
  } # foreach
SKIP_CONTENTS:
pass('all done');

__END__

