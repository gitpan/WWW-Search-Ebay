use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('Date::Manip') };
BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test', qw( count_results )) };
BEGIN { use_ok('WWW::Search::Ebay') };

use strict;

my $iDebug;
my $iDump = 0;

&my_new_engine('Ebay::ByEndDate');

goto TEST_NOW;

$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
TEST_NOW:
$iDebug = 0;
$iDump = 0;
# This query usually returns 1 page of results:
&my_test('normal', 'star wars chip* -figure -comm* -lay*', 1, 49, $iDebug, $iDump);
# goto ALL_DONE;  # for debugging

CONTENTS:
$iDebug = 0;
# ebay.com reports all date-times as Pacific:
&Date_Init('TZ=US/Pacific');
# Now get some ByEndDate results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
if (0)
  {
  my $o = new WWW::Search('Ebay::ByEndDate');
  ok(ref $o);
  $o->native_query('Tobago flag',
                     {
                      search_debug => $iDebug,
                     },
                  );
  @ao = $o->results();
  } # if
cmp_ok(0, '<', scalar(@ao), 'got some results');
my $fDeltaPrev = -1;
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://cgi\d*\.ebay\.com},
       'result URL is really from ebay.com');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  my $sDate = $oResult->change_date;
  # diag(qq{raw result date is '$sDate'});
  # my $sDateOctal = &octalize($sDate);
  # diag(qq{octalized result date is '$sDateOctal'});
  cmp_ok($sDate, 'ne', '',
         'end date is not empty');
  # Tweak ebay interval so that Date::Manip can parse it:
  $sDate =~ s!(\d)m!$1mn!;
  # Clean up whitespace so Date::Manip can parse it:
  $sDate =~ s!\240!\040!g;
  # diag(qq{poached result date is '$sDate'});
  my $delta = &ParseDateDelta($sDate);
  # diag(qq{delta is $delta});
  # Create a sortable version of the delta:
  my $fDelta = &Delta_Format($delta, 4, '%dt');
  # diag(qq{fDelta is $fDelta});
  cmp_ok($fDeltaPrev, '<=', $fDelta, 'result is in order by end date');
  like($oResult->description, qr{([0-9]+|no)\s+bids?},
       'result bidcount is ok');
  $fDeltaPrev = $fDelta;
  } # foreach
ALL_DONE:
exit 0;

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
