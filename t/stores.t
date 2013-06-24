
# $Id: stores.t,v 1.20 2013/06/24 03:24:19 martin Exp $

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
  {
  $TODO = 'WWW::Search::Ebay can not fetch multiple pages';
  diag("Sending multi-page stores query...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns hundreds of pages of results:
  tm_run_test('normal', 'LEGO', 101, undef, $iDebug);
  cmp_ok(1, '<', $WWW::Search::Test::oSearch->{requests_made}, 'got multiple pages');
  $TODO = q{};
  }
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
my @ara;
push @ara, [
            url => like => qr{\Ahttp://(cgi|www)\d*\.ebay\.com}, 'result URL is really from ebay.com'
           ];
push @ara, [
            title => ne => q{''}, 'result title is not empty',
           ];
push @ara, [
            description => like => qr{([0-9]+|no)\s+bids?}, 'bid count is ok',
           ];
# Don't bother checking the end_date or change_date, because eBay
# stores are most likely to have only buy-it-now items (which do not
# have dates)
WWW::Search::Test::test_most_results(\@ara);

pass;
SKIP_CONTENTS:
pass;

__END__

