use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test', qw( count_results )) };
BEGIN { use_ok('WWW::Search::Ebay') };

my $iDebug;
my $iDump = 0;

&my_new_engine('Ebay');

$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
# goto MULTI_RESULT;
$iDebug = 0;
# This query usually returns 1 page of results:
&my_test('normal', 'star wars chip* -figure -comm* -lay*', 1, 49, $iDebug);

MULTI_RESULT:
$iDebug = 0;
# This query returns hundreds of pages of results:
&my_test('normal', 'LEGO', 101, undef, $iDebug);

CONTENTS:
$iDebug = 0;
# Now get some results and inspect them:
$WWW::Search::Test::oSearch->native_query('Trinidad Tobago flag');
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<=', scalar(@ao), 'got some results');
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://cgi\d*\.ebay\.com},
       'result URL is really from ebay.com');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  cmp_ok($oResult->change_date, 'ne', '',
         'result date is not empty');
  like($oResult->description, qr{([0-9]+|no)\s+bids?},
       'result bidcount is ok');
  } # foreach

sub my_new_engine
  {
  my $sEngine = shift;
  $WWW::Search::Test::oSearch = new WWW::Search($sEngine);
  ok(ref($WWW::Search::Test::oSearch), "instantiate WWW::Search::$sEngine object");
  } # my_new_engine

sub my_test
  {
  # Same arguments as WWW::Search::Test::count_results()
  my ($sType, $sQuery, $iMin, $iMax, $iDebug, $iPrintResults) = @_;
  my $iCount = &count_results(@_);
  cmp_ok($iCount, '>=', $iMin, qq{lower-bound num-hits for query=$sQuery}) if defined $iMin;
  cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for query=$sQuery}) if defined $iMax;
  } # my_test


__END__
