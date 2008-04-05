
# $Id: Stores.pm,v 1.12 2008/02/24 21:16:21 Daddy Exp $

=head1 NAME

WWW::Search::Ebay::Stores - backend for searching eBay Stores

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::Stores');
  my $sQuery = WWW::Search::escape_query("C-10 carded Yakface");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a Ebay specialization of WWW::Search.
It handles making and interpreting Ebay searches
F<http://www.ebay.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

The search is done against eBay Stores items only.

The query is applied to TITLES only.

See L<WWW::Search::Ebay> for a description of the search results.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::Ebay::Stores> was written by and is maintained by
Martin Thurn C<mthurn@cpan.org>, L<http://tinyurl.com/nn67z>.

Some fixes along the way contributed by Troy Davis.

=cut

package WWW::Search::Ebay::Stores;

use strict;
use warnings;

use base 'WWW::Search::Ebay';
our
$VERSION = do { my @r = (q$Revision: 1.12 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  # As of 2004-10-20:
  # http://search.stores.ebay.com/search/search.dll?sofocus=bs&sbrftog=1&catref=C6&socurrencydisplay=1&from=R10&sasaleclass=1&sorecordsperpage=100&sotimedisplay=1&socolumnlayout=2&satitle=star+wars+lego&sacategory=-6%26catref%3DC6&bs=Search&sofp=4&sotr=2&sapricelo=&sapricehi=&searchfilters=&sosortproperty=1&sosortorder=1
  # simplest = http://search.stores.ebay.com/search/search.dll?socurrencydisplay=1&sasaleclass=1&sorecordsperpage=100&sotimedisplay=1&socolumnlayout=2&satitle=star+wars+lego
  # As of 2005-08-29:
  # http://search.stores.ebay.com/search/search.dll?satitle=093624-69602-5
  $rh->{'search_host'} = 'http://search.stores.ebay.com';
  $rh->{'search_path'} = '/search/search.dll';
  $rh->{'satitle'} = $sQuery;
  # Turn off default W::S::Ebay options:
  $self->{_options} = {};
  return $self->SUPER::native_setup_search($sQuery, $rh);
  } # native_setup_search

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
  # This is for Stores:
  return qw( paypal bids price shipping store enddate );
  } # columns


1;

__END__

