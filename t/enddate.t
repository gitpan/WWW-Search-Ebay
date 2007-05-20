
# $Id: enddate.t,v 1.8 2007/05/20 13:33:19 Daddy Exp $

use Data::Dumper;
use ExtUtils::testlib;
use Test::More no_plan;

use constant DEBUG_DATE => 0;

BEGIN { use_ok('Date::Manip') };
$ENV{TZ} = 'EST5EDT';
&Date_Init('TZ=EST5EDT');
BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Ebay') };

use strict;

my $iDebug = 0;
my $iDump = 0;

&tm_new_engine('Ebay::ByEndDate');
# goto TEST_NOW;

diag("Sending 0-page query...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
TEST_NOW:
diag("Sending query...");
$iDebug = 0;
$iDump = 0;
# We need a query that returns "Featured Items" _and_ items that end
# in a few minutes.  This one attracts Rock'n'roll fans and
# philatelists:
TODO:
  {
  $TODO = 'We only need one page of results in order to test the end-date sort';
  &tm_run_test('normal', 'zeppelin', 55, 99, $iDebug, $iDump);
  }
$TODO = '';
# goto ALL_DONE;  # for debugging

# Now get some ByEndDate results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
my $sDatePrev = 'yesterday';
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://cgi\d*\.ebay\.com},
       'result URL is really from ebay.com');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  like($oResult->description, qr{([0-9]+|no)\s+bids?},
       'result bidcount is ok');
  my $sDate = $oResult->change_date || '';
  DEBUG_DATE && diag(qq{raw result date is '$sDate'});
  diag(Dumper($oResult)) unless isnt($sDate, '');
  my $iCmp = &Date_Cmp($sDatePrev, $sDate);
  cmp_ok($iCmp, '<=', 0, 'result is in order by end date');
  $sDatePrev = $sDate;
  } # foreach
ALL_DONE:
exit 0;

__END__

