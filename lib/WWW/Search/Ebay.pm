# Ebay.pm
# by Martin Thurn
# $Id: Ebay.pm,v 2.151 2004/10/21 11:15:48 Daddy Exp $

=head1 NAME

WWW::Search::Ebay - backend for searching www.ebay.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay');
  my $sQuery = WWW::Search::escape_query("C-10 carded Yakface");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a Ebay specialization of L<WWW::Search>.
It handles making and interpreting Ebay searches
F<http://www.ebay.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

The search is done against CURRENT running AUCTIONS only.
(NOT completed auctions, NOT eBay Stores items, NOT Buy-It-Now only items.)
(If you want to search completed auctions, use the L<WWW::Search::Ebay::Completed> module.)
(If you want to search eBay Stores, use the L<WWW::Search::Ebay::Stores> module.)

The query is applied to TITLES only.

The results are ordered youngest auctions first (reverse order of
auction listing date).

In the resulting L<WWW::Search::Result> objects, the description field
consists of a human-readable combination (joined with semicolon-space)
of the Item Number; number of bids; and high bid amount (or starting
bid amount).

In the resulting L<WWW::Search::Result> objects, the bid_count field
contains the number of bids as an integer.

In the resulting L<WWW::Search::Result> objects, the bid_amount field is
a string containing the high bid or starting bid as a human-readable
monetary value in seller-native units, e.g. "$14.95" or "GBP 6.00".

=head1 OPTIONS

=over

=item Search descriptions

To search titles and descriptions, add 'srchdesc'=>'y' to the query options:

  $oSearch->native_query($sQuery, { srchdesc => 'y' } );

=item Search one category

To restrict your search to a particular eBay category,
find out eBay's ID number for the category and
add 'sacategory'=>123 to the query options:

  $oSearch->native_query($sQuery, { sacategory => 48995 } );

If you send a single asterisk or a single space as the query string,
the results will be ALL the auctions in that category.

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::Ebay> was written by Martin Thurn
(mthurn@cpan.org).

C<WWW::Search::Ebay> is maintained by Martin Thurn
(mthurn@cpan.org).

Some fixes along the way contributed by Troy Davis.

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::Ebay;

@ISA = qw( WWW::Search );

use Carp ();
# use Data::Dumper;  # for debugging only
use WWW::Search qw( generic_option strip_tags );
# We need the version that has bid_amount() and bid_count() methods:
use WWW::SearchResult 2.063;
use WWW::Search::Result;

