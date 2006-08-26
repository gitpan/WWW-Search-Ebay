
# $Id: ByBidderID.pm,v 2.1 2005/12/28 02:06:02 Daddy Exp $

=head1 NAME

WWW::Search::Ebay::ByBidderID - backend for searching eBay for items offered by a particular seller

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::ByBidderID');
  my $sQuery = WWW::Search::escape_query("fabz75");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

See L<WWW::Search::Ebay> for details.
The query string must be an eBay bidder ID.

This class is an Ebay specialization of WWW::Search.
It handles making and interpreting Ebay searches
F<http://www.ebay.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

Searches only for items being bid on by eBay buyers whose ID matches exactly.

The resulting L<WWW::Search::Result> objects will have the following
attributes filled in:

=over

=item start_date

The approximate date the auction started.

=item end_date

The date/time the auction will end.

=item bid_amount

The current high bid.

=item title

The auction title.

=item bidder

The eBay ID of the current high bidder.

=item seller

The eBay ID of the seller.

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 AUTHOR

Code contributed by Andreas Grau.  Thank you!
Maintained by Martin Thurn as part of the WWW-Search-Ebay distribution.

=cut

package WWW::Search::Ebay::ByBidderID;

use Data::Dumper;
use Switch;
use WWW::Search::Ebay;

