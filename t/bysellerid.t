
# $Id: bysellerid.t,v 1.7 2007/12/05 19:12:52 Daddy Exp $

use Bit::Vector;
use Date::Manip;
use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Ebay::BySellerID') };

my $iDebug;
my $iDump = 0;

&tm_new_engine('Ebay::BySellerID');
goto DEBUG_NOW;
# goto CONTENTS;

diag("Sending 0-page query...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);

# goto SKIP_MULTI;
# DEBUG_NOW:
;
MULTI_RESULT:
diag("Sending multi-page query...");
$iDebug = 0;
$iDump = 0;
# This query returns many pages of results:
&tm_run_test('normal', 'toymom21957', 201, undef, $iDebug);

DEBUG_NOW:
;
SKIP_MULTI:
;
CONTENTS:
diag("Sending 1-page query to check contents...");
$iDebug = 0;
$iDump = 0;
# local $TODO = 'Too hard to find a seller with consistently one page of auctions';
&tm_run_test('normal', 'martinthurn', 1, 99, $iDebug, $iDump);
# Now get the results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
my $iTests = 7;
foreach my $oResult (@ao)
  {
  my $oV = new Bit::Vector($iTests);
  $oV->Fill;
  $iVall = $oV->to_Dec;
  # Create a vector of which tests passed:
  $oV->Bit_Off(1) unless like($oResult->url,
                              qr{\Ahttp://cgi\d*\.ebay\.com},
                              'result URL is really from ebay.com');
  $oV->Bit_Off(2) unless cmp_ok($oResult->title, 'ne', '',
                                'result Title is not empty');
  $oV->Bit_Off(3) unless cmp_ok(&ParseDate($oResult->change_date) || '',
                                'ne', '',
                                'change_date is really a date');
  $oV->Bit_Off(4) unless like($oResult->description,
                              qr{Item #\d+;},
                              'result item number is ok');
  $oV->Bit_Off(5) unless like($oResult->description,
                              qr{\s(\d+|no)\s+bids?;},
                              'result bidcount is ok');
  $oV->Bit_Off(6) unless like($oResult->bid_count, qr{\A\d+\Z},
                              'bid_count is a number');
  my $iV = $oV->to_Dec;
  if ($iV < $iVall)
    {
    $hash{$iV} = $oResult;
    $iAnyFailed++;
    } # if
  } # foreach
if ($iAnyFailed)
  {
  diag(" Here are results that exemplify the failures:");
  while (my ($sKey, $sVal) = each %hash)
    {
    diag(Dumper($sVal));
    } # while
  } # if


__END__

