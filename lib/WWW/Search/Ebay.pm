# Ebay.pm
# by Martin Thurn
# $Id: Ebay.pm,v 2.175 2005/08/18 04:55:09 Daddy Exp $

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

In the resulting L<WWW::Search::Result> objects, the change_date field
contains a human-readable DTG of when the auction is scheduled to end
(in the form "YYYY-MM-DD HH:MM:SS TZ").  If environment variable TZ is
set, the time will be converted to that timezone; otherwise the time
will be left in ebay.com's default timezone (US/Pacific).

In the resulting L<WWW::Search::Result> objects, the bid_count field
contains the number of bids as an integer.

In the resulting L<WWW::Search::Result> objects, the bid_amount field is
a string containing the high bid or starting bid as a human-readable
monetary value in seller-native units, e.g. "$14.95" or "GBP 6.00".

If your query string happens to be an eBay item number,
(i.e. if ebay.com redirects the query to an auction page),
you will get back one WWW::Search::Result without bid or price information.

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
use Data::Dumper;  # for debugging only
use Date::Manip;
&Date_Init('TZ=US/Pacific') unless (defined($ENV{TZ}) && ($ENV{TZ} ne ''));
use HTML::TreeBuilder;
use LWP::Simple;
use Switch;
use WWW::Search qw( generic_option strip_tags );
# We need the version that has bid_amount() and bid_count() methods:
use WWW::SearchResult 2.063;
use WWW::Search::Result;

