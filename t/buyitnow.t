use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test', qw( count_results )) };
BEGIN { use_ok('WWW::Search::Ebay::BuyItNow') };

my $iDebug;
my $iDump = 0;

&my_new_engine('Ebay::BuyItNow');
# goto DEBUG_NOW;
# goto CONTENTS;

diag("Sending 0-page query...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);

# DEBUG_NOW:
;
MULTI_RESULT:
diag("Sending multi-page query...");
$iDebug = 0;
$iDump = 0;
# This query returns hundreds of pages of results:
&my_test('normal', 'LEGO', 101, undef, $iDebug);

CONTENTS:
diag("Sending 1-page query to check contents...");
$iDebug = 0;
$iDump = 0;
&my_test('normal', 'Trinidad Tobago flag', 1, 99, $iDebug, $iDump);
# Now get the results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://cgi\d*\.ebay\.com},
       'result URL is really from ebay.com');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  cmp_ok($oResult->change_date, 'ne', '',
         'result date is not empty');
  like($oResult->description, qr{no\s+bids;},
       'result bid count is ok');
  like($oResult->description, qr{starting\sbid},
       'result bid amount is ok');
  } # foreach

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
  if (defined $iMin)
    {
    cmp_ok($iMin, '<=', $iCount, qq{lower-bound num-hits for query=$sQuery});
    cmp_ok($iMin, '<=', $WWW::Search::Test::oSearch->approximate_result_count,
           qq{lower-bound approximate_result_count});
    } # if
  if (defined $iMax)
    {
    cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for query=$sQuery});
    cmp_ok($WWW::Search::Test::oSearch->approximate_result_count, '<=', $iMax,
           qq{upper-bound approximate_result_count});
    } # if
  } # my_test


__END__