use vars qw( @ISA $VERSION );
@ISA = qw( WWW::Search::Ebay );
$VERSION = do { my @r = (q$Revision: 2.1 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  $rh->{'search_host'} = 'http://cgi.ebay.com';
  $rh->{'search_path'} = '/ws/eBayISAPI.dll';
  $rh->{'userid'} = $sQuery;
  $rh->{'completed'} = 0 if not defined $rh->{'completed'};  # return completed auctions
  $rh->{'all'} = 1       if not defined $rh->{'all'};        # return auctions where bidder is not high-bidder
  $rh->{'rows'} = '200';  # Results per page
  $rh->{'sort'} = '3';  # Sort column

  # add 'ViewBidItems' to URL
  my $sUrl = $self->SUPER::native_setup_search('', $rh);
  $sUrl =~ s!\?!?ViewBidItems&!;

  return $self->{_next_url} = $sUrl;
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
  # This is for BidItems:
  return qw( item start end price title high_bidder seller );
  } # columns

my $qrTitle = qr{\AeBay.+Bidder List:\s+(\w+)}; #

# The Bidder List is formatted using simple <table> without
# styles. So we use <th> and <td> for positioning.
sub _result_td_spec
  {
  return (
          '_tag' => 'td',
         );
  } # _result_td_spec

sub _result_th_spec
  {
  return (
          '_tag' => 'th',
         );
  } # _result_th_spec

sub parse_tree
  {
  my $self = shift;
  my $tree = shift;
  my $sBidder = '';

  # Parse title to get the bidder id
  my $sTitle = $self->{response}->header('title') || '';
  if ($sTitle =~ m!$qrTitle!)
    {
    $sBidder = $1;
    } # if

  # The hit count is in a <td> tag:
  $self->approximate_result_count(0);
  my @aoTD = $tree->look_down($self->_result_td_spec);
 COUNT:
  foreach my $oTD (@aoTD)
    {
    print STDERR " +   try CNT ===", $oTD->as_text, "===\n" if (1 < $self->{_debug});
    if ($oTD->as_text =~ m!of (\d+) total!)
      {
      $self->approximate_result_count($1);
      last COUNT;
      } # if
    } # foreach

  # have something ?
  if (0 < $self->approximate_result_count)
    {
    # find <th> for title row
    my @aoTH = $tree->look_down($self->_result_th_spec);
    my $oTable;
 START:
    foreach my $oTH (@aoTH)
      {
      print STDERR " +   try TH ===", $oTH->as_text, "===\n" if (1 < $self->{_debug}); 
      if ($oTH->as_text =~ m!Item!)
        {
        # parent->parent is <table>
        $oTable = $oTH->parent->parent;
        last START;
        } # if
      } # foreach
    # get <td> in the table
    @aoTD = $oTable->look_down($self->_result_td_spec);
 TD:
    foreach my $oTD (@aoTD)
      {
      # Sanity check:
      next TD unless ref($oTD);
      my $sTD = $oTD->as_HTML;
      print STDERR " DDD raw TD ==$sTD==\n" if (1 < $self->{_debug});
      # Skip if this is not an item number
      my $iItem = $oTD->as_text;
      next TD if ($iItem !~ m!\A\d{10}\Z!);
      print STDERR " DDD good item ==$iItem==\n" if (1 < $self->{_debug});
      # The rest of the info about this item is in sister TD elements to
      # the right:
      my @asColumns = $self->columns;
      my @aoSibs = $oTD->right;
      my $hit = new WWW::Search::Result;
      my $iCol = 1; # start at 1 - item# is handled below
 SIBLING_TD:
      while ((my $oTDsib = shift(@aoSibs)) && (my $sColumn = $asColumns[$iCol++]))
        {
        switch ($sColumn)
          {
          case 'start'       { $hit->start_date($self->parse_date($oTDsib)) }
          case 'end'         { $hit->end_date($self->parse_date($oTDsib)) }
          case 'price'       { $self->parse_price($oTDsib, $hit) }
          case 'title'       { $hit->title($oTDsib->as_text) }
          case 'high_bidder' { $hit->bidder($oTDsib->as_text) }
          case 'seller'      { $hit->seller($oTDsib->as_text) }
          else               { next SIBLING_TD }
          } # switch
        } # while
      $hit->item_number($iItem);
      my $oURL = $self->{response}->request->uri;
      $oURL->query(qq{ViewItem&item=$iItem});
      $hit->add_url("$oURL");
      # print STDERR Dumper($hit);
      push @{$self->{cache}}, $hit;
      $self->{'_num_hits'}++;
      $hits_found++;
      # Delete this HTML element so that future searches go faster?
      $oTD->detach;
      $oTD->delete;
      } # foreach TD

    # Look for a NEXT link: >>
    my @aoA = $tree->look_down('_tag', 'a');
 TRY_NEXT:
    foreach my $oA (0, reverse @aoA)
      {
      next TRY_NEXT unless ref $oA;
      print STDERR " +   try NEXT A ===", $oA->as_HTML, "===\n" if (1 < $self->{_debug});
      my $href = $oA->attr('href');
      next TRY_NEXT unless $href;
      # If we get all the way to the item list, there must be no next
      # button:
      last TRY_NEXT if ($href =~ m!ViewItem!);
      if ($oA->as_text eq '>>')
        {
        print STDERR " +   got NEXT A ===", $oA->as_HTML, "===\n" if 1 < $self->{_debug};
        $self->{_next_url} = $self->absurl($self->{_prev_url}, $href);
        last TRY_NEXT;
        } # if
      } # foreach
    } # if
  $tree->delete;
  return $hits_found;
  } # parse_tree

# A pattern to match HTML whitespace:
our $W = q{[\ \t\r\n\240]};

sub parse_price
  {
  my $currency = qr/(?:\$|C|EUR|GBP|\�|CHF|\�|AUD|AU)/;
  
  my $self = shift;
  my $oTDprice = shift;
  my $hit = shift;
  return 0 unless (ref $oTDprice);
  my $s = $oTDprice->as_HTML;
  my $iPrice = $oTDprice->as_text;

  $iPrice =~ s!&pound;!GBP!;
  $iPrice =~ s!(\d)$W*($currency$W*[\d.,]+)!$1 (Buy-It-Now for $2)!;
  $hit->bid_amount($iPrice);
  # $hit->price($iPrice);
  return 1;
  } # parse_price

sub parse_date
  {
  my $self = shift;
  my $oTDdate = shift;
  my $hit = shift;
  my $sDate = 'unknown';
  if (! ref $oTDdate)
    {
    return $sDate;
    }
  my $s = $oTDdate->as_HTML;
  print STDERR " +   TDdate ===$s===\n" if 1 < $self->{_debug};
  my $sDateTemp = $oTDdate->as_text;
  # Convert nbsp to regular space:
  $sDateTemp =~ s!\240!\040!g;
  print STDERR " +   raw    sDateTemp ===$sDateTemp===\n" if 1 < $self->{_debug};
  return $sDateTemp;
  } # parse_date

1;

__END__

