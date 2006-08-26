
# $Id: DE.pm,v 2.2 2006/08/26 03:53:57 Daddy Exp $

=head1 NAME

WWW::Search::Ebay::DE - backend for searching auctions at www.ebay.de

=head1 DESCRIPTION

Acts just like WWW::Search::Ebay.

=head1 AUTHOR

C<WWW::Search::Ebay::DE> was written by Martin Thurn
(mthurn@cpan.org).

C<WWW::Search::Ebay::DE> is maintained by Martin Thurn
(mthurn@cpan.org).

=cut

package WWW::Search::Ebay::DE;

use Carp;
use WWW::Search::Ebay;
use vars qw( @ISA $VERSION );
@ISA = qw( WWW::Search::Ebay );
$VERSION = do { my @r = (q$Revision: 2.2 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  unless (ref($rhOptsArg) eq 'HASH')
    {
    carp " --- second argument to native_setup_search should be hashref, not arrayref";
    return undef;
    } # unless
  $rhOptsArg->{search_host} = 'http://search.ebay.de';
  return $self->SUPER::native_setup_search($native_query, $rhOptsArg);
  } # native_setup_search

# This is what we look_down for to find the HTML element that contains
# the result count:
sub _result_count_td_specs_OLD
  {
  return (
          '_tag' => 'p',
          id => 'count'
         );
  } # _result_count_td_specs

# This is what we look_down for to find the <TD> that contain auction
# titles:
sub _title_td_specs
  {
  return (
          '_tag' => 'td',
          'class' => 'ebcTtl',
         );
  } # _title_td_specs

sub _result_count_regex
  {
  return qr'(\d+) Artikel gefunden ';
  } # _result_count_regex

sub _next_text
  {
  # The text of the "Next" button, localized:
  return 'Weiter';
  } # _next_text

sub currency_pattern
  {
  # A pattern to match all possible currencies found in eBay listings
  # (if one character looks weird, it's really a British Pound symbol
  # but Emacs shows it wrong):
  return qr{(?:US\s?\$|£|EUR)}; # } } # Emacs indentation bugfix
  } # currency_pattern

sub preprocess_results_page_OFF
  {
  my $self = shift;
  my $sPage = shift;
  # print STDERR Dumper($self->{response});
  # For debugging:
  print STDERR $sPage;
  exit 88;
  } # preprocess_results_page

sub columns
  {
  my $self = shift;
  # This is for DE:
  return qw( bids price shipping paypal enddate );
  } # columns

sub _process_date_abbrevs
  {
  my $self = shift;
  my $s = shift;
  # Convert German abbreviations for units of time to something
  # Date::Manip can parse (namely, English words):
  $s =~ s!(\d)T!$1 days!;
  $s =~ s!(\d)Std!$1 hours!;
  $s =~ s!(\d)Min!$1 minutes!;
  return $s;
  } # _process_date_abbrevs


1;

__END__

