
# $Id: Stores.pm,v 1.1 2004/06/06 02:54:13 Daddy Exp $

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

C<WWW::Search::Ebay::Stores> was written by Martin Thurn
(mthurn@cpan.org).

=cut

package WWW::Search::Ebay::Stores;

use WWW::Search::Ebay;
use vars qw( @ISA $VERSION );
@ISA = qw( WWW::Search::Ebay );
$VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  # http://search.stores.ebay.com/ws/search/StoreItemSearch?from=R10&sasaleclass=2&satitle=star+wars+lego&sbrexp=WD1S&sbrhrlink=str&sif=1&socolumnlayout=3&sofp=4&sosortorder=1&sosortproperty=1
  # http://search.stores.ebay.com/search/search.dll?GetResult&satitle=star+wars+lego&sosortorder=2&sosortproperty=2
  # http://search.stores.ebay.com/ws/search/StoreItemSearch?sasaleclass=2&satitle=dupondius
  # As of 2004-10-20:
  # http://search.stores.ebay.com/search/search.dll?sofocus=bs&sbrftog=1&catref=C6&socurrencydisplay=1&from=R10&sasaleclass=1&sorecordsperpage=100&sotimedisplay=1&socolumnlayout=2&satitle=star+wars+lego&sacategory=-6%26catref%3DC6&bs=Search&sofp=4&sotr=2&sapricelo=&sapricehi=&searchfilters=&sosortproperty=1&sosortorder=1
  # simplest = http://search.stores.ebay.com/search/search.dll?socurrencydisplay=1&sasaleclass=1&sorecordsperpage=100&sotimedisplay=1&socolumnlayout=2&satitle=star+wars+lego
  $self->{'_options'} = {
                         'satitle' => $sQuery,
                         'sucurrencydisplay' => 1,
                         'sarecordsperpage' => 100,
                         'sasaleclass' => 1,
                         'sosortproperty' => 2,
                         'sosortorder' => 2,
                         'sotimedisplay' => 1,
                         # Display item number explicitly:
                         'socolumnlayout' => 2,
                        };
  $rh->{'search_host'} = 'http://search.stores.ebay.com';
  $rh->{'search_path'} = '/search/search.dll';
  return $self->SUPER::native_setup_search($sQuery, $rh);
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


sub parse_tree_OFF
  {
  my $self = shift;
  my $tree = shift;

  # A pattern to match HTML whitespace:
  my $W = q{[\ \t\r\n\240]};
  my $hits_found = 0;
  # The hit count is in a TD tag:
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
                              'width' => '12%',
                              sub { ($_[0]->as_text =~ m!\A\d{9,}\Z! ) }
                             );
 TD:
  foreach my $oTD (@aoTD)
    {
    # Sanity check:
    next TD unless ref $oTD;
    my $sTD = $oTD->as_HTML;
    $oTD = $oTD->right;
    next TD unless ref $oTD;
    print STDERR " + try TD ===$sTD===\n" if 1 < $self->{_debug};
    # First A tag contains the url & title:
    my $oA = $oTD->look_down('_tag', 'a');
    next TD unless ref $oA;
    my $sURL = $oA->attr('href');
    next TD unless $sURL =~ m!ViewItem!;
    my $iItemNum = 0;
    $iItemNum = $1 if ($sURL =~ m!item=(\d+)!);
    next TD unless ($iItemNum != 0);
    my $sTitle = $oA->as_text;
    my ($iPrice, $iBids, $sDate) = ('$unknown', 'Buy-It-Now', 'unknown');
    # The rest of the info about this item is in sister TD elements to
    # the right:
    my @aoSibs = $oTD->right;
    # The next sister has the current bid amount (or starting bid):
    my $oTDprice = shift @aoSibs;
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
    # The next sister has the "Buy-It-Now" icon:
    my $oTDbids = shift @aoSibs;
    my $sDesc = "Item \043$iItemNum; Buy-It-Now for $iPrice";
    # The last sister has the auction start date:
    my $oTDdate = pop @aoSibs;
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
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    # Delete this HTML element so that future searches go faster!
    $oTD->detach;
    $oTD->delete;
    } # foreach

  # Look for a NEXT link:
  my @aoA = $tree->look_down('_tag', 'a');
 TRY_NEXT:
  foreach my $oA (reverse @aoA)
    {
    next TRY_NEXT unless ref $oA;
    print STDERR " +   try NEXT A ===", $oA->as_HTML, "===\n" if 1 < $self->{_debug};
    my $href = $oA->attr('href');
    next TRY_NEXT unless $href;
    # If we get all the way to the item list, there must be no next
    # button:
    last TRY_NEXT if $href =~ m!ViewItem!;
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
