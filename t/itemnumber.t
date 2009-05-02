
# $Id: itemnumber.t,v 1.12 2009/05/02 16:15:45 Martin Exp $

use Data::Dumper;
use ExtUtils::testlib;
use Test::More no_plan;

use WWW::Search::Test;
BEGIN
  {
  use_ok('WWW::Search::Ebay');
  } # end of BEGIN block

use strict;

my $iDebug;
my $iDump;

tm_new_engine('Ebay');

$iDebug = 0;
$iDump = 0;
tm_run_test('normal', '370196177721', 1, 1, $iDebug, $iDump);

__END__

