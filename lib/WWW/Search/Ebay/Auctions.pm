
# $Id: Auctions.pm,v 1.1 2004/06/06 02:55:16 Daddy Exp $

package WWW::Search::Ebay::Auctions;

use WWW::Search::Ebay;
use vars qw( @ISA $VERSION );
@ISA = qw( WWW::Search::Ebay );
$VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

1;

__END__
