
# $Id: basic.t,v 1.12 2005/08/18 04:56:09 Daddy Exp $

use Bit::Vector;
use Data::Dumper;
use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('Date::Manip') };
&Date_Init('TZ=-0500');
BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Ebay') };

use strict;

my $iDebug;
my $iDump = 0;

&tm_new_engine('Ebay');
# goto DEBUG_NOW;
# goto CONTENTS;

diag("Sending 0-page queries...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
# There are no hits for "laavar", but eBay gives us all the "lavar"
# hits:
$iDebug = 0;
&tm_run_test('normal', 'laavar', 0, 0, $iDebug);

;
MULTI_RESULT:
diag("Sending multi-page query...");
$iDebug = 0;
$iDump = 0;
# This query returns hundreds of pages of results:
&tm_run_test('normal', 'LEGO', 101, undef, $iDebug);

if (0)
  {
  # The intention of this test block is to retrieve a page that
  # returns hits on the exact query term, AND hits on alternate
  # spellings.  It's just too hard to find such a word that
  # consistently performs as needed.
  local $TODO = "Sometimes there are NO hits for lavarr";
  diag("Sending 1-page queries...");
  # There are a few hits for "lavarr", and eBay also gives us all the
  # "lavar" hits:
  $iDebug = 0;
  &tm_run_test('normal', 'lavarr', 1, 99, $iDebug);
  }

DEBUG_NOW:
;
CONTENTS:
diag("Sending 1-page query to check contents...");
$iDebug = 0;
$iDump = 0;
&tm_run_test('normal', 'trinidad tobago flag', 1, 99, $iDebug, $iDump);
# Now get the results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
# We perform this many tests on each result object:
my $iTests = 7;
my $iAnyFailed = 0;
my ($iVall, %hash);
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
  $oV->Bit_Off(0) unless unlike($oResult->title, qr{(?i:quakers)},
                                'result Title is not "quakers"');
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

