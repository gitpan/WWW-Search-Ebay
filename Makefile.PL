
# $rcs = ' $Id: Makefile.PL,v 1.37 2006/02/19 20:43:40 Daddy Exp $ ';

use inc::Module::Install;

name('WWW-Search-Ebay');
author('Martin Thurn <mthurn@cpan.org>');
license('perl');
version(2.219);

requires(perl => 5.005);
build_requires('Bit::Vector');
requires('Date::Manip');
requires('HTML::TreeBuilder');
build_requires('IO::Capture::Stderr');
requires('LWP::Simple');
requires('Switch' => 2.10);
# Test::More is needed for `make test`:
build_requires('Test::More');
# We need the version that has method agent_name():
requires('WWW::Search' => 2.529);
# We need the version that has the bidder and seller methods:
requires('WWW::SearchResult' => 2.067);
# We need the version of WWW::Search::Test that exports its tm_
# functions:
build_requires('WWW::Search::Test' => 2.265);

check_nmake();      # check and download nmake.exe for Win32
&WriteAll;

sub MY::postamble
  {
  my $ret = <<'PART0';
coverage :
	$(RM_RF) cover_db/*
	$(MAKE) HARNESS_PERL_SWITCHES=-MDevel::Cover coverage_slave
coverage_slave : test
	cover
PART0
  return $ret;
  } # MY::postamble

__END__

