
# $Id: BuyItNow.pm,v 1.3 2005/08/14 21:33:59 Daddy Exp $

=head1 NAME

WWW::Search::Ebay::BuyItNow - backend for searching eBay Buy-It-Now items

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::BuyItNow');
  my $sQuery = WWW::Search::escape_query("jawa");
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

The search is done against eBay Buy-It-Now items only.

The query is applied to TITLES only.

In the resulting WWW::Search::Result objects, the description field
consists of a human-readable combination (joined with semicolon-space)
of the Item Number; number of bids; and high bid amount (or starting
bid amount).

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::Ebay::BuyItNow> was written by Martin Thurn
(mthurn@cpan.org).

=cut

package WWW::Search::Ebay::BuyItNow;

use WWW::Search::Ebay;
use vars qw( @ISA $VERSION );
@ISA = qw( WWW::Search::Ebay );
$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  $rh->{'sasaleclass'} = 2;
  return $self->SUPER::native_setup_search($sQuery, $rh);
  } # native_setup_search

1;

__END__

