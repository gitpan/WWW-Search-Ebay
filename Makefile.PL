use inc::Module::Install;

name('WWW-Search-Ebay');
author('Martin Thurn <mthurn@cpan.org>');
license('perl');
version(2.195);

requires(perl => 5.005);
requires('Date::Manip');
build_requires('IO::Capture::ErrorMessages');
# Test::More is needed for `make test`:
build_requires('Test::More');
# We need the version that has method agent_name():
requires('WWW::Search' => 2.529);

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
