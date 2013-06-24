
# $rcs = ' $Id: Makefile.PL,v 1.92 2013/06/24 03:17:04 martin Exp $ ';

use inc::Module::Install;

version(3.027);
all_from('lib/WWW/Search/Ebay.pm');

requires(perl => 5.005);
test_requires('Bit::Vector');
requires('Date::Manip');
# requires('DateTime::TimeZone');
test_requires('Date::Manip');
requires('HTML::TreeBuilder');
test_requires('IO::Capture::Stderr');
requires('LWP::Simple');
# Test::More is needed for `make test`:
test_requires('Test::More');
recommends('Test::Pod');
recommends('Test::Pod::Coverage');
# We need the version that has methods named with leading underscore:
requires('WWW::Search' => 2.557);
# We need the version that has the bidder and seller methods:
requires('WWW::SearchResult' => 2.067);
# We need the bug-fixed version of WWW::Search::Test:
test_requires('WWW::Search::Test' => 2.290);

my $ret = <<'PART0';
coverage :
	$(RM_RF) cover_db/*
	$(MAKE) HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover
PART0
postamble $ret;

WriteAll;

use Env;
if ($ENV{MTHURN_PERL_DEV})
  {
  print "DDD This is author's development environment\n";
  my $sFnameMakefile = q{Makefile};
  eval "use File::Slurp";
  my $s = read_file($sFnameMakefile);
  if ($s !~ s/(DIRFILESEP\s*=\s*).+$/$1\//m)
    {
    print " EEE did not find DIRFILESEP in Makefile\n";
    } # if
  if ($s !~ s/(pm_to_blib\(){{\@ARGV}}/$1 . '{@ARGV}'/e)
    {
    print " EEE did not find pm_to_blib@ARGV in Makefile\n";
    } # if
  if ($s !~ s/(from_to\s+=>\s+){{\@ARGV}}/$1 . '{@ARGV}'/e)
    {
    print " EEE did not find from_to@ARGV in Makefile\n";
    } # if
  write_file($sFnameMakefile, $s);
  } # if

__END__

