use ExtUtils::testlib;
use Test::More no_plan;

use constant DEBUG_DATE => 0;

BEGIN { use_ok('Date::Manip') };
BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test', qw( count_results )) };
BEGIN { use_ok('WWW::Search::Ebay') };

use strict;

my $iDebug = 0;
my $iDump = 0;

&Date_Init('TZ=US/Eastern');
&my_new_engine('Ebay::ByEndDate');
# goto TEST_NOW;

diag("Sending 0-page query...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
TEST_NOW:
diag("Sending query...");
$iDebug = 0;
$iDump = 0;
# We need a query that returns "Featured Items" _and_ items that end
# in a few minutes.  This one attracts Rock'n'roll fans and
# philatelists:
&my_test('normal', 'zeppelin', 55, 99, $iDebug, $iDump);
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
  isnt($sDate, '');
  my $iCmp = &Date_Cmp($sDatePrev, $sDate);
  cmp_ok($iCmp, '<=', 0, 'result is in order by end date');
  $sDatePrev = $sDate;
  } # foreach
ALL_DONE:
exit 0;

sub my_new_engine
  {
  my $sEngine = shift;
  $WWW::Search::Test::oSearch = new WWW::Search($sEngine);
  ok(ref($WWW::Search::Test::oSearch), "instantiate WWW::Search::$sEngine object");
  $WWW::Search::Test::oSearch->env_proxy('yes');
  } # my_new_engine

sub my_test
  {
  # Same arguments as WWW::Search::Test::count_results()
  my ($sType, $sQuery, $iMin, $iMax, $iDebug, $iPrintResults) = @_;
  my $iCount = &count_results(@_);
  cmp_ok($iCount, '>=', $iMin, qq{lower-bound num-hits for query=$sQuery}) if defined $iMin;
  # cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for query=$sQuery}) if defined $iMax;
  } # my_test


__END__
