
# $Id: FR.pm,v 2.7 2008/02/25 01:24:46 Daddy Exp $

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
$VERSION = do { my @r = (q$Revision: 2.7 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  unless (ref($rhOptsArg) eq 'HASH')
    {
    carp " --- second argument to native_setup_search should be hashref, not arrayref";
    return undef;
    } # unless
  $rhOptsArg->{search_host} = 'http://search.ebay.fr';
  return $self->SUPER::native_setup_search($native_query, $rhOptsArg);
  } # native_setup_search

# This is what we look_down for to find the HTML element that contains
# the result count:
sub result_count_element_specs_OLD
  {
  return (
          '_tag' => 'p',
          id => 'count'
         );
  } # result_count_element_specs

sub result_count_pattern
  {
  return qr'(\d+) objets? trouv';
  } # result_count_pattern

# This is what we look_down for to find the <TD> that contain auction
# titles:
sub title_element_specs
  {
  return (
          '_tag' => 'td',
          'class' => 'ebcTtl',
         );
  } # title_element_specs

sub _next_text
  {
  # The text of the "Next" button, localized:
  return 'Suivante';
  } # _next_text

sub title_pattern
  {
  my $self = shift;
  return qr{\A(.+?)\s+EN\s+VENTE\s+SUR\s+EBAY\.FR\s+()\(FIN\s+LE\s+([^)]+)\)}i;
  } # title_pattern

sub currency_pattern
  {
  my $self = shift;
  # A pattern to match all possible currencies found in eBay listings
  my $W = $self->whitespace_pattern;
  return qr{[\d.,]+$W+EUR}; # } } # Emacs indentation bugfix
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
  # This is for FR:
  return qw( paypal price shipping bids enddate );
  } # columns

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

