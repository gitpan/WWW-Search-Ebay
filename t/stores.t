
# $Id: stores.t,v 1.17 2008/09/07 03:26:11 Martin Exp $

use blib;
use Bit::Vector;
use Data::Dumper;
use Test::More no_plan;

use Date::Manip;
Date_Init('TZ=-0500');
use WWW::Search;
use WWW::Search::Test;
BEGIN
  {
  use_ok('WWW::Search::Ebay::Stores');
  }

my $iDebug = 0;
my $iDump = 0;

tm_new_engine('Ebay::Stores');
# goto DEBUG_NOW;
# goto CONTENTS;

diag("Sending 0-page stores query...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);

# DEBUG_NOW:
pass;
MULTI_RESULT:
pass;
diag("Sending multi-page stores query...");
$iDebug = 0;
$iDump = 0;
# This query returns hundreds of pages of results:
tm_run_test('normal', 'LEGO', 101, undef, $iDebug);
cmp_ok(1, '<', $WWW::Search::Test::oSearch->{requests_made}, 'got multiple pages');

pass;
DEBUG_NOW:
pass;
TODO:
  {
  $TODO = 'sometimes there are none of this item listed';
  diag("Sending 1-page stores query for 12-digit UPC...");
  $iDebug = 0;
  $iDump = 0;
  tm_run_test('normal', '093624-69602-5',
              1, 99, $iDebug, $iDump);
  $TODO = '';
  }
TODO:
  {
  $TODO = 'sometimes there are none of this item listed';
  diag("Sending 1-page stores query for 13-digit EAN...");
  $iDebug = 0;
  $iDump = 0;
  tm_run_test('normal', '00-77778-60672-7' , 1, 99, $iDebug, $iDump);
  $TODO = '';
  }
TODO:
  {
  $TODO = 'sometimes there are none of this item listed';
  diag("Sending stores query for 10-digit ISBN...");
  $iDebug = 0;
  $iDump = 0;
  tm_run_test('normal', '0-553-09606-0' , 1, undef, $iDebug, $iDump);
  $TODO = '';
  }
# goto SKIP_CONTENTS;

pass;
CONTENTS:
pass;
diag("Sending 1-page stores query to check contents...");
$iDebug = 0;
$iDump = 0;
tm_run_test('normal', 'shmi ccg', 1, 99, $iDebug, $iDump);
# Now get the results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
# We perform this many tests on each result object:
my $iTests = 5;
my $iAnyFailed = 0;
my ($iVall, %hash);
foreach my $oResult (@ao)
  {
  my $oV = new Bit::Vector($iTests);
  $oV->Fill;
  $iVall = $oV->to_Dec;
  # Create a vector of which tests passed:
  $oV->Bit_Off(1) unless like($oResult->url, qr{\Ahttp://cgi\d*\.ebay\.com},
                              'result URL is really from ebay.com');
  $oV->Bit_Off(2) unless cmp_ok($oResult->title, 'ne', '',
                                'result Title is not empty');
  $oV->Bit_Off(3) unless cmp_ok(ParseDate($oResult->change_date) || '', 'ne', '',
                                'change_date is really a date');
  $oV->Bit_Off(4) unless like($oResult->description, qr{([0-9]+|no)\s+bids?},
                              'result bidcount is ok');
  $oV->Bit_Off(0) unless like($oResult->bid_count, qr{\A\d+\Z},
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

pass;
SKIP_CONTENTS:
pass;

__END__