use strict;
our
$VERSION = do { my @r = (q$Revision: 2.175 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
my $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

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

  $self->{search_host} ||= 'http://search.ebay.com';
  $self->{search_path} ||= '/ws/search/SaleSearch';
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
                         'sotimedisplay' => 0,
                         # Use the default columns, NOT anything the
                         # user may have customized (which would come
                         # through via cookies):
                         'socustoverride' => 1,
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


my $qrTitle = qr{\AeBay:\s.+\(item\s+(\d+)\s+end\s+time\s+([^)]+)\)\Z}; #

sub preprocess_results_page
  {
  my $self = shift;
  my $sPage = shift;
  if (0)
    {
    # print STDERR Dumper($self->{response});
    # For debugging:
    print STDERR $sPage;
    exit 88;
    } # if
  my $sTitle = $self->{response}->header('title') || '';
  if ($sTitle =~ m!$qrTitle!)
    {
    # print STDERR " DDD got a Title: ==$sTitle==\n";
    # This search returned a single auction item page.  We do not need
    # to fetch eBay official time.
    } # if
  else
    {
    # Fetch the official ebay.com time:
    $self->{_ebay_official_time} = 'now';
    my $sPageDate = get('http://cgi1.ebay.com/aw-cgi/eBayISAPI.dll?TimeShow') || '';
    if ($sPageDate ne '')
      {
      my $tree = HTML::TreeBuilder->new;
      $tree->parse($sPageDate);
      $tree->eof;
      my $s = $tree->as_text;
      # print STDERR " DDD official time =====$s=====\n";
      if ($s =~ m!The official eBay Time is now:(.+?)Pacific\s!i)
        {
        # ParseDate automatically converts to local timezone:
        my $date = &ParseDate($1);
        # print STDERR " DDD official time =====$date=====\n";
        $self->{_ebay_official_time} = $date;
        } # if
      } # if
    } # else
  return $sPage;
  # Ebay used to send malformed HTML:
  # my $iSubs = 0 + ($sPage =~ s!</FONT></TD></FONT></TD>!</FONT></TD>!gi);
  # print STDERR " +   deleted $iSubs extraneous tags\n" if 1 < $self->{_debug};
  } # preprocess_results_page


sub currency_pattern
  {
  # A pattern to match all possible currencies found in eBay listings:
  return qr/(?:\$|C|EUR|GBP)/;
  } # currency_pattern

sub _cleanup_url
  {
  my $self = shift;
  my $sURL = shift || '';
  # Make sure we don't return two different URLs for the same item:
  $sURL =~ s!&rd=\d+!!;
  $sURL =~ s!&category=\d+!!;
  $sURL =~ s!&ssPageName=[A-Z0-9]+!!;
  return $sURL;
  } # _cleanup_url

sub _format_date
  {
  my $self = shift;
  &UnixDate(shift, '%Y-%m-%d %H:%M %Z');
  } # _format_date

sub _create_description
  {
  my $self = shift;
  my $iItem = shift || 'unknown';
  my $iBids = shift || 'no';
  my $iPrice = shift || 'unknown';
  my $sWhen = shift || 'current';
  # print STDERR " DDD _c_d($iItem, $iBids, $iPrice, $sWhen)\n";
  my $sDesc = "Item \043$iItem; $iBids bid";
  $sDesc .= 's' if $iBids ne '1';
  $sDesc .= '; ';
  $sDesc .= 'no' ne $iBids ? $sWhen : 'starting';
  $sDesc .= " bid $iPrice";
  return $sDesc;
  } # _create_description

# This is what we look_down for to find the HTML element that contains
# the result count:
sub _result_count_td_specs
  {
  return (
          '_tag' => 'div',
          class => 'count'
         );
  } # _result_count_td_specs

# This is what we look_down for to find the <TD> that contain auction
# titles:
sub _title_td_specs
  {
  return (
          '_tag' => 'td',
          'class' => 'ebcTtl',
         );
  } # _title_td_specs


sub columns
  {
  my $self = shift;
  # This is for basic USA eBay:
  return qw( paypal price bids enddate );
  } # columns

sub parse_tree
  {
  my $self = shift;
  my $tree = shift;

  my $sTitle = $self->{response}->header('title') || '';
  if ($sTitle =~ m!$qrTitle!)
    {
    my $hit = new WWW::Search::Result;
    $hit->description($self->_create_description($1));
    $hit->change_date($self->_format_date($2));
    $hit->title($3);
    $hit->add_url($self->{response}->request->uri);
    # print Dumper($hit);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $self->approximate_result_count(1);
    return 1;
    } # if
  my $hits_found = 0;
  # The hit count is in a FONT tag:
  my @aoFONT = $tree->look_down($self->_result_count_td_specs);
 FONT:
  foreach my $oFONT (@aoFONT)
    {
    print STDERR " +   try FONT ===", $oFONT->as_text, "===\n" if (1 < $self->{_debug});
    if ($oFONT->as_text =~ m!(\d+) items found !)
      {
      $self->approximate_result_count($1);
      last FONT;
      } # if
    } # foreach

  # See if our query was completely replaced by a similar-spelling query:
  my $oLI = $tree->look_down(_tag => 'li',
                             class => 'ebInf',
                            );
  if (ref $oLI)
    {
    if ($oLI->as_text =~ m! keyword has been replaced !)
      {
      $self->approximate_result_count(0);
      return 0;
      } # if
    } # if
  # First, delete all the results that came from spelling variations:
  my $oDiv = $tree->look_down(_tag => 'div',
                              id => 'expSplChk',
                             );
  if (ref $oDiv)
    {
    # print STDERR " DDD found a spell-check ===", $oDiv->as_text, "===\n";
    $oDiv->detach;
    $oDiv->delete;
    } # if
  # The list of matching items is in a table.  The first column of the
  # table is nothing but icons; the second column is the good stuff.
  my @a = $self->_title_td_specs;
  # print STDERR Dumper(\@a);
  # exit 88;
  my @aoTD = $tree->look_down(@a);
  unless (@aoTD)
    {
    print STDERR " --- did not find table of results\n" if $self->{_debug};
    } # unless
  my $qrItemNum = qr{[;Q]item[=Z](\d+)[;Q]};
 TD:
  foreach my $oTDtitle (0, @aoTD)
    {
    # Sanity check:
    next TD unless ref $oTDtitle;
    my $sTDtitle = $oTDtitle->as_HTML;
    print STDERR " + try TDtitle ===$sTDtitle===\n" if (1 < $self->{_debug});
    # First A tag contains the url & title:
    my $oA = $oTDtitle->look_down('_tag', 'a');
    next TD unless ref $oA;
    # This is needed for Ebay::UK to make sure we're looking at the right TD:
    my $sTitle = $oA->as_text || '';
    next TD if ($sTitle eq '');
    print STDERR " +   sTitle ===$sTitle===\n" if (1 < $self->{_debug});
    my $oURI = URI->new($oA->attr('href'));
    next TD unless ($oURI =~ m!ViewItem!);
    next TD unless ($oURI =~ m!$qrItemNum!);
    my $iItemNum = $1;
    print STDERR " +   iItemNum ===$iItemNum===\n" if (1 < $self->{_debug});
    if ($oURI->as_string =~ m!QQitemZ(\d+)QQ!)
      {
      # Convert new eBay links to old reliable ones:
      # $oURI->path('');
      $oURI->path('/ws/eBayISAPI.dll');
      $oURI->query("ViewItem&item=$1");
      } # if
    my $sURL = $oURI->as_string;
    my $hit = new WWW::Search::Result;
    $hit->add_url($self->_cleanup_url($sURL));
    $hit->title($sTitle);
    # The rest of the info about this item is in sister TD elements to
    # the right:
    my @aoSibs = $oTDtitle->right;
    my @asColumns = $self->columns;
 SIBLING_TD:
    while ((my $oTDsib = shift(@aoSibs))
           &&
           (my $sColumn = shift(@asColumns))
          )
      {
      switch ($sColumn)
        {
        case 'price'    { next TD unless $self->parse_price($oTDsib, $hit) }
        case 'bids'     { next TD unless $self->parse_bids($oTDsib, $hit) }
        case 'shipping' { next TD unless $self->parse_shipping($oTDsib, $hit) }
        case 'enddate'  { next TD unless $self->parse_enddate($oTDsib, $hit) }
        else            { next SIBLING_TD }
        } # switch
      } # while
    my $sDesc = $self->_create_description($iItemNum,
                                           $hit->bid_count,
                                           $hit->bid_amount);
    $hit->description($sDesc);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    # Delete this HTML element so that future searches go faster?
    $oTDtitle->detach;
    $oTDtitle->delete;
    } # foreach TD

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

# A pattern to match HTML whitespace:
our $W = q{[\ \t\r\n\240]};

sub parse_price
  {
  my $self = shift;
  my $oTDprice = shift;
  my $hit = shift;
  return 0 unless (ref $oTDprice);
  my $s = $oTDprice->as_HTML;
  if (1 < $self->{_debug})
    {
    print STDERR " +   try TDprice ===$s===\n";
    } # if
  if ($s =~ m!\sclass="ebcTim"!)
    {
    # If we see this, we probably were searching for Store items
    # but we ran off the bottom of the Store item list and ran
    # into the list of Auction items.
    return 0;
    # There is a separate backend for searching Auction items!
    } # if
  if ($s =~ m!class="ebcBid"!)
    {
    # If we see this, we must have been searching for Stores items
    # but we ran off the bottom of the Stores item list and ran
    # into the list of "other" items.
    return 1;
    # We could probably return 0 to abandon the rest of the page, but
    # maybe just maybe we hit this because of a parsing glitch which
    # might correct itself on the next TD.
    } # if
  if ($s =~ m!class="ebcStr"!)
    {
    # If we see this, we must have been searching for Buy-It-Now items
    # but we ran off the bottom of the time-limit item list and ran
    # into the list of permanent Store items.
    return 0;
    # There is a separate backend for searching Stores items!
    } # if
  my $iPrice = $oTDprice->as_text;
  print STDERR " +   raw iPrice ===$iPrice===\n" if (1 < $self->{_debug});
  my $currency = $self->currency_pattern;
  $iPrice =~ s!(\d)$W*($currency$W*[\d.,]+)!$1 (Buy-It-Now for $2)!;
  $hit->bid_amount($iPrice);
  return 1;
  } # parse_price

sub parse_bids
  {
  my $self = shift;
  my $oTDbids = shift;
  my $hit = shift;
  my $iBids = 0;
  if (ref $oTDbids)
    {
    my $s = $oTDbids->as_HTML;
    if (1 < $self->{_debug})
      {
      print STDERR " +   TDbids ===$s===\n";
      } # if
    if ($s =~ m!\sclass="ebcTim"!)
      {
      # If we see this, we probably were searching for Store items
      # but we ran off the bottom of the Store item list and ran
      # into the list of Auction items.
      return 0;
      # There is a separate backend for searching Auction items!
      } # if
    $iBids = $oTDbids->as_text;
    if (
        # Bid listed as hyphen means no bids:
        ($iBids =~ m!\A$W*-$W*\Z!)
        ||
        # Bid listed as whitespace means no bids:
        ($iBids =~ m!\A$W*\Z!)
       )
      {
      $iBids = 0;
      } # if
    } # if
  $hit->bid_count($iBids);
  return 1;
  } # parse_bids

sub parse_shipping
  {
  my $self = shift;
  my $oTD = shift;
  my $hit = shift;
  return 1;
  } # parse_shipping

sub parse_skip
  {
  my $self = shift;
  my $oTD = shift;
  my $hit = shift;
  return 1;
  } # parse_skip

sub parse_enddate
  {
  my $self = shift;
  my $oTDdate = shift;
  my $hit = shift;
  my $sDate = 'unknown';
  if (! ref $oTDdate)
    {
    return 0;
    }
  my $s = $oTDdate->as_HTML;
  print STDERR " +   TDdate ===$s===\n" if 1 < $self->{_debug};
  my $sDateTemp = $oTDdate->as_text;
  # Convert nbsp to regular space:
  $sDateTemp =~ s!\240!\040!g;
  print STDERR " +   raw    sDateTemp ===$sDateTemp===\n" if 1 < $self->{_debug};
  $sDateTemp =~ s!<!!;
  $sDateTemp =~ s!d! days!;
  $sDateTemp =~ s!h! hours!;
  $sDateTemp =~ s!m! minutes!;
  print STDERR " +   cooked sDateTemp ===$sDateTemp===\n" if 1 < $self->{_debug};
  my $date = &DateCalc($self->{_ebay_official_time}, "+ $sDateTemp");
  print STDERR " +   date ===$date===\n" if 1 < $self->{_debug};
  $sDate = $self->_format_date($date);
  $hit->change_date($sDate);
  return 1;
  } # parse_enddate

1;

__END__

