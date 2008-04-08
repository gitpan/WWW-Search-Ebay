
# $Id: DE.pm,v 2.10 2008/04/06 03:51:23 Martin Exp $

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
  $rhOptsArg->{search_host} = 'http://search.ebay.de';
  return $self->SUPER::_native_setup_search($native_query, $rhOptsArg);
  } # _native_setup_search

# This is what we look_down for to find the HTML element that contains
# the result count:
sub _result_count_element_specs_NOT_NEEDED
  {
  return (
          '_tag' => 'p',
          class => 'count'
         );
  } # _result_count_element_specs


sub _result_count_pattern
  {
  return qr'(\d+) Artikel gefunden ';
  } # _result_count_pattern

sub _next_text
  {
  # The text of the "Next" button, localized:
  return 'Weiter';
  } # _next_text

sub _currency_pattern
  {
  # A pattern to match all possible currencies found in eBay listings
  # (if one character looks weird, it's really a British Pound symbol
  # but Emacs shows it wrong):
  return qr{(?:US\s?\$|£|EUR)}; # } } # Emacs indentation bugfix
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
  # This is for DE:
  return qw( bids price shipping paypal enddate );
  } # _columns

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

