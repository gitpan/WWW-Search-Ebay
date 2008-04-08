
# $Id: FR.pm,v 2.10 2008/04/06 03:51:23 Martin Exp $

=head1 NAME

WWW::Search::Ebay::FR - backend for searching auctions at eBay France

=head1 DESCRIPTION

Acts just like WWW::Search::Ebay.

=head1 AUTHOR

C<WWW::Search::Ebay::FR> was written by and is maintained by
Martin Thurn C<mthurn@cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

package WWW::Search::Ebay::FR;

use strict;
use warnings;

use Carp;
use base 'WWW::Search::Ebay';
our
$VERSION = do { my @r = (q$Revision: 2.10 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub _native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  unless (ref($rhOptsArg) eq 'HASH')
    {
    carp " --- second argument to _native_setup_search should be hashref, not arrayref";
    return undef;
    } # unless
  $rhOptsArg->{search_host} = 'http://search.ebay.fr';
  return $self->SUPER::_native_setup_search($native_query, $rhOptsArg);
  } # _native_setup_search

# This is what we look_down for to find the HTML element that contains
# the result count:
sub _result_count_element_specs_USE_DEFAULT
  {
  return (
          '_tag' => 'p',
          id => 'count'
         );
  } # _result_count_element_specs

sub _result_count_pattern
  {
  return qr'(\d+) objets? trouv';
  } # _result_count_pattern


sub _next_text
  {
  # The text of the "Next" button, localized:
  return 'Suivante';
  } # _next_text

sub _title_pattern
  {
  my $self = shift;
  return qr{\A(.+?)\s+EN\s+VENTE\s+SUR\s+EBAY\.FR\s+()\(FIN\s+LE\s+([^)]+)\)}i;
  } # _title_pattern

sub _currency_pattern
  {
  my $self = shift;
  # A pattern to match all possible currencies found in eBay listings
  my $W = $self->whitespace_pattern;
  return qr{[\d.,]+$W+EUR}; # } } # Emacs indentation bugfix
  } # _currency_pattern

sub _preprocess_results_page_OFF
  {
  my $self = shift;
  my $sPage = shift;
  # print STDERR Dumper($self->{response});
  # For debugging:
  print STDERR $sPage;
  exit 88;
  } # _preprocess_results_page

sub _columns
  {
  my $self = shift;
  # This is for FR:
  return qw( paypal price shipping bids enddate );
  } # _columns

sub _process_date_abbrevs
  {
  my $self = shift;
  my $s = shift;
  # Convert French abbreviations for units of time to something
  # Date::Manip can parse (namely, English words):
  $s =~ s!(\d)j!$1 days!;
  $s =~ s!(\d)h!$1 hours!;
  $s =~ s!(\d)m!$1 minutes!;
  return $s;
  } # _process_date_abbrevs


1;

__END__

