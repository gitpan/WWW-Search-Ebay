# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;
use WWW::Search;
use WWW::Search::Test qw( new_engine run_test );

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

# 6 tests without "goto MULTI_RESULT"
BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
$loaded = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$WWW::Search::Test::iTest = 0;

&new_engine('Ebay');
my $debug = 0;

# This test returns no results (but we should not get an HTTP error):
&run_test($WWW::Search::Test::bogus_query, 0, 0, $debug);
# goto MULTI_RESULT;
$debug = 0;
# This query usually returns 1 page of results:
&run_test('thurn und taxis', 1, 49, $debug);
# goto MULTI_RESULT;
$debug = 0;
# This query usually returns 2 pages of results:
&run_test('bib fortuna', 51, 99, $debug);

MULTI_RESULT:
$debug = 0;
# This query returns hundreds of pages of results:
&run_test('Star Wars', 101, undef, $debug);

&new_engine('Ebay::ByEndDate');
