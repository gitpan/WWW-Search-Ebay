
# $Id: UK.pm,v 1.14 2008/02/25 01:24:46 Daddy Exp $

=head1 NAME

WWW::Search::Ebay::UK - backend for searching auctions at www.ebay.co.uk

=head1 DESCRIPTION

Acts just like WWW::Search::Ebay.

=head1 AUTHOR

C<WWW::Search::Ebay::UK> was written by and is maintained by
Martin Thurn C<mthurn@cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

package WWW::Search::Ebay::UK;

use strict;
use warnings;

use Carp;
use base 'WWW::Search::Ebay';
our
$VERSION = do { my @r = (q$Revision: 1.14 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  unless (ref($rhOptsArg) eq 'HASH')
    {
    carp " --- second argument to native_setup_search should be hashref, not arrayref";
    return undef;
    } # unless
  $rhOptsArg->{search_host} = 'http://search.ebay.co.uk';
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

# This is what we look_down for to find the <TD> that contain auction
# titles:
sub title_element_specs
  {
  return (
          '_tag' => 'td',
          'class' => 'ebcTtl',
         );
  } # title_element_specs

sub currency_pattern
  {
  # A pattern to match all possible currencies found in eBay listings
  # (if one character looks weird, it's really a British Pound symbol
  # but Emacs shows it wrong):
  return qr{(?:US\s?\$|£)}; # } } # Emacs indentation bugfix
  } # currency_pattern

sub _preprocess_results_page
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
  # This is for UK:
  return qw( bids price postage paypal enddate );
  } # columns

1;

__END__

