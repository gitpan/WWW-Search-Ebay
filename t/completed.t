use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('Date::Manip') };
BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test', qw( count_results )) };
BEGIN { use_ok('WWW::Search::Ebay') };
BEGIN { use_ok('WWW::Search::Ebay::Completed') };

use strict;
use warnings;

my $iDebug;
my $iDump = 0;

&my_new_engine('Ebay::Completed');

# goto TEST_NOW;  # for debugging

$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
TEST_NOW:
$iDebug = 0;
$iDump = 0;
# This query usually returns many results:
&my_test('normal', 'yak', 1, undef, $iDebug, $iDump);
# goto ALL_DONE;  # for debugging

CONTENTS:
$iDebug = 0;
# ebay.com reports all date-times as Pacific:
&Date_Init('TZ=US/Pacific');
my $dateNow = &ParseDate('now');
# diag(qq{dateNow is $dateNow});
# my $sDateTest = 'Oct-24 17:17';
# my $dateTest = &ParseDate($sDateTest);
# diag(qq{dateTest is $dateTest});
# exit 1;
# Now get some Completed results and inspect them:
if (0)
  {
  $WWW::Search::Test::oSearch->native_query('star wars chip* -figure -comm* -lay*',
                                              {
                                               search_debug => $iDebug,
                                              },
                                           );
  } # if
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://cgi\d*\.ebay\.com},
       'result URL is really from ebay.com');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  my $sDate = $oResult->change_date;
  # Clean up whitespace so Date::Manip can parse it:
  $sDate =~ s!\240!\040!g;
  # diag(qq{raw result date is '$sDate'});
  # my $sDateOctal = &octalize($sDate);
  # diag(qq{octalized result date is '$sDateOctal'});
  cmp_ok($sDate, 'ne', '',
         'result date is not empty');
  # Make sure the end-date is in the past:
  my $dateResult = &ParseDate($sDate); # "Oct-26 17:17"); # $sDate);
  # diag(qq{cooked result date is '$dateResult'});
  cmp_ok($dateResult, 'ne', '', 'result date is really a date');
  # diag(qq{raw result date is still '$sDate'});
  my $iCmp = &Date_Cmp($dateResult, $dateNow);
  cmp_ok($iCmp, '<', 0, 'result date is in the past');
  like($oResult->description, qr{([0-9]+|no)\s+bids?},
       'result bidcount is ok');
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
  cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for query=$sQuery}) if defined $iMax;
  } # my_test

sub octalize
  {
  return join(',', map { sprintf('%c=\%0.3o,', ord($_), ord($_)) } split('', shift));
  } # octalize

__END__
