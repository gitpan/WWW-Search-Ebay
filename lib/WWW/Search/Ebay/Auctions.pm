
# $Id: Auctions.pm,v 1.3 2004/07/24 18:33:58 Daddy Exp $

=head1 NAME

WWW::Search::Ebay::Auctions - backend for searching auctions at www.ebay.com

=head1 DESCRIPTION

This module is just a synonym of WWW::Search::Ebay.

=head1 AUTHOR

C<WWW::Search::Ebay::Auctions> was written by Martin Thurn
(mthurn@cpan.org).

C<WWW::Search::Ebay::Auctions> is maintained by Martin Thurn
(mthurn@cpan.org).

=cut

package WWW::Search::Ebay::Auctions;

use WWW::Search::Ebay;
use vars qw( @ISA $VERSION );
@ISA = qw( WWW::Search::Ebay );
$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

1;

__END__
