# Ebay.pm
# by Martin Thurn
# $Id: Ebay.pm,v 2.144 2004/06/06 02:55:44 Daddy Exp Daddy $

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

This class is a Ebay specialization of WWW::Search.
It handles making and interpreting Ebay searches
F<http://www.ebay.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

The search is done against CURRENT running AUCTIONS only.
(NOT complete auctions, NOT eBay Stores items, NOT Buy-It-Now only items.)
(If you want to search eBay Stores, use the WWW::Search::Ebay::Stores module.)

The query is applied to TITLES only.

The results are ordered youngest auctions first (reverse order of
auction listing date).

In the resulting WWW::Search::Result objects, the description field
consists of a human-readable combination (joined with semicolon-space)
of the Item Number; number of bids; and high bid amount (or starting
bid amount).

=head1 OPTIONS

=over

=item Search descriptions

To search titles and descriptions, add 'srchdesc' => 'y' to the query options:

  $oSearch->native_query($sQuery, { srchdesc => 'y' } );

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 CAVEATS

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::Ebay> was written by Martin Thurn
(mthurn@cpan.org).

C<WWW::Search::Ebay> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::Ebay;

@ISA = qw( WWW::Search );

use Carp ();
use Data::Dumper;  # for debugging only
use WWW::Search qw( generic_option strip_tags );
use WWW::Search::Result;

$VERSION = do { my @r = (q$Revision: 2.144 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
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
                              'width' => '12%',
                              sub { ($_[0]->as_text =~ m!\A\d{9,}\Z! ) }
                             );
 TD:
  foreach my $oTD (@aoTD)
    {
    # Sanity check:
    next TD unless ref $oTD;
    my $iItemNum = $oTD->as_text;
    my $sTD = $oTD->as_HTML;
    print STDERR " + try TD ===$sTD===\n" if 1 < $self->{_debug};
    $oTD = $oTD->right;
    # First A tag contains the url & title:
    my $oA = $oTD->look_down('_tag', 'a');
    next TD unless ref $oA;
    my $sURL = $oA->attr('href');
    next TD unless $sURL =~ m!ViewItem!;
    my $sTitle = $oA->as_text;
    my ($iPrice, $iBids, $sDate) = ('$unknown', 'no', 'unknown');
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
    # The next sister has the number of bids:
    my $oTDbids = shift @aoSibs;
    if (ref $oTDbids)
      {
      if (1 < $self->{_debug})
        {
        my $s = $oTDbids->as_HTML;
        print STDERR " +   TDbids ===$s===\n";
        } # if
      $iBids = $oTDbids->as_text;
      } # if
    # Bid listed as hyphen means no bids:
    $iBids = 'no' if $iBids =~ m!\A$W*-$W*\Z!;
    # Bid listed as whitespace means no bids:
    $iBids = 'no' if $iBids =~ m!\A$W*\Z!;
    my $sDesc = "Item \043$iItemNum; $iBids bid";
    $sDesc .= 's' if $iBids ne '1';
    $sDesc .= '; ';
    $sDesc .= 'no' ne $iBids ? 'current' : 'starting';
    $sDesc .= " bid $iPrice";
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

