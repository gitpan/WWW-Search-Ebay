
# $Id: UK.pm,v 1.1 2004/11/30 04:14:30 Daddy Exp $

=head1 NAME

WWW::Search::Ebay::UK - backend for searching auctions at www.ebay.com

=head1 DESCRIPTION

This module is just a synonym of WWW::Search::Ebay.

=head1 AUTHOR

C<WWW::Search::Ebay::UK> was written by Martin Thurn
(mthurn@cpan.org).

C<WWW::Search::Ebay::UK> is maintained by Martin Thurn
(mthurn@cpan.org).

=cut

package WWW::Search::Ebay::UK;

use Carp;
use WWW::Search::Ebay;
use vars qw( @ISA $VERSION );
@ISA = qw( WWW::Search::Ebay );
$VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  unless (ref($rhOptsArg) eq 'HASH')
    {
    carp " --- second argument to native_setup_search should be hashref, not arrayref";
    return undef;
    } # unless
  $rhOptsArg->{search_host} = 'http://search.ebay.co.uk';
  return $self->SUPER::native_setup_search($native_query, $rhOptsArg);
  } # native_setup_search

sub currency_pattern
  {
  # A pattern to match all possible currencies found in eBay listings:
  return qr/(?:US\s\$|£)/;
  } # currency_pattern

1;

__END__
