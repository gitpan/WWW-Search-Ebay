# Ebay/Completed.pm
# by Martin Thurn
# $Id: Completed.pm,v 1.2 2003-10-27 09:56:21-05 kingpin Exp kingpin $

=head1 NAME

WWW::Search::Ebay::Completed - backend for searching completed auctions on www.ebay.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::Completed');
  my $sQuery = WWW::Search::escape_query("Yakface");
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

The search is done against completed auctions only.

The query is applied to TITLES only.

See the NOTES section of L<WWW::Search::Ebay> for a description of the results.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 CAVEATS

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

Thanks to Troy Arnold C<troy at zenux.net> for figuring out how to do this search.

C<WWW::Search::Ebay::Completed> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::Ebay::Completed;

use Carp;
use WWW::Search::Ebay;
@ISA = qw( WWW::Search::Ebay );

use vars qw( $MAINTAINER $VERSION );
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/o);

# private
sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  unless (ref($rhOptsArg) eq 'HASH')
    {
    carp " --- second argument to native_setup_search should be hashref, not arrayref";
    return undef;
    } # unless
  $rhOptsArg->{'ebay_host'} = 'http://search-completed.ebay.com';
  return $self->SUPER::native_setup_search($native_query, $rhOptsArg);
  } # native_setup_search

1;

__END__
