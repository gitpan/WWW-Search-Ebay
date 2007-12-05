
# $Id: Ebay.pm,v 2.206 2007/12/05 19:13:28 Daddy Exp $

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

In the resulting L<WWW::Search::Result> objects, the description()
field consists of a human-readable combination (joined with
semicolon-space) of the Item Number; number of bids; and high bid
amount (or starting bid amount).

In the resulting L<WWW::Search::Result> objects, the end_date() field
contains a human-readable DTG of when the auction is scheduled to end
(in the form "YYYY-MM-DD HH:MM TZ").  If environment variable TZ is
set, the time will be converted to that timezone; otherwise the time
will be left in ebay.com's default timezone (US/Pacific).

In the resulting L<WWW::Search::Result> objects, the bid_count() field
contains the number of bids as an integer.

In the resulting L<WWW::Search::Result> objects, the bid_amount()
field is a string containing the high bid or starting bid as a
human-readable monetary value in seller-native units, e.g. "$14.95" or
"GBP 6.00".

In the resulting L<WWW::Search::Result> objects, the category() field
contains the Ebay category number.

In the resulting L<WWW::Search::Result> objects, the sold() field will
be non-zero if the item has already sold.  (Only if you're using
WWW::Search::Ebay::Completed)

After a successful search, your search object will contain an element
named 'categories' which will be a reference to an array of hashes
containing names and IDs of categories and nested subcategories, and
the count of items matching your query in each category and
subcategory.  (Special thanks to Nick Lokkju for this code!)  For
example:

  $oSearch->{category} = [
          {
            'ID' => '1',
            'Count' => 19,
            'Name' => 'Collectibles',
            'Subcategory' => [
                               {
                                 'ID' => '13877',
                                 'Count' => 11,
                                 'Name' => 'Historical Memorabilia'
                               },
                               {
                                 'ID' => '11450',
                                 'Count' => 1,
                                 'Name' => 'Clothing, Shoes & Accessories'
                               },
                             ]
          },
          {
            'ID' => '281',
            'Count' => 1,
            'Name' => 'Jewelry & Watches',
          }
        ];

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

=head1 PUBLIC METHODS OF NOTE

=over

=cut

#####################################################################

package WWW::Search::Ebay;

use strict;

use base 'WWW::Search';

use constant DEBUG_DATES => 0;

use Carp ();
use CGI;
use Data::Dumper;  # for debugging only
use Date::Manip;
&Date_Init('TZ=US/Pacific') unless (defined($ENV{TZ}) && ($ENV{TZ} ne ''));
use HTML::TreeBuilder;
use LWP::Simple;
use WWW::Search qw( generic_option strip_tags );
# We need the version that has the sold() method:
use WWW::SearchResult 2.072;
use WWW::Search::Result;

our
$VERSION = do { my @r = (q$Revision: 2.206 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';
my $cgi = new CGI;

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
  $self->agent_name('Mozilla/5.0 (compatible; Mozilla/4.0; MSIE 6.0; Windows NT 5.1; Q312461)');

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
      # print STDERR " DDD   inspecting option $key...";
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
  # Clear the list of results per category:
  $self->{categories} = [];
  # Finally, figure out the url.
  $self->{_next_url} = $self->{'search_host'} . $self->{'search_path'} .'?'. $self->hash_to_cgi_string($self->{_options});
  } # native_setup_search


my $qrTitle = qr{\A(.+?)\s+-\s+\(EBAY\s+ITEM\s+(\d+)\s+END\s+TIME\s+([^)]+)\)\Z}i; #

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
      if ($s =~ m!The official eBay Time is now:(.+?(P[SD]T))\s*Pacific\s!i)
        {
        my ($sDateRaw, $sTZ) = ($1, $2);
        DEBUG_DATES && print STDERR " DDD official time raw     ==$sDateRaw==\n";
        # Apparently, ParseDate() automatically converts to local timezone:
        my $date = &ParseDate($sDateRaw);
        DEBUG_DATES && print STDERR " DDD official time cooked  ==$date==\n";
        $self->{_ebay_official_time} = $date;
        } # if
      } # if
    } # else
  return $sPage;
  # Ebay used to send malformed HTML:
  # my $iSubs = 0 + ($sPage =~ s!</FONT></TD></FONT></TD>!</FONT></TD>!gi);
  # print STDERR " DDD   deleted $iSubs extraneous tags\n" if 1 < $self->{_debug};
  } # preprocess_results_page

