
# $Id: ES.pm,v 2.9 2008/04/05 14:48:03 Martin Exp $

=head1 NAME

WWW::Search::Ebay::ES - backend for searching auctions at eBay Spain

=head1 DESCRIPTION

Acts just like WWW::Search::Ebay.

=head1 AUTHOR

C<WWW::Search::Ebay::ES> was written by and is maintained by
Martin Thurn C<mthurn@cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

package WWW::Search::Ebay::ES;

use strict;
use warnings;

use Carp;
use base 'WWW::Search::Ebay';
our
$VERSION = do { my @r = (q$Revision: 2.9 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  unless (ref($rhOptsArg) eq 'HASH')
    {
    carp " --- second argument to native_setup_search should be hashref, not arrayref";
    return undef;
    } # unless
  $rhOptsArg->{search_host} = 'http://search.ebay.es';
  return $self->SUPER::native_setup_search($native_query, $rhOptsArg);
  } # native_setup_search

# This is what we look_down for to find the HTML element that contains
# the result count:
sub result_count_element_specs_USE_DEFAULT
  {
  return (
          '_tag' => 'div',
          class => 'count'
         );
  } # result_count_element_specs

# This is what we look_down for to find the <TD> that contain auction
# titles:
sub title_element_specs
  {
  return (
          '_tag' => 'td',
          'class' => 'ebcTtl',
         );
  } # title_element_specs

sub result_count_pattern
  {
  return qr'(?:encontrados?\s+)?(\d+)\s+art(�|í)culos\s+(?:encontrados?)?';
  } # result_count_pattern

sub _next_text
  {
  # The text of the "Next" button, localized:
  return 'Siguiente';
  } # _next_text

sub currency_pattern
  {
  my $self = shift;
  # A pattern to match all possible currencies found in eBay listings
  # (if one character looks weird, it's really a British Pound symbol
  # but Emacs shows it wrong):
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
  # This is for ES:
  return qw( paypal price bids shipping enddate );
  } # columns

sub _process_date_abbrevs
  {
  my $self = shift;
  my $s = shift;
  # Convert Spanish abbreviations for units of time to something
  # Date::Manip can parse (namely, English words):
  $s =~ s!(\d)d!$1 days!;
  $s =~ s!(\d)h!$1 hours!;
  $s =~ s!(\d)m!$1 minutes!;
  return $s;
  } # _process_date_abbrevs


1;

__END__

