
# $Id: buyitnow.t,v 1.10 2007/05/20 13:33:19 Daddy Exp $

use Bit::Vector;
use Data::Dumper;
use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Ebay::BuyItNow') };

my $iDebug;
my $iDump = 0;

&tm_new_engine('Ebay::BuyItNow');
# goto DEBUG_NOW;
# goto CONTENTS;

diag("Sending 0-page query...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);

# DEBUG_NOW:
;
MULTI_RESULT:
diag("Sending multi-page query...");
$iDebug = 0;
$iDump = 0;
# This query returns hundreds of pages of results:
&tm_run_test('normal', 'LEGO', 101, undef, $iDebug);

# DEBUG_NOW:
;
TODO:
  {
  $TODO = 'sometimes there are too many of this book for sale';
  diag("Sending 1-page query for 12-digit UPC...");
  $iDebug = 0;
  $iDump = 0;
  &tm_run_test('normal', '0-77778-60672-7' , 1, 99, $iDebug, $iDump);
  $TODO = '';
  } # end of TODO
;
TODO:
  {
  $TODO = 'sometimes there are zero of this item';
  diag("Sending 1-page query for 13-digit EAN...");
  $iDebug = 0;
  $iDump = 0;
  &tm_run_test('normal', '00-75678-26382-8' , 1, 99, $iDebug, $iDump);
  $TODO = '';
  }
DEBUG_NOW:
diag("Sending 1-page query for 10-digit ISBN...");
TODO:
  {
  $TODO = 'sometimes there are none of this book for sale';
  $iDebug = 0;
  $iDump = 0;
  &tm_run_test('normal', '0-395-52021-5' , 1, 99, $iDebug, $iDump);
  $TODO = '';
  } # end of TODO block
# goto SKIP_CONTENTS;

CONTENTS:
diag("Sending 1-page query to check contents...");
$iDebug = 0;
$iDump = 0;
&tm_run_test('normal', 'Burkina Faso flag', 1, 99, $iDebug, $iDump);
# Now get the results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
# We perform this many tests on each result object:
my $iTests = 5;
my $iAnyFailed = 0;
my ($iVall, %hash);
my $oV = new Bit::Vector($iTests);
$oV->Fill;
$iVall = $oV->to_Dec;
foreach my $oResult (@ao)
  {
  $oV->Bit_Off(0) unless like($oResult->url, qr{\Ahttp://cgi\d*\.ebay\.com},
                              'result URL is really from ebay.com');
  $oV->Bit_Off(1) unless cmp_ok($oResult->title, 'ne', '',
                                'result Title is not empty');
  $oV->Bit_Off(2) unless cmp_ok($oResult->change_date, 'ne', '',
                                'result date is not empty');
  $oV->Bit_Off(3) unless like($oResult->description, qr{no\s+bids;},
                              'result bid count is ok');
  $oV->Bit_Off(4) unless like($oResult->description, qr{starting\sbid},
                              'result bid amount is ok');
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
SKIP_CONTENTS:
;

__END__