sub whitespace_pattern
  {
  # A pattern to match HTML whitespace:
  return qr{[\ \t\r\n\240]};
  } # whitespace_pattern 

sub currency_pattern
  {
  my $self = shift;
  # A pattern to match all possible currencies found in USA eBay
  # listings:
  my $W = $self->whitespace_pattern;
  return qr/(?:\$|C|EUR|GBP)$W*[0-9.,]+/;
  } # currency_pattern

sub _cleanup_url
  {
  my $self = shift;
  my $sURL = shift() || '';
  # Make sure we don't return two different URLs for the same item:
  $sURL =~ s!&rd=\d+!!;
  $sURL =~ s!&category=\d+!!;
  $sURL =~ s!&ssPageName=[A-Z0-9]+!!;
  return $sURL;
  } # _cleanup_url

sub _format_date
  {
  my $self = shift;
  return &UnixDate(shift, '%Y-%m-%d %H:%M %Z');
  } # _format_date

sub _bidcount_as_text
  {
  my $self = shift;
  my $hit = shift;
  my $iBids = $hit->bid_count || 'no';
  my $s = "$iBids bid";
  $s .= 's' if ($iBids ne '1');
  $s .= '; ';
  } # _bidcount_as_text

sub _bidamount_as_text
  {
  my $self = shift;
  my $hit = shift;
  my $iPrice = $hit->bid_amount || 'unknown';
  my $sDesc = '';
  $sDesc .= $hit->bid_count ? 'current' : 'starting';
  $sDesc .= " bid $iPrice";
  } # _bidamount_as_text