$VERSION = do { my @r = (q$Revision: 2.151 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;

  # Set some private variables:
  $self->{_debug} ||= $rhOptsArg->{'search_debug'};
  $self->{_debug} = 2 if ($rhOptsArg->{'search_parse_debug'});
  $self->{_debug} ||= 0;

  my $DEFAULT_HITS_PER_PAGE = 100;
  $self->{'_hits_per_page'} = $DEFAULT_HITS_PER_PAGE;

  $self->user_agent('non-robot');
  # $self->agent_name('Mozilla/5.0 (compatible; Mozilla/4.0; MSIE 6.0; Windows NT 5.1; Q312461)');

  $self->{'_next_to_retrieve'} = 0;
  $self->{'_num_hits'} = 0;

  $self->{search_host} = 'http://search.ebay.com';
  $self->{search_path} = '/ws/search/SaleSearch';
  if (!defined($self->{_options}))
    {
    $self->{_options} = {
                         'satitle' => $native_query,
                         # Search AUCTIONS ONLY:
                         'sasaleclass' => 1,
                         # Display item number explicitly:
                         'socolumnlayout' => 2,
                         # Do not convert everything to US$:
                         'socurrencydisplay' => 1,
                         'sorecordsperpage' => $self->{_hits_per_page},
                         # Display absolute times, NOT relative times:
                         'sotimedisplay' => 1,
                        };
    } # if
  if (defined($rhOptsArg))
    {
    # Copy in new options.
    foreach my $key (keys %$rhOptsArg)
      {
      # print STDERR " +   inspecting option $key...";
      if (WWW::Search::generic_option($key))
        {
        # print STDERR "promote & delete\n";
        $self->{$key} = $rhOptsArg->{$key} if defined($rhOptsArg->{$key});
        delete $rhOptsArg->{$key};
        }
      else
        {
        # print STDERR "copy\n";
        $self->{_options}->{$key} = $rhOptsArg->{$key} if defined($rhOptsArg->{$key});
        }
      } # foreach
    } # if

  # Finally, figure out the url.
  $self->{_next_url} = $self->{'search_host'} . $self->{'search_path'} .'?'. $self->hash_to_cgi_string($self->{_options});
  } # native_setup_search


sub preprocess_results_page_OFF
  {
  my $self = shift;
  my $sPage = shift;
  # Ebay used to send malformed HTML:
  # my $iSubs = 0 + ($sPage =~ s!</FONT></TD></FONT></TD>!</FONT></TD>!gi);
  # print STDERR " +   deleted $iSubs extraneous tags\n" if 1 < $self->{_debug};
  # For debugging:
  print STDERR $sPage;
  exit 88;
  return $sPage;
  } # preprocess_results_page


sub currency_pattern
  {
  # A pattern to match all possible currencies found in eBay listings:
  return qr/(?:\$|C|EUR|GBP)/;
  } # currency_pattern

# private
sub parse_tree
  {
  my $self = shift;
  my $tree = shift;

  # A pattern to match HTML whitespace:
  my $W = q{[\ \t\r\n\240]};
  my $hits_found = 0;
  # The hit count is in a FONT tag:
  my @aoFONT = $tree->look_down('_tag' => 'td',
                                width => '75%',);
 FONT:
  foreach my $oFONT (@aoFONT)
    {
    print STDERR " +   try FONT ===", $oFONT->as_text, "===\n" if 1 < $self->{_debug};
    if ($oFONT->as_text =~ m!(\d+) items found !)
      {
      $self->approximate_result_count($1);
      last FONT;
      } # if
    } # foreach
  my $currency = $self->currency_pattern;
  # The list of matching items is in a table.  The first column of the
  # table is nothing but icons; the second column is the good stuff.
  my @aoTD = $tree->look_down('_tag', 'td',
                              'width' => '8%',
                              sub { ($_[0]->as_text =~ m!\A\d{9,}\Z! ) }
                             );
 TD:
  foreach my $oTD (0, @aoTD)
    {
    # Sanity check:
    next TD unless ref $oTD;
    my $iItemNum = $oTD->as_text;
    my $sTD = $oTD->as_HTML;
    print STDERR " + try TD ===$sTD===\n" if 1 < $self->{_debug};
    my $oTDtitle = $oTD->left;
    # First A tag contains the url & title:
    my $oA = $oTDtitle->look_down('_tag', 'a');
    next TD unless ref $oA;
    my $sURL = $oA->attr('href');
    next TD unless $sURL =~ m!ViewItem!;
    my $sTitle = $oA->as_text;
    my ($iPrice, $iBids, $iBidInt, $sDate) = ('$unknown', 'no', 'unknown');
    # The rest of the info about this item is in sister TD elements to
    # the right:
    my @aoSibs = $oTD->right;
    # The next sister has the current bid amount (or starting bid):
    my $oTDprice = shift @aoSibs;
    $oTDprice = shift @aoSibs;
    if (ref $oTDprice)
      {
      if (1 < $self->{_debug})
        {
        my $s = $oTDprice->as_HTML;
        print STDERR " +   TDprice ===$s===\n";
        } # if
      $iPrice = $oTDprice->as_text;
      $iPrice =~ s!(\d)$W*($currency$W*[\d.,]+)!$1 (Buy-It-Now for $2)!;
      } # if
    # The next sister has the number of bids:
    my $oTDbids = shift @aoSibs;
    if (ref $oTDbids)
      {
      if (1 < $self->{_debug})
        {
        my $s = $oTDbids->as_HTML;
        print STDERR " +   TDbids ===$s===\n";
        } # if
      $iBidInt = $iBids = $oTDbids->as_text;
      } # if
    if (
        # Bid listed as hyphen means no bids:
        ($iBids =~ m!\A$W*-$W*\Z!)
        ||
        # Bid listed as whitespace means no bids:
        ($iBids =~ m!\A$W*\Z!)
       )
      {
      $iBids = 'no';
      $iBidInt = 0;
      } # if
    my $sDesc = "Item \043$iItemNum; $iBids bid";
    $sDesc .= 's' if $iBids ne '1';
    $sDesc .= '; ';
    $sDesc .= 'no' ne $iBids ? 'current' : 'starting';
    $sDesc .= " bid $iPrice";
    # The next sister has the auction start date...
    my $oTDdate = shift @aoSibs;
    # ...unless this is a Stores search, in which case the next sister
    # is the store name:
    $oTDdate = shift @aoSibs if (ref($self) eq 'WWW::Search::Ebay::Stores');
    if (ref $oTDdate)
      {
      my $s = $oTDdate->as_HTML;
      print STDERR " +   TDdate ===$s===\n" if 1 < $self->{_debug};
      $sDate = $oTDdate->as_text;
      # Convert nbsp to regular space:
      $sDate =~ s!\240!\040!g;
      } # if
    my $hit = new WWW::Search::Result;
    # Make sure we don't return two different URLs for the same item:
    $sURL =~ s!&rd=\d+!!;
    $sURL =~ s!&ssPageName=[A-Z0-9]+!!;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description($sDesc);
    $hit->change_date($sDate);
    $hit->bid_count($iBidInt);
    $hit->bid_amount($iPrice);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    # Delete this HTML element so that future searches go faster?
    $oTD->detach;
    $oTD->delete;
    } # foreach

  # Look for a NEXT link:
  my @aoA = $tree->look_down('_tag', 'a');
 TRY_NEXT:
  foreach my $oA (0, reverse @aoA)
    {
    next TRY_NEXT unless ref $oA;
    print STDERR " +   try NEXT A ===", $oA->as_HTML, "===\n" if 1 < $self->{_debug};
    my $href = $oA->attr('href');
    next TRY_NEXT unless $href;
    # If we get all the way to the item list, there must be no next
    # button:
    last TRY_NEXT if ($href =~ m!ViewItem!);
    if ($oA->as_text eq 'Next')
      {
      print STDERR " +   got NEXT A ===", $oA->as_HTML, "===\n" if 1 < $self->{_debug};
      $self->{_next_url} = $self->absurl($self->{_prev_url}, $href);
      last TRY_NEXT;
      } # if
    } # foreach

  # All done with this page.
  $tree->delete;
  return $hits_found;
  } # parse_tree

1;

__END__

