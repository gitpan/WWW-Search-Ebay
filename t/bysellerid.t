
# $Id: bysellerid.t,v 1.12 2009-08-30 14:40:55 Martin Exp $

use Bit::Vector;
use Date::Manip;
use ExtUtils::testlib;
use Test::More no_plan;

use WWW::Search;
use WWW::Search::Test;
BEGIN
  {
  use_ok('WWW::Search::Ebay::BySellerID');
  }

my $iDebug;
my $iDump;

tm_new_engine('Ebay::BySellerID');
# goto DEBUG_NOW;
# goto CONTENTS;

diag("Sending 0-page query...");
$iDebug = 0;
$iDump = 0;
# This test returns no results (but we should not get an HTTP error):
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDump);

goto SKIP_MULTI;
pass('no-op');
# DEBUG_NOW:
pass('no-op');
MULTI_RESULT:
  {
  $TODO = 'WWW::Search::Ebay can not fetch multiple pages';
  diag("Sending multi-page query...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns many pages of results:
  tm_run_test('normal', 'toymom21957', 200, undef, $iDebug);
  cmp_ok(1, '<', $WWW::Search::Test::oSearch->{requests_made}, 'got multiple pages');
  $TODO = q{};
  }

DEBUG_NOW:
pass('no-op');
SKIP_MULTI:
pass('no-op');
CONTENTS:
diag("Sending 1-page query to check contents...");
$iDebug = 0;
$iDump = 0;
# local $TODO = 'Too hard to find a seller with consistently one page of auctions';
tm_run_test('normal', 'jessestoyland', 1, 199, $iDebug, $iDump);
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
  $oV->Bit_Off(3) unless cmp_ok(ParseDate($oResult->change_date) || '',
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