sub _create_description
  {
  my $self = shift;
  my $hit = shift;
  my $iItem = $hit->item_number || 'unknown';
  my $sWhen = shift() || 'current';
  # print STDERR " DDD _c_d($iItem, $iBids, $iPrice, $sWhen)\n";
  my $sDesc = "Item \043$iItem; ". $self->_bidcount_as_text($hit);
  $sDesc .= $self->_bidamount_as_text($hit);
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


sub _result_count_regex
  {
  return qr'(\d+) items? found ';
  } # _result_count_regex

sub columns
  {
  my $self = shift;
  # This is for basic USA eBay:
  return qw( paypal bids price shipping enddate );
  } # columns

sub parse_tree
  {
  my $self = shift;
  my $tree = shift;

  my $sTitle = $self->{response}->header('title') || '';
  if ($sTitle =~ m!$qrTitle!)
    {
    my ($sTitle, $iItem, $sDateRaw) = ($1, $2, $3);
    my $sDateCooked = $self->_format_date($sDateRaw);
    my $hit = new WWW::Search::Result;
    $hit->item_number($iItem);
    $hit->end_date($sDateCooked);
    # For backward-compatibility:
    $hit->change_date($sDateCooked);
    $hit->title($sTitle);
    $hit->add_url($self->{response}->request->uri);
    $hit->description($self->_create_description($hit));
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
    print STDERR " DDD   try FONT ===", $oFONT->as_text, "===\n" if (1 < $self->{_debug});
    my $qr = $self->_result_count_regex;
    if ($oFONT->as_text =~ m!$qr!)
      {
      $self->approximate_result_count($1);
      last FONT;
      } # if
    } # foreach

  # Recursively parse the stats telling how many items were found in
  # each category:
  my $oUL = $tree->look_down(_tag => 'ul',
                             class => 'categories');
  $self->{categories} ||= [];
  $self->_parse_category_list($oUL, $self->{categories}) if ref($oUL);

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
  # By default, use the hard-coded order of columns:
  my @asColumns = $self->columns;
  if (ref($self) !~ m!::Completed!)
    {
    # See if we can glean the actual order of columns from the page itself:
    my @aoCOL = $tree->look_down(_tag => 'col');
    my @asId;
    foreach my $oCOL (@aoCOL)
      {
      # Sanity check:
      next unless ref($oCOL);
      my $sId = $oCOL->attr('id') || '';
      # Sanity check:
      next unless ($sId ne '');
      $sId =~ s!\Aebc!!;
      # Try not to go past the first table:
      last if ($sId eq 'bdrRt');
      push @asId, $sId;
      } # foreach
    print STDERR " DDD raw    asId is (@asId)\n" if (1 < $self->{_debug});
    1 while (@asId && (shift(@asId) ne 'title'));
    local $" = ',';
    print STDERR " DDD cooked asId is (@asId)\n" if (1 < $self->{_debug});
    @asColumns = @asId if @asId;
    } # if
  print STDERR " DDD   asColumns is (@asColumns)\n" if (1 < $self->{_debug});
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
    print STDERR " DDD try TDtitle ===$sTDtitle===\n" if (1 < $self->{_debug});
    # First A tag contains the url & title:
    my $oA = $oTDtitle->look_down('_tag', 'a');
    next TD unless ref $oA;
    # This is needed for Ebay::UK to make sure we're looking at the right TD:
    my $sTitle = $oA->as_text || '';
    next TD if ($sTitle eq '');
    print STDERR " DDD   sTitle ===$sTitle===\n" if (1 < $self->{_debug});
    my $oURI = URI->new($oA->attr('href'));
    next TD unless ($oURI =~ m!ViewItem!);
    next TD unless ($oURI =~ m!$qrItemNum!);
    my $iItemNum = $1;
    my $iCategory = 'unknown';
    $iCategory = $1 if ($oURI =~ m!QQcategoryZ(\d+)QQ!);
    print STDERR " DDD   iItemNum ===$iItemNum===\n" if (1 < $self->{_debug});
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
    $hit->category($iCategory);
    $hit->item_number($iItemNum);
    # The rest of the info about this item is in sister TD elements to
    # the right:
    my @aoSibs = $oTDtitle->right;
    # But in the Completed auctions list, the rest of the info is in
    # the next row of the table:
    if (ref($self) =~ m!::Completed!)
      {
      @aoSibs = $oTDtitle->parent->right->look_down(_tag => 'td');
      # Throw out one empty cell:
      shift @aoSibs;
      } # if
    my $iCol = 0;
 SIBLING_TD:
    while ((my $oTDsib = shift(@aoSibs))
           &&
           (my $sColumn = $asColumns[$iCol++])
          )
      {
      next unless ref($oTDsib);
      my $s = $oTDsib->as_HTML;
      print STDERR " DDD   try TD$sColumn ===$s===\n" if (1 < $self->{_debug});
      if ($sColumn eq 'price')
        {
        next TD unless $self->parse_price($oTDsib, $hit);
        }
      elsif ($sColumn eq 'bids')
        {
        next TD unless $self->parse_bids($oTDsib, $hit);
        }
      elsif ($sColumn eq 'shipping')
        {
        next TD unless $self->parse_shipping($oTDsib, $hit);
        }
      elsif ($sColumn eq 'enddate')
        {
        next TD unless $self->parse_enddate($oTDsib, $hit);
        }
      elsif ($sColumn eq 'time')
        {
        next TD unless $self->parse_enddate($oTDsib, $hit);
        }
      elsif ($sColumn eq 'country')
        {
        # This listing is from a country other than the base site
        # we're searching against.  Throw it out:
        next TD;
        }
      else
        {
        print STDERR " DDD     do not know how to handle column named $sColumn\n" if (1 < $self->{_debug});
        next SIBLING_TD;
        }
      } # while
    my $sDesc = $self->_create_description($hit);
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
    print STDERR " DDD   try NEXT A ===", $oA->as_HTML, "===\n" if (1 < $self->{_debug});
    my $href = $oA->attr('href');
    next TRY_NEXT unless $href;
    # If we get all the way to the item list, there must be no next
    # button:
    last TRY_NEXT if ($href =~ m!ViewItem!);
    if ($oA->as_text eq $self->_next_text)
      {
      print STDERR " DDD   got NEXT A ===", $oA->as_HTML, "===\n" if 1 < $self->{_debug};
      $self->{_next_url} = $self->absurl($self->{_prev_url}, $href);
      last TRY_NEXT;
      } # if
    } # foreach
  # All done with this page.
  $tree->delete;
  return $hits_found;
  } # parse_tree

sub _next_text
  {
  # The text of the "Next" button, localized:
  return 'Next';
  } # _next_text

