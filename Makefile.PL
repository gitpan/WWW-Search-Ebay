
# $rcs = ' $Id: Makefile.PL,v 1.20 2004/11/28 02:46:50 Daddy Exp Daddy $ ';

use inc::Module::Install;

name('WWW-Search-Ebay');
author('Martin Thurn <mthurn@cpan.org>');
license('perl');
version(2.204);

requires(perl => 5.005);
build_requires('Bit::Vector');
requires('Date::Manip');
requires('HTML::TreeBuilder');
build_requires('IO::Capture::ErrorMessages');
requires('LWP::Simple');
# Test::More is needed for `make test`:
build_requires('Test::More');
# We need the version that has method agent_name():
requires('WWW::Search' => 2.529);
# We need the version that has method bid_count():
requires('WWW::SearchResult' => 2.063);
# We need the version of WWW::Search::Test that exports its tm_
# functions:
build_requires('WWW::Search::Test' => 2.265);

check_nmake();      # check and download nmake.exe for Win32
&Makefile->write;

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
