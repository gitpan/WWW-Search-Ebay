use inc::Module::Install;

name('WWW::Search::Ebay');
author('Martin Thurn <mthurn@cpan.org>');
license('perl');
version(2.14);

requires('WWW::Search::Test' => 2.12);
# Test::More is needed for `make test`:
include_deps('Test::More', 5.004);
requires('Test::More');

check_nmake();      # check and download nmake.exe for Win32
&Makefile->write;

__END__
