# Ebay.pm
# by Martin Thurn
# $Id: Ebay.pm,v 1.7 2001/07/30 18:05:35 mthurn Exp $

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

$VERSION = '2.05';
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
  $tree->parse($response->content);
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
    my ($iPrice, $iBids, $sDate) = ('$unknown', 'unknown', 'unknown');
    # The rest of the info about this item is in sister TD elements to
    # the right:
    my @aoSibs = $oTD->right;
    # The next sister has the current bid amount (or starting bid):
    my $oTDprice = shift @aoSibs;
    if (ref $oTDprice)
      {
      my $s = $oTDprice->as_HTML;
      print STDERR " +   TDprice ===$s===\n" if 1 < $self->{_debug};
      $iPrice = $oTDprice->as_text;
      } # if
    # The next sister has the number of bids:
    my $oTDbids = shift @aoSibs;
    if (ref $oTDbids)
      {
      my $s = $oTDbids->as_HTML;
      print STDERR " +   TDbids ===$s===\n" if 1 < $self->{_debug};
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
    } # foreach

  # If there is a NEXT button, it is the last FORM element:
  my @aoFORM = $tree->look_down('_tag', 'form');
  my $oFORM = pop @aoFORM;
  if (ref $oFORM)
    {
    my $sForm = $oFORM->as_HTML;
    print STDERR " + FORM ===$sForm===\n" if 1 < $self->{_debug};
    my $oForm = HTML::Form->parse($sForm, $sBaseURL);
    if (ref $oForm)
      {
      print STDERR " +   FORM parsed OK\n" if 1 < $self->{_debug};
      my $oNextButton = $oForm->find_input(undef, 'submit');
      if (ref $oNextButton && (lc $oNextButton->value eq 'next'))
        {
        print STDERR " +   found Next button OK\n" if 1 < $self->{_debug};
        print STDERR " +   NEXT == ", $oNextButton, "\n" if 1 < $self->{_debug};
        $self->{_next_url} = new $HTTP::URI_CLASS($oNextButton->click($oForm)->uri);
        print STDERR " +   next_url == ", $self->{_next_url}, "\n" if 1 < $self->{_debug};
        } # if oForm
      } # if oNextButton
    } # if

  # All done with this page.
  $tree->delete;
  return $hits_found;
  } # native_retrieve_some

1;

__END__

Martin''s page download notes, 2001-04:

http://search.ebay.com/search/search.dll?MfcISAPICommand=GetResult&ht=1&SortProperty=MetaEndSort&query=taco+bell+star+wars

http://search.ebay.com/search/search.dll?MfcISAPICommand=GetResult&ht=1&ebaytag1=ebayreg&query=taco+bell+pog*&query2=taco+bell+pog*&search_option=1&exclude=&category0=&minPrice=&maxPrice=&ebaytag1code=0&st=0&SortProperty=MetaNewSort
