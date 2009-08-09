
# $rcs = ' $Id: Makefile.PL,v 1.75 2009-08-09 01:52:15 Martin Exp $ ';

use inc::Module::Install;

all_from('lib/WWW/Search/Ebay.pm');
version(3.012);

requires(perl => 5.005);
test_requires('Bit::Vector');
requires('Date::Manip');
test_requires('Date::Manip');
requires('HTML::TreeBuilder');
test_requires('IO::Capture::Stderr');
requires('LWP::Simple');
# Test::More is needed for `make test`:
test_requires('Test::More');
test_recommends('Test::Pod');
test_recommends('Test::Pod::Coverage');
# We need the version that has methods named with leading underscore:
requires('WWW::Search' => 2.557);
# We need the version that has the bidder and seller methods:
requires('WWW::SearchResult' => 2.067);
# We need the version of WWW::Search::Test that exports its tm_
# functions:
test_requires('WWW::Search::Test' => 2.265);

WriteAll;

sub MY::postamble
  {
  my $ret = <<'PART0';
coverage :
	$(RM_RF) cover_db/*
	$(MAKE) HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover
PART0
  return $ret;
  } # MY::postamble

__END__

