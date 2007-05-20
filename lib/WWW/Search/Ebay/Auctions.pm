
# $Id: Auctions.pm,v 1.6 2007/05/20 13:32:56 Daddy Exp $

=head1 NAME

WWW::Search::Ebay::Auctions - backend for searching auctions at www.ebay.com

=head1 DESCRIPTION

This module is just a synonym of WWW::Search::Ebay.

=head1 AUTHOR

C<WWW::Search::Ebay::Auctions> was written by and is maintained by
Martin Thurn C<mthurn@cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

package WWW::Search::Ebay::Auctions;

use strict;

use base 'WWW::Search::Ebay';
our
$VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

1;

__END__