sub _parse_category_list
  {
  my $self = shift;
  my $oTree = shift;
  my $ra = shift;
  my $oUL = $oTree->look_down(_tag => 'ul');
  my @aoLI = $oUL->look_down(_tag => 'li');
 CATLIST_LI:
  foreach my $oLI (@aoLI)
    {
    my %hash;
    next CATLIST_LI unless ref($oLI);
    if ($oLI->parent->same_as($oUL))
      {
      my $oA = $oLI->look_down(_tag => 'a');
      next CATLIST_LI unless ref($oA);
      my $oSPAN = $oLI->look_down(_tag => 'span');
      next CATLIST_LI unless ref($oSPAN);
      $hash{'Name'} = $oA->as_text;
      $hash{'ID'} = $oA->{'href'};
      $hash{'ID'} =~ /sacatZ([0-9]+)/;
      $hash{'ID'} = $1;
      my $i = $oSPAN->as_text;
      $i =~ tr/0-9//cd;
      $hash{'Count'} = $i;
      push @{$ra}, \%hash;
      } # if
    my @aoUL = $oLI->look_down(_tag => 'ul');
 CATLIST_UL:
    foreach my $oUL (@aoUL)
      {
      next CATLIST_UL unless ref($oUL);
      if($oUL->parent()->same_as($oLI))
        {
        $hash{'Subcategory'} = ();
        $self->_parse_category_list($oLI, \@{$hash{'Subcategory'}});
        } # if
      } # foreach CATLIST_UL
    } # foreach CATLIST_LI
  } # _parse_category_list

sub parse_price
  {
  my $self = shift;
  my $oTDprice = shift;
  my $hit = shift;
  return 0 unless (ref $oTDprice);
  my $s = $oTDprice->as_HTML;
  if (1 < $self->{_debug})
    {
    print STDERR " DDD   try TDprice ===$s===\n";
    } # if
  if ($oTDprice->attr('class') eq 'ebcBid')
    {
    # If we see this, we must have been searching for Stores items
    # but we ran off the bottom of the Stores item list and ran
    # into the list of "other" items.
    return 1;
    # We could probably return 0 to abandon the rest of the page, but
    # maybe just maybe we hit this because of a parsing glitch which
    # might correct itself on the next TD.
    } # if
  if ($oTDprice->attr('class') !~ m'ebcPr')
    {
    # If we see this, we probably were searching for Store items
    # but we ran off the bottom of the Store item list and ran
    # into the list of Auction items.
    return 0;
    # There is a separate backend for searching Auction items!
    } # if
  if ($oTDprice->look_down(_tag => 'span',
                          class => 'ebSold'))
    {
    # This item sold, even if it had no bids (i.e. Buy-It-Now)
    $hit->sold(1);
    } # if
  my $iPrice = $oTDprice->as_text;
  print STDERR " DDD   raw iPrice ===$iPrice===\n" if (1 < $self->{_debug});
  $iPrice =~ s!&pound;!GBP!;
  # Convert nbsp to regular space:
  $iPrice =~ s!\240!\040!g;
  my $currency = $self->currency_pattern;
  my $W = $self->whitespace_pattern;
  $iPrice =~ s!($currency)$W*($currency)!$1 (Buy-It-Now for $2)!;
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
      print STDERR " DDD   TDbids ===$s===\n";
      } # if
    if ($oTDbids->attr('class') !~ m'ebcBid')
      {
      # If we see this, we probably were searching for Store items
      # but we ran off the bottom of the Store item list and ran
      # into the list of Auction items.
      return 0;
      # There is a separate backend for searching Auction items!
      } # if
    $iBids = $oTDbids->as_text;
    my $W = $self->whitespace_pattern;
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
  if ($oTD->attr('class') =~ m'ebcCty')
    {
    # If we see this, we probably were searching for UK auctions
    # but we ran off the bottom of the UK item list and ran
    # into the list of international items.
    return 0;
    } # if
  my $iPrice = $oTD->as_text;
  print STDERR " DDD   raw shipping ===$iPrice===\n" if (1 < $self->{_debug});
  $iPrice =~ s!&pound;!GBP!;
  $hit->shipping($iPrice);
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
  my ($s, $sDateTemp);
  if (ref $oTDdate)
    {
    $sDateTemp = $oTDdate->as_text;
    $s = $oTDdate->as_HTML;
    }
  else
    {
    $sDateTemp = $s = $oTDdate;
    }
  print STDERR " DDD   TDdate ===$s===\n" if (1 < $self->{_debug});
  if (ref($oTDdate) && ($oTDdate->attr('class') !~ m'ebcTim'))
    {
    # If we see this, we probably were searching for Buy-It-Now items
    # but we ran off the bottom of the item list and ran into the list
    # of Store items.
    return 0;
    # There is a separate backend for searching Store items!
    } # if
  # Convert nbsp to regular space:
  $sDateTemp =~ s!\240!\040!g;
  print STDERR " DDD   raw    sDateTemp ===$sDateTemp===\n" if (DEBUG_DATES || (1 < $self->{_debug}));
  $sDateTemp =~ s!<!!;
  $sDateTemp = $self->_process_date_abbrevs($sDateTemp);
  print STDERR " DDD   cooked sDateTemp ===$sDateTemp===\n" if (DEBUG_DATES || (1 < $self->{_debug}));
  print STDERR " DDD   official time =====$self->{_ebay_official_time}=====\n" if (DEBUG_DATES || (1 < $self->{_debug}));
  my $date = &DateCalc($self->{_ebay_official_time}, " + $sDateTemp");
  print STDERR " DDD   date ===$date===\n" if (DEBUG_DATES || (1 < $self->{_debug}));
  $sDate = $self->_format_date($date);
  print STDERR " DDD   sDate ===$sDate===\n" if (DEBUG_DATES || (1 < $self->{_debug}));
  $hit->end_date($sDate);
  # For backward-compatibility:
  $hit->change_date($sDate);
  return 1;
  } # parse_enddate

