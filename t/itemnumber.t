
# $Id: itemnumber.t,v 1.14 2010-08-02 02:06:08 Martin Exp $

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
tm_run_test('normal', '280530100713', 1, 1, $iDebug, $iDump);

__END__

