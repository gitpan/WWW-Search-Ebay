
# $Id: bybidderid.t,v 1.2 2006/01/29 02:19:09 Daddy Exp $

use Bit::Vector;
use Data::Dumper;
use Date::Manip;
use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Ebay::ByBidderID') };

my $iDebug;
my $iDump = 0;

&tm_new_engine('Ebay::ByBidderID');
# goto DEBUG_NOW;
# goto CONTENTS;

diag("Sending 0-page query...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);

CONTENTS:
;
TODO:
  {
  $TODO = q{If this bidder is not bidding right now, we won't find any auctions!};
  diag("Sending query to check contents...");
  $iDebug = 0;
  $iDump = 0;
  &tm_run_test('normal', 'fabz75', 1, undef, $iDebug, $iDump);
  # Now get the results and inspect them:
  my @ao = $WWW::Search::Test::oSearch->results();
  cmp_ok(0, '<', scalar(@ao), 'got some results');
  is($WWW::Search::Test::oSearch->approximate_result_count, scalar(@ao), 'number of results == number listed on page');
  my $iTests = 8;
  foreach my $oResult (@ao)
    {
    my $oV = new Bit::Vector($iTests);
    $oV->Fill;
    $iVall = $oV->to_Dec;
    # Create a vector of which tests passed:
    my $iBit = 0;
    $oV->Bit_Off($iBit++) unless like($oResult->url,
                                      qr{\Ahttp://cgi\d*\.ebay\.com},
                                      'result URL is really from ebay.com');
    $oV->Bit_Off($iBit++) unless cmp_ok($oResult->title, 'ne', '',
                                        'result Title is not empty');
    $oV->Bit_Off($iBit++) unless cmp_ok(&ParseDate($oResult->start_date) || '',
                                        'ne', '',
                                        'start_date is really a date');
    $oV->Bit_Off($iBit++) unless cmp_ok(&ParseDate($oResult->end_date) || '',
                                        'ne', '',
                                        'end_date is really a date');
    $oV->Bit_Off($iBit++) unless like($oResult->item_number, qr{\A\d+\Z},
                                      'result item number is ok');
    $oV->Bit_Off($iBit++) unless cmp_ok($oResult->seller, 'ne', '',
                                        'seller is not empty');
    $oV->Bit_Off($iBit++) unless like($oResult->bid_amount, qr{\d},
                                      'bid_amount seems ok');
    $oV->Bit_Off($iBit++) unless cmp_ok($oResult->bidder, 'ne', '',
                                        'bidder is not empty');
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
  $TODO = '';
  } # end of TODO block

__END__

