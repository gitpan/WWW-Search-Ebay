# Ebay.pm
# by Martin Thurn
# $Id: Ebay.pm,v 1.7 2001/07/30 18:05:35 mthurn Exp mthurn $

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

The search is done against CURRENT running auctions only.

The query is applied to TITLES only.

The results are ordered youngest auctions first (reverse order of
auction listing date).

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 CAVEATS

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::Ebay> was written by Martin Thurn
(MartinThurn@iname.com).

C<WWW::Search::Ebay> is maintained by Martin Thurn
(MartinThurn@iname.com).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

=head2 2.01

First publicly-released version.

=cut

#####################################################################

package WWW::Search::Ebay;

@ISA = qw( WWW::Search );

use Carp ();
use Data::Dumper;  # for debugging only
use HTML::Form;
use HTML::TreeBuilder;
use WWW::Search qw( generic_option strip_tags );
require WWW::SearchResult;

$VERSION = '2.06';
$MAINTAINER = 'Martin Thurn <MartinThurn@iname.com>';

# private
sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;

  # Set some private variables:
  $self->{_debug} ||= $rhOptsArg->{'search_debug'};
  $self->{_debug} = 2 if ($rhOptsArg->{'search_parse_debug'});
  $self->{_debug} ||= 0;

  my $DEFAULT_HITS_PER_PAGE = 50;
  # $DEFAULT_HITS_PER_PAGE = 30 if $self->{_debug};
  $self->{'_hits_per_page'} = $DEFAULT_HITS_PER_PAGE;

  $self->{agent_e_mail} = 'MartinThurn@iname.com';
  $self->user_agent('non-robot');

  $self->{'_next_to_retrieve'} = 0;
  $self->{'_num_hits'} = 0;

  if (!defined($self->{_options}))
    {
    $self->{_options} = {
                         'search_url' => 'http://search.ebay.com/search/search.dll',
                         'MfcISAPICommand' => 'GetResult',
                         'ht' => 1,
                         # Default sort order is reverse-order of listing date:
                         'SortProperty' => 'MetaNewSort',
                         'query' => $native_query,
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
  $self->{_next_url} = $self->{_options}->{'search_url'} .'?'. $self->hash_to_cgi_string($self->{_options});
  } # native_setup_search


# private
sub native_retrieve_some
  {
  my ($self) = @_;

  # Fast exit if already done:
  return undef unless defined($self->{_next_url});

  # If this is not the first page of results, sleep so as to not overload the server:
  $self->user_agent_delay if 1 < $self->{'_next_to_retrieve'};

  # Get some results, adhering to the WWW::Search mechanism:
  print STDERR " +   sending request (",$self->{_next_url},")\n" if $self->{'_debug'};
  my $response = $self->http_request('GET', $self->{_next_url});
  $self->{response} = $response;
  unless ($response->is_success)
    {
    return undef;
    } # unless

  print STDERR " +   got response\n" if $self->{'_debug'};
  my $sBaseURL = $self->{'_next_url'};
  $self->{'_next_url'} = undef;

  # Parse the output:
  my $hits_found = 0;
  my $tree = new HTML::TreeBuilder;
  my $sPage = $response->content;
  # Ebay sends malformed HTML:
  my $iSubs = 0 + ($sPage =~ s!</FONT></TD></FONT></TD>!</FONT></TD>!gi);
  # print STDERR " +   deleted $iSubs extraneous tags\n" if 1 < $self->{_debug};
  $tree->parse($sPage);
  $tree->eof;

  # The hit count is in a FONT tag:
  my @aoFONT = $tree->look_down('_tag', 'font');
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

  # The list of matching items is in a table.  The first column of the
  # table is nothing but icons; the second column is the good stuff.
  my @aoTD = $tree->look_down('_tag', 'td',
                              sub { (
                                     ($_[0]->as_HTML =~ m!ViewItem! )
                                     &&
                                     # Ignore thumbnails:
                                     ($_[0]->as_HTML !~ m!\#DESC! )
                                    )
                                  }
                             );
 TD:
  foreach my $oTD (@aoTD)
    {
    my $sTD = $oTD->as_HTML;
    my $oFONT = $oTD->look_down('_tag', 'font');
    next TD unless ref $oFONT;
    my $oA = $oFONT->look_down('_tag', 'a');
    next TD unless ref $oA;
    my $sURL = $oA->attr('href');
    next TD unless $sURL =~ m!ViewItem!;
    my $sTitle = $oA->as_text;
    print STDERR " + TD ===$sTD===\n" if 1 < $self->{_debug};
    my ($iItemNum) = ($sURL =~ m!item=(\d+)!);
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
      $iPrice =~ s!(\d)(\$[\d.,]+)!$1 (US$2)!;
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
    $iBids = 'no' if $iBids eq '-';
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
      } # if
    my $hit = new WWW::SearchResult;
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
    next unless ref $oA;
    print STDERR " +   try NEXT A ===", $oA->as_HTML, "===\n" if 1 < $self->{_debug};
    if ($oA->as_text =~ m!Next\s+(>|&gt;)!i)
      {
      $self->{_next_url} = $self->absurl($sBaseURL, $oA->attr('href'));
      print STDERR " +   got NEXT A ===", $self->{_next_url}, "===\n" if 1 < $self->{_debug};
      last TRY_NEXT;
      } # if
    } # foreach

  # All done with this page.
  $tree->delete;
  return $hits_found;
  } # native_retrieve_some

1;

__END__

Martin''s page download notes, 2001-04:

http://search.ebay.com/search/search.dll?MfcISAPICommand=GetResult&ht=1&SortProperty=MetaEndSort&query=taco+bell+star+wars

http://search.ebay.com/search/search.dll?MfcISAPICommand=GetResult&ht=1&ebaytag1=ebayreg&query=taco+bell+pog*&query2=taco+bell+pog*&search_option=1&exclude=&category0=&minPrice=&maxPrice=&ebaytag1code=0&st=0&SortProperty=MetaNewSort

<TR>
<TD align="center" valign="middle" width="12%">
  <FONT size=3>
  <A href="http://pages.ebay.com/help/basics/g-pic.html">
  <IMG height=15 width=64 border=0 alt="[Picture!]" src="http://pics.ebay.com/aw/pics/lst/_p__64x15.gif">
  </A>
  </FONT>
</TD>
<TD valign="top" width="54%">
  <A href="http://pages.ebay.com/help/basics/g-new.html">
    <IMG height=15 width=16 border=0 alt="New!" src="http://pics.ebay.com/aw/pics/lst/new.gif">
  </A>
  <FONT size=3>
    <A href="http://cgi.ebay.com/aw-cgi/eBayISAPI.dll?ViewItem&item=1050807630">
      Star Wars: Boba Fett:When the fat lady Swings
    </A>
  </FONT>
</TD>
<TD nowrap align="right" valign="top" width="11%">
  <FONT size=3>
    <B>
      <FONT size="-1" color="#666666">
        EUR
      </FONT> 5.50
    </B>
    <BR>
    <I>
      $4.95
    </I>
    </FONT>
  </TD>
  </FONT>
</TD>
<TD align="center" valign="top" width="5%">
<FONT size=3>-
</FONT>
</TD>
<TD align="right" valign="top" width="18%">
<FONT size=3>Dec-20 01:54
</FONT>
</TD>
</TR>
</TABLE>
<TABLE width="100%" cellpadding=4 border=0 cellspacing=0 bgcolor="#EFEFEF">

=====

<TABLE width="100%" cellpadding=4 border=0 cellspacing=0 bgcolor="#FFFFFF">
<TR><TD align="center" valign="middle" width="12%"><FONT size=3>
<A href="http://pages.ebay.com/help/basics/g-pic.html"><IMG height=15 width=64 border=0 alt="[Picture!]" src="http://pics.ebay.com/aw/pics/lst/_p__64x15.gif"></A>
</FONT></TD><TD valign="top" width="54%"><A href="http://pages.ebay.com/help/basics/g-new.html"><IMG height=15 width=16 border=0 alt="New!" src="http://pics.ebay.com/aw/pics/lst/new.gif"></A>
<FONT size=3><A href="http://cgi.ebay.com/aw-cgi/eBayISAPI.dll?ViewItem&item=1050807630">Star Wars: Boba Fett:When the fat lady Swings</A></FONT>
</TD>
<TD nowrap align="right" valign="top" width="11%"><FONT size=3><B><FONT size="-1" color="#666666">EUR</FONT> 5.50</B><BR><I>$4.95</I></FONT></TD></FONT></TD><TD align="center" valign="top" width="5%"><FONT size=3>-</FONT></TD><TD align="right" valign="top" width="18%"><FONT size=3>Dec-20 01:54</FONT></TD></TR></TABLE>