sub _process_date_abbrevs
  {
  my $self = shift;
  my $s = shift;
  $s =~ s!d! days!;
  $s =~ s!h! hours!;
  $s =~ s!m! minutes!;
  return $s;
  } # _process_date_abbrevs


=item result_as_HTML

Given a WWW::SearchResult object representing an auction, formats it
human-readably with HTML.

An optional second argument is the date format,
a string as specified for Date::Manip::UnixDate.
Default is '%Y-%m-%d %H:%M:%S'

  my $sHTML = $oSearch->result_as_HTML($oSearchResult, '%H:%M %b %E');

=cut

sub result_as_HTML
  {
  my $self = shift;
  my $oSR = shift or return '';
  my $sDateFormat = shift || q'%Y-%m-%d %H:%M:%S';
  my $dateEnd = &ParseDate($oSR->end_date);
  my $iItemNum = $oSR->item_number;
  my $sSold = $oSR->sold
  ? $cgi->font({color=>'green'}, 'sold') .q{; }
  : $cgi->font({color=>'red'}, 'not sold') .q{; };
  my $sBids = $self->_bidcount_as_text($oSR);
  my $sPrice = $self->_bidamount_as_text($oSR);
  my $sEndedColor = 'green';
  my $sEndedWord = 'ends';
  my $dateNow = &ParseDate('now');
  print STDERR " DDD compare end_date ==$dateEnd==\n" if (DEBUG_DATES || (1 < $self->{_debug}));
  print STDERR " DDD compare date_now ==$dateNow==\n" if (DEBUG_DATES || (1 < $self->{_debug}));
  if (&Date_Cmp($dateEnd, $dateNow) < 0)
    {
    $sEndedColor = 'red';
    $sEndedWord = 'ended';
    } # if
  my $sEnded = $cgi->font({ color => $sEndedColor },
                          &UnixDate($dateEnd,
                                    qq"$sEndedWord $sDateFormat"));
  my $s = $cgi->b(
                  $cgi->a({href => $oSR->url}, $oSR->title),
                  $cgi->br,
                  qq{$sEnded; $sSold$sBids$sPrice},
                 );
  $s .= $cgi->br;
  $s .= $cgi->font({size => -1},
                   $cgi->a({href => qq{http://cgi.ebay.com/ws/eBayISAPI.dll?MakeTrack&item=$iItemNum}}, 'watch this item in MyEbay'),
                  );
  # Format the entire thing as Helvetica:
  $s = $cgi->font({face => 'Arial, Helvetica'}, $s);
  return $s;
  } # result_as_HTML


=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::Ebay> was written by and is maintained by
Martin Thurn C<mthurn@cpan.org>, L<http://tinyurl.com/nn67z>.

Some fixes along the way contributed by Troy Davis.

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;

__END__
