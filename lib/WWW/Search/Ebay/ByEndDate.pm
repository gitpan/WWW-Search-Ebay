# Ebay/ByEndDate.pm
# by Martin Thurn
# $Id: Ebay.pm,v 1.7 2001/07/30 18:05:35 mthurn Exp $

=head1 NAME

WWW::Search::Ebay::ByEndDate - backend for searching www.ebay.com, with results sorted with "items ending first"

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::ByEndDate');
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

The results are ordered auctions ending soon first (order of
increasing auction ending date).  In the WWW::SearchResult objects,
the change_date field contains the auction ending date & time exactly
as returned by ebay.com; this can have values like "in 12 mins".

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 CAVEATS

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::Ebay::ByEndDate> was written by Martin Thurn
(mthurn@tasc.com).

C<WWW::Search::Ebay::ByEndDate> is maintained by Martin Thurn
(mthurn@tasc.com).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

=head2 2.01

First publicly-released version.

=cut

#####################################################################

package WWW::Search::Ebay::ByEndDate;

use WWW::Search::Ebay;
@ISA = qw( WWW::Search::Ebay );

$VERSION = '2.01';
$MAINTAINER = 'Martin Thurn <mthurn@tasc.com>';

# private
sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;

  $rhOptsArg ||= [];
  $rhOptsArg->{'SortProperty'} = 'MetaEndSort';
  return $self->SUPER::native_setup_search($native_query, $rhOptsArg);
  } # native_setup_search

1;

__END__
