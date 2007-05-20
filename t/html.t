
# $Id: html.t,v 1.1 2007/04/07 21:16:53 Daddy Exp $

use Data::Dumper;
use ExtUtils::testlib;
use Test::More no_plan;

use constant DEBUG_DATE => 0;

BEGIN { use_ok('Date::Manip') };
$ENV{TZ} = 'EST5EDT';
&Date_Init('TZ=EST5EDT');
BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Ebay') };

use strict;

my $iDebug = 0;
my $iDump = 0;

&tm_new_engine('Ebay');

# We need a query that returns items that end in a few minutes.  This
# one attracts Rock'n'roll fans and philatelists:
TODO:
  {
  $TODO = 'We only need one page of results in order to test the HTML';
  &tm_run_test('normal', 'zeppelin', 1, 44, $iDebug, $iDump);
  }
$TODO = '';
# goto ALL_DONE;  # for debugging

# Now get some results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
# $WWW::Search::Test::oSearch->{_debug} = 2;
foreach my $oResult (@ao)
  {
  my $sHTML = $WWW::Search::Test::oSearch->result_as_HTML($oResult);
  # diag($sHTML);
  last;
  } # foreach
ALL_DONE:
exit 0;

__END__

