
# $Id: DE.pm,v 2.8 2008/02/25 01:24:45 Daddy Exp $

=head1 NAME

WWW::Search::Ebay::DE - backend for searching auctions at www.ebay.de

=head1 DESCRIPTION

Acts just like WWW::Search::Ebay.

=head1 AUTHOR

C<WWW::Search::Ebay::DE> was written by and is maintained by
Martin Thurn C<mthurn@cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

package WWW::Search::Ebay::DE;

use strict;
use warnings;

use Carp;
use base 'WWW::Search::Ebay';
our
$VERSION = do { my @r = (q$Revision: 2.8 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

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
sub result_count_element_specs_NOT_NEEDED
  {
  return (
          '_tag' => 'p',
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
  return qr'(\d+) Artikel gefunden ';
  } # result_count_pattern

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
  $s =~ s!(\d)Std\.?!$1 hours!;
  $s =~ s!(\d)Min\.?!$1 minutes!;
  return $s;
  } # _process_date_abbrevs


1;

__END__

