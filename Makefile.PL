use inc::Module::Install;

name('WWW-Search-Ebay');
author('Martin Thurn <mthurn@cpan.org>');
license('perl');
version(2.193);

requires(perl => 5.005);
# Date::Manip is needed for `make test`:
include_deps('Date::Manip', 5.004);
requires('Date::Manip');
# Test::More is needed for `make test`:
build_requires('Test::More');
requires('WWW::Search::Test' => 2.12);

check_nmake();      # check and download nmake.exe for Win32
&Makefile->write;

sub MY::postamble
  {
  my $ret = <<'PART0';
coverage :
	$(MAKE) HARNESS_PERL_SWITCHES=-MDevel::Cover coverage_slave
coverage_slave : test
	cover
PART0
  return $ret;
  } # MY::postamble

__END__
